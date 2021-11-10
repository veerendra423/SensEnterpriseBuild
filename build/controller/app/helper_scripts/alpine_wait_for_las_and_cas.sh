#!/bin/bash

echo "Waiting for LAS to become ready..."
RET=0
timeout -t 60 bash -c 'until printf "" 2>>/dev/null >>/dev/tcp/$0/$1; do sleep 0.4; done' las 18766 || RET=$? || true
if [ $RET -ne 0 ]; then
    echo "FAIL! LAS didn't become available within one minute"
    exit 1
fi
echo "LAS is ready!"

echo "Waiting for CAS to become ready..."
RET=0
timeout -t 60 bash -c 'until printf "" 2>>/dev/null >>/dev/tcp/$0/$1; do sleep 0.4; done' cas 8081 || RET=$? || true
if [ $RET -ne 0 ]; then
    echo "FAIL! CAS didn't become available within one minute"
    exit 1
fi
echo "CAS is ready!"
