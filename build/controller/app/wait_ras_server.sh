#!/bin/bash
# wait for spire server
maindir=.
if [ "$1" ];then
  maindir=$1
fi
source $maindir/.env

echo "Waiting for controller ras server to become ready..."
a=1
while [ $a -le 10 ]
do
RET=0
timeout 60 bash -c 'until printf "" 2>>/dev/null >>/dev/tcp/$0/$1; do sleep 0.4; done' ${SENSORIANT_SPIRE_SERVER_HOSTNAME} ${SENSORIANT_SPIRE_SERVER_PORT} || RET=$? || true
if [ $RET -eq 0 ]; then
    echo "controller ras server  is ready!"
    exit 1
fi
echo "FAIL! RAS server didn't become available within one minute..retrying"
a=`expr $a + 1`
done
echo "FAIL! RAS server not available after 10 tries"
