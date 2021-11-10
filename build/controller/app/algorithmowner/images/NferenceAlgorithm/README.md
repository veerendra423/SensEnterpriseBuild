# Algorithm Image

This directory contains all files necessary to build the algorithm image.
It contains an encrypted python program that operates on the data of the
database and pushes its results into a volume which is subsequently read
by the output program.

## Image Building

As this image contains encrypted code, the build process requires a
preprocessing step in which the files are encrypted and authenticated.
The resulting files are checked into the repository for the convenience
of the user and ease-of-use.
They can be reconstructed with the `encrypt_algorithm.sh` script.
This, however, requires updating the policies of the algorithm owner.

```bash
$ ./encrypt_algorithm.sh 
Building the base image that contains python with all necessary dependencies.
This is necessary to protect the python dependencies against malicious code injections.
Sending build context to Docker daemon  1.264MB
Step 1/5 : FROM ssensoriant.azurecr.io/priv-comp/python-3.7.3-alpine:VERSION_0_0_2
 ---> 685faf8357cd
Step 2/5 : ADD /app/requirements.txt /requirements.txt
 ---> Using cache
 ---> 635ea3510da0
Step 3/5 : RUN pip install --no-cache-dir -r /requirements.txt &&     rm /requirements.txt
 ---> Using cache
 ---> e269202b528c
Step 4/5 : WORKDIR /
 ---> Using cache
 ---> 656d6eaa525a
Step 5/5 : ENTRYPOINT ["/bin/sh"]
 ---> Using cache
 ---> d0d07f664d2a
Successfully built d0d07f664d2a
Successfully tagged algorithm_plaintext:latest

Now, we enter the base image to record the trusted state of the python
dependencies and encrypt the application.
Created empty file system protection file in fspf.pb. AES-GCM tag: fa4692ef67835d1296cf92599d3f613c
Added region / to file system protection file fspf.pb new AES-GCM tag: 98193d43f12b4851e99be7ac6c64dc97
Added region /usr/lib/ to file system protection file fspf.pb new AES-GCM tag: 449dbd6c8ebbc912b8da2b309e673a62
Added files to file system protection file fspf.pb new AES-GCM tag: ea5bdb469a92eb4ea92bc1525c1fdf81
Added region /app to file system protection file fspf.pb new AES-GCM tag: 259e13b7cb9bb61b18eb6b36d9a30728
Added files to file system protection file fspf.pb new AES-GCM tag: 1b68f3e8ae933bc7c961fad72c880489
Encrypted file system protection file fspf.pb AES-GCM tag: 337d953cc21bd098217177bc09444498 key: 369a01e162154de8b3dffa28f83a3c9400dfc8424ab9385b7c148387587c5b68

Update the algorithm owner's session file with the FSPF key and tag now
```
