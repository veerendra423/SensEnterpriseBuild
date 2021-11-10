#!/usr/bin/env bash

# build the copy_files image
docker build -f Dockerfile . -t copy_files
