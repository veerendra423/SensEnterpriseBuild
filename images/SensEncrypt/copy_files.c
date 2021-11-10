// copy_files.c
//
// Copy files from encrypted input directory
// to an unencrypted output directory.

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <getopt.h>
#include <stdbool.h>
#include <sys/types.h>

#include <sys/stat.h>

#include <assert.h>
#include <dirent.h>
#include <limits.h>
#include <stdio.h>
#include <string.h>
#include <scone.h>
#include <ctype.h>

#define BLOCK_COPY_MIN_SIZE     4096*1024
#define BLOCK_COPY_MAX_SIZE     4096*1024*8

/* read_file
*
*  reads a file into a buffer and returns the buffer
*  and returns the size in argument *size
*
*  returns NULL on error
*
*  expects the call to free the allocated buffer
*/

char* read_file(const char* filename, size_t* size) {
    *size=-1;
    FILE *f = fopen(filename, "rb");
    if (!f) {
        perror ("Error opening file for reading");
        return NULL;
    }
    if (fseek(f, 0, SEEK_END) < 0) {
        fprintf(stderr, "seek to end failed for file '%s'\n", filename);
        fclose(f);
        return NULL;
    }
    size_t fsize = ftell(f);
    if (fseek(f, 0, SEEK_SET) < 0) {
        fprintf(stderr, "seek to start of file failed for file '%s'\n", filename);
        fclose(f);
        return NULL;
    }

    char *string = malloc(fsize + 1);
    if (string == NULL) {
        fprintf(stderr, "cannot allocated sufficient memory '%ld' for file '%s'\n", fsize, filename);
        fclose(f);
        return NULL;
    }
    if(fsize == 0){
        fprintf(stderr, " Note: file '%s': has zero bytes\n", filename);
        goto end;
    }
    size_t sz = fread(string, fsize, 1, f);

    if (sz != 1) {
        fprintf(stderr, "reading file '%s': expected %zu bytes but only got %zu\n", filename, fsize, sz);
        fclose(f);
        return NULL;
    }
    end:
    fclose(f);

    string[fsize] = 0;
    *size=fsize;
    return string;
}

/* write_file
*
*  writes a file passed in as a buffer with a given size
*
*  returns 0 on error
*
*  frees the buffer unless an error occurred
*/

int write_file(const char* filename, char* buf, size_t size) {
    FILE *f = fopen(filename, "w");
    if (!f) {
        perror ("Error opening file for writing");
        return 0;
    }
    size_t sz = fwrite(buf, size, 1, f);
    if(sz == 0){
        fprintf(stderr, " Note: create file '%s': that has %zu byte size\n", filename, sz);
        free(buf);
        fclose(f);
        return 1;
    }

    if (sz != 1) {
        fprintf(stderr, "writing file '%s': wanted to write %zu bytes but only written %zu\n", filename, size, sz);
        fclose(f);
        return 0;
    }
    free(buf);
    fclose(f);
    return 1;
}

/*
*  copy_file
*
*  copies a given file *from* to *to*
*
*  returns 0 on error
*  returns 1 on success
*/

int copy_file(const char* from, const char* to) {
    int retcode;
    size_t in, out;
    size_t size=0;
    char* buf=NULL;
    int sz=0;

    char *block_size=getenv("SENSENCRYPT_BLOCK_COPY_SIZE");
    if (block_size != NULL) {
        sz = atoi(block_size);
    }
    sz=((sz < BLOCK_COPY_MIN_SIZE)?BLOCK_COPY_MIN_SIZE:(sz > BLOCK_COPY_MAX_SIZE)?BLOCK_COPY_MAX_SIZE:sz);
    FILE *f = fopen(from, "rb");
    if (!f) {
        perror ("Error opening file for reading");
        return 0;
    }
    FILE *fw = fopen(to, "w");
    if (!f) {
        perror ("Error opening file for writing");
        return 0;
    }
    if (fseek(f, 0, SEEK_END) < 0) {
        fprintf(stderr, "seek to end failed for file '%s'\n", from);
        fclose(f);
        return 0;
    }
    size_t fsize = ftell(f);
    if (fseek(f, 0, SEEK_SET) < 0) {
        fprintf(stderr, "seek to start of file failed for file '%s'\n", from);
        fclose(f);
        return 0;
    }

    if(fsize == 0){
        fprintf(stderr, " Note: file '%s': has zero bytes\n", from);
        goto end;
    }

    buf = malloc(sz + 1);
    while (1) {
       in = fread(buf, 1, sz, f);
       if (0 == in) break;
       out = fwrite(buf, 1, in, fw);
       if (0 == out) break;
       size=size+out;
    }


    end:
    fclose(f);
    fclose(fw);
    free(buf);

    if(size==fsize){
	    retcode = 1;
    }
    else 
       retcode = 0;
    return retcode;
}

