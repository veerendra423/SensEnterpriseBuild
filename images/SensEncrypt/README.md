# Copy Files

## Building

To build the image `copy_files`, just execute

```bash
./build.sh
```

You can run an example via

```bash
docker run --device=/dev/isgx -ti --rm  copy_files -h
```

which results in the following output:

```bash
 Recursively copy all files from one directory to another directory.

 Usage: copy_files [help] [flags]

 flags:
  -i PATH, --input=PATH     Path to input files (required)
  -o PATH, --output=PATH    Path to output files (required)
  -h, --help                Print this help text
```

## CI Testing

To run the **ci tests** for `copy_files`, i.e., to

- create an Docker image `copy_files_ci_image`,
- runs the tests described in `test.bats`,
- which builds the `copy_files` CLI with SCONE, and
- tests the functionality

just execute:

```bash
./run_ci.sh
```

Note: The `copy_files` reads files into memory as a whole. We have to give `copy_files` enough HEAP such that even the largest file can be read into memory.
