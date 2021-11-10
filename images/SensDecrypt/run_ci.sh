#!/usr/bin/env bash

# build a test image
docker build -f Dockerfile-ci . -t copy_files_ci_image

# run tests
docker run -it --rm copy_files_ci_image