/*
 * ptree
 *
 *  iterates over all files in a directory and calls copy for all files found
 *  creates missing directories with the same mode in the out_dir
 */

static int ptree(char *curpath, char * const path, const char* out_dir, int in_dir_path_len) {
        char ep[PATH_MAX];
        char p[PATH_MAX];
        char to[PATH_MAX];
        DIR *dirp;
        struct dirent entry;
        struct dirent *endp;
        struct stat st;
        if (curpath != NULL){
            snprintf(ep, sizeof(ep), "%s/%s", curpath, path);
        }else{
            snprintf(ep, sizeof(ep), "%s", path);
        }

        if (stat(ep, &st) == -1)
                return -1;
        if ((dirp = opendir(ep)) == NULL)
                return -1;
        for (;;) {
                endp = NULL;
                if (readdir_r(dirp, &entry, &endp) == -1) {
                        closedir(dirp);
                        return -1;
                }
                if (endp == NULL)
                        break;
                assert(endp == &entry);
                if (strcmp(entry.d_name, ".") == 0 ||
                    strcmp(entry.d_name, "..") == 0)
                        continue;
                if (curpath != NULL)
                        snprintf(ep, sizeof(ep), "%s/%s/%s", curpath,
                            path, entry.d_name);
                else
                        snprintf(ep, sizeof(ep), "%s/%s", path,
                            entry.d_name);
                if (stat(ep, &st) == -1) {
                    if(S_ISCHR(st.st_mode))
                        fprintf(stderr, " Omit: character device '%s' \n", entry.d_name);
                    else if(S_ISBLK(st.st_mode))
                        fprintf(stderr, " Omit: block device '%s' \n", entry.d_name);
                    else if(S_ISFIFO(st.st_mode))
                        fprintf(stderr, " Omit: FIFO (named pipe) '%s' \n", entry.d_name);
                    else if(S_ISLNK(st.st_mode))
                        fprintf(stderr, " Omit: symbolic link '%s' \n", entry.d_name);
                    else if(S_ISSOCK(st.st_mode))
                        fprintf(stderr, " Omit: socket '%s' \n", entry.d_name);
                    else
                        fprintf(stderr, " Omit: could not recognize type of this file '%s' \n", entry.d_name);
                    continue;
                    // closedir(dirp);
                    // return -1;
                }

                if (S_ISREG(st.st_mode)) {
                    if (strcmp(entry.d_name, "volume.fspf") != 0) {
                        ep[sizeof(ep)-1] = 0;
                        snprintf(to, sizeof(to), "%s/%s", out_dir, &ep[in_dir_path_len]);
                        printf("copying file %s to %s\n", ep, to);
                        if (! copy_file(ep, to)) {
                            printf("Error copying file '%s'\n", ep);
                            exit(1);
                        }
                    }
                }

                if (S_ISDIR(st.st_mode)){
                    // Create dir in the out_dir with name that starts at &ep[in_dir_path_len]
                    ep[sizeof(ep)-1] = 0;
                    snprintf(to, sizeof(to), "%s/%s", out_dir, &ep[in_dir_path_len]);
                    mkdir(to, st.st_mode);
                    if (curpath != NULL){
                        snprintf(p, sizeof(p), "%s/%s", curpath, path);
                    }else{
                        snprintf(p, sizeof(p), "%s", path);
                    }
                snprintf(ep, sizeof(ep), "%s", entry.d_name);
                ptree(p, ep, out_dir, in_dir_path_len);
                }

        }
        closedir(dirp);
        return 0;
}

int hex_to_bin(const char* input, uint8_t* output, uint32_t output_sz) {
    memset(output, 0, output_sz);
    if (input[0] == '0' && input[1] == 'x') {
        input += 2;
    }

    int ret = 0;
    bool shift = true;
    while (*input != '\0') {
        if (ret >= output_sz)
            return -2;
        switch (toupper(*input)) {
            case '0': *output |= 0x00;  break;
            case '1': *output |= 0x01;  break;
            case '2': *output |= 0x02;  break;
            case '3': *output |= 0x03;  break;
            case '4': *output |= 0x04;  break;
            case '5': *output |= 0x05;  break;
            case '6': *output |= 0x06;  break;
            case '7': *output |= 0x07;  break;
            case '8': *output |= 0x08;  break;
            case '9': *output |= 0x09;  break;
            case 'A': *output |= 0x0a;  break;
            case 'B': *output |= 0x0b;  break;
            case 'C': *output |= 0x0c;  break;
            case 'D': *output |= 0x0d;  break;
            case 'E': *output |= 0x0e;  break;
            case 'F': *output |= 0x0f;  break;
            default: return -1;
        }
        input++;
        if (shift) {
            *output <<= 4;
            shift = false;
        } else {
            output++;
            ret++;
            shift = true;
        }
    }
    if (shift) // we expect even number of hex digits
        return ret;
    else
        return -3; // odd number of hex digits -> return error
}

