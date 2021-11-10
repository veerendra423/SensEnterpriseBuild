#FROM sconecuratedimages/crosscompilers:alpine
#FROM sensoriant.azurecr.io/priv-comp/crosscompilers-alpine:attestation
#FROM sensoriant.azurecr.io/priv-comp/crosscompilers-alpine3.7-5.0:11022020
FROM sensoriant.azurecr.io/priv-comp/crosscompilers-alpine3.13-5.1.x:02032021

COPY *.c /build/
COPY *.h /build/

RUN cd build && scone-gcc user_extension.c httpclient.c jsmn.c -shared -o libattestation-go.so


