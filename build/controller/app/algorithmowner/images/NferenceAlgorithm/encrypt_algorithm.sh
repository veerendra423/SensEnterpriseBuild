#!/bin/bash -x

set -e

echo "Building the base image that contains python with all necessary dependencies."
echo "This is necessary to protect the python dependencies against malicious code injections."
docker build . -t algorithm-base:test -f Dockerfile.base
echo ""

echo "Now, we enter the base image to record the trusted state of the python"
echo "dependencies and encrypt the application."
docker run -it --rm --privileged  --device /dev/isgx --device /dev/gsgx  -e SCONE_VERSION=1 -e SCONE_MODE=sim  -e SCONE_VERSION=1 -v `pwd`:/algorithm algorithm-base:test sh -c "
    cd /algorithm && \
    # cleanup previous files
    rm -rf image_files && \
    mkdir -p image_files/app && \
    cd image_files && \
    scone fspf create fspf.pb && \
    scone fspf addr fspf.pb / --not-protected --kernel / && \
    scone fspf addr fspf.pb /usr/lib/ --authenticated --kernel /usr/lib && \
    scone fspf addf fspf.pb /usr/lib/ /usr/lib/ && \
    # all files in /app shall be encrypted
    scone fspf addr fspf.pb /app --encrypted --kernel /app && \
    # encrypt the files in /algorithm/app (the plaintext) and write the encrypted
    # files to /algorithm/image_files/app
    scone fspf addf fspf.pb /app /algorithm/app /algorithm/image_files/app 
    #&&  \
    # authenticate glibc and related libs
    scone fspf addr fspf.pb /opt/scone/lib --authenticated --kernel /opt/scone/lib  && \
    scone fspf addf fspf.pb /opt/scone/lib /opt/scone/lib  && \
    # authenticate python interpreter 
    scone fspf addr fspf.pb /root/miniconda --authenticated --kernel /root/miniconda && \
    scone fspf addf fspf.pb /root/miniconda /root/miniconda
    # encrypt the metadata file
    scone fspf encrypt fspf.pb > /algorithm/tag_key.txt
     ls
"

while IFS= read -r line
do
  echo "$line" | awk '{print "FSPF_TAG="substr($0,60,32)}' > .env
  echo "$line" | awk '{print "FSPF_KEY="substr($0,98,64)}' >> .env
done < "tag_key.txt"
cat tag_key.txt
rm -f tag_key.txt
mkdir -p ../../keys/algorithm/
cp .env ../../keys/algorithm/
rm .env
