#FROM sensoriant.azurecr.io/priv-comp/crosscompilers-alpine3.7:VERSION_0_0_2 as build
#FROM sconecuratedimages/sensoriant:crosscompilers-alpine3.7.local-scone4.2.1 as build
#FROM sconecuratedimages/sensoriant:crosscompilers-alpine3.7-scone5.0.0 as build
FROM sensoriant.azurecr.io/priv-comp/crosscompilers-alpine3.7-5.0:11022020 as build

RUN apk update && apk add \
    bats \
    make
COPY . /copy_files
WORKDIR /copy_files
RUN make with-scone

FROM alpine:3.7

COPY --from=build /opt/scone/lib/libc.scone* /opt/scone/lib/
COPY --from=build /opt/scone/cross-compiler/x86_64-linux-musl/lib/libgcc_s.so.1 /opt/scone/lib
COPY --from=build /opt/scone/lib/ld-scone* /opt/scone/lib
COPY --from=build /copy_files/copy_files /

RUN apk add bash --no-cache

ENTRYPOINT ["/copy_files","-i","/encrypted-output","-o","/unencrypted-output","-k","$SCONE_FSPF_KEY"]
