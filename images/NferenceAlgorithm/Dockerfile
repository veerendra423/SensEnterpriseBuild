FROM sensoriant.azurecr.io/nference/algorithm-base:test

ADD image_files /

RUN apt-get update
RUN apt-get install strace --assume-yes

#RUN mkdir /encrypted-output

WORKDIR /app

#CMD /opt/scone/lib/ld-scone-x86_64.so.1 /root/miniconda/bin/python3 /app/nference_algorithm.py --output /encrypted-output
