#include <stdio.h>
int main(int argc, char **argv) {
    printf ("Attestation Passed..\n");
#if DEBUG
    printf ("LUKE: In test.c - argc = %d\n", argc);
    for (int i=0; i<argc; i++) {
        printf ("argv[%d] = %s\n", i, argv[i]);
    }
#endif
    return 23;
}
