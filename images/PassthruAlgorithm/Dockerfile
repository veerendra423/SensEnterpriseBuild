#FROM sensoriant.azurecr.io/priv-comp/crosscompilers-alpine3.7:VERSION_0_0_2 as build
FROM sensoriant.azurecr.io/priv-comp/crosscompilers-alpine:attestation
RUN apt-get update && apt install make

#RUN apk update && apk add make
#    bats \
#    make
COPY . /copy_files
WORKDIR /copy_files
RUN make with-scone

#FROM alpine:3.7

#COPY --from=build /opt/scone/lib/libc.scone* /opt/scone/lib/
#COPY --from=build /opt/scone/cross-compiler/x86_64-linux-musl/lib/libgcc_s.so.1 /opt/scone/lib
#COPY --from=build /opt/scone/lib/ld-scone* /opt/scone/lib
FROM sensoriant.azurecr.io/priv-comp/crosscompilers-alpine:attestation
COPY --from=0 /copy_files/copy_files /
COPY --from=0 /copy_files/libsensattest.so /

#RUN apk add bash --no-cache

#ENTRYPOINT ["/copy_files","-i","/algorithm-input","-o","/algorithm-output"]

