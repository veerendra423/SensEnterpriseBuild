#!/bin/bash
docker run --rm -e SCONE_MODE=sim -it -v $PWD/empty-dir:/empty-dir -v $PWD/encrypted-output:/encrypted-output sensoriant.azurecr.io/priv-comp/python-3.8.1-ubuntu:11302020 bash -c "
    rm -rf /encrypted-output/* && \
    mkdir -p /encrypted-output && \
    cd /encrypted-output && \
    scone fspf create volume.fspf && \
    scone fspf addr /encrypted-output/volume.fspf . --encrypted --kernel . && \
    scone fspf addf /encrypted-output/volume.fspf . /empty-dir /encrypted-output/ && \
    scone fspf encrypt volume.fspf > /empty-dir/tag_key.txt && \
    cat /empty-dir/tag_key.txt"

while IFS= read -r line
do
  echo "$line" | awk '{print "export SENSDECRYPT_FSPF_TAG="substr($0,64,32)}' > .env1
  echo "$line" | awk '{print "export SENSDECRYPT_FSPF_KEY="substr($0,102,64)}' >> .env1
done < "empty-dir/tag_key.txt"

while IFS= read -r line
do
  echo "$line" | awk '{print "SENSDECRYPT_FSPF_TAG="substr($0,64,32)}' > .env
  echo "$line" | awk '{print "SENSDECRYPT_FSPF_KEY="substr($0,102,64)}' >> .env
done < "empty-dir/tag_key.txt"

sudo rm -f empty-dir/tag_key.txt