/*
* copyies files from directory  --input to --output
*
* note that the input files are encrypted, they will be transparently decrypted by SCONE
* note that the output files must be encrypted, they will be transparently encrypted by SCONE
*/

const char *args_info_help[] = {
  " Recursively copy all files from one directory to another directory.",
  "",
  " Usage: copy_files [help] [flags] ",
  "",
  " flags: ",
  "  -i PATH, --input=PATH     Path to input files (required)",
  "  -o PATH, --output=PATH    Path to output files (required)",
  "  -k STR,  --key=STR        Encryption key for volume.fspf (required)",
  "  -h, --help                Print this help text",
  0
};

void print_usage() {
    int i = 0;
    while (args_info_help[i])
        printf("%s\n", args_info_help[i++]);
}

int main(int argc, char** argv) {
    bool i = false, o = false;
    char *input = 0, *output = 0;
    char *real_in = 0, *real_out = 0;
    char c;
	char *key = 0;
    unsigned char key_hex[32];

   while (1)
    {
        int option_index = 0;
        static struct option long_options[] = {
                { "input",	1, NULL, 'i' },
                { "output",	1, NULL, 'o' },
                { "key",	1, NULL, 'k' },
                { "help",   0, NULL, 'h' },
                { 0,  0, 0, 0 }
        };

        c = getopt_long (argc, argv, "i:o:hk:", long_options, &option_index);

        if (c == -1) break;	/* Exit from `while (1)' loop.  */

        switch (c)
        {
            case 'h':	/* Print help and exit.  */
                print_usage();
                exit (EXIT_SUCCESS);
            case 'i':
                if (optarg) input = optarg;
                i = true;
                printf("You provided this input path: %s\n", optarg);
                break;
            case 'o':
                if (optarg) output = optarg;
                o = true;
                printf("You provided this output path: %s\n", optarg);
                break;
            case 'k':
                if (optarg) key = optarg;
                break;
            case 0:	/* Long option with no short option */
            case '?':	/* Invalid option.  */
                /* `getopt_long' already printed an error message.  */
                exit(EXIT_FAILURE);
            default:	/* bug: option not considered.  */
                fprintf(stderr, "option unknown: %c\n", c);
                print_usage();
                exit(EXIT_FAILURE);
        }

    }

    if (!key) {
        fprintf(stderr, "volume key was not provided\n");
        print_usage();
        exit(EXIT_FAILURE);
	}

    if(!i){
        fprintf(stderr, "input path was not provided\n");
        print_usage();
        exit(EXIT_FAILURE);
    }
    if(!o){
        fprintf(stderr, "output path was not provided\n");
        print_usage();
        exit(EXIT_FAILURE);
    }

    if (hex_to_bin(key, key_hex, 32) < 0) {
        fprintf(stderr, "invalid volume key\n");
        exit(EXIT_FAILURE);
    }

    // to find absolute paths of the dir
    if( (real_in = realpath(input, real_in)) == NULL){
        fprintf(stderr, "could not determine realpath of input path (might not exist)\n");
        exit(EXIT_FAILURE);
    }
    printf("Use this input path:  %s\n",real_in);

    if( (real_out = realpath(output, real_out)) == NULL){
        fprintf(stderr, "could not determine realpath of output path (might not exist)\n");
        exit(EXIT_FAILURE);
    }
    printf("Use this output path: %s\n",real_out);

	/* output dir is encrypted. prepare path string to initialize volume.fspf
	 * - volume.fspf must be located in the same directory as the output data.
	 * If the opposite behavior is required (output has plaintext, input
	 *  - encrypted), use real_in instead of real_out */
    char *volume_path = calloc(1, strlen(real_out) + strlen("/volume.fspf") + 1);
    if (!volume_path) {
        fprintf(stderr, "no memory when creating input path string \n");
        exit(EXIT_FAILURE);
    }
    strcpy(volume_path, real_out);
    strcpy(volume_path + strlen(real_out), "/volume.fspf");

    /* this call will initialize a volume at the input path and the application
     * will be able to read encrypted data from this region after the call */
    scone_initialize_fspf(volume_path, key_hex, 0 /* tag */);

    //+1 to start right after the end
    ptree(NULL, real_in, real_out, strlen(real_in)+1);

    return 0;
}

