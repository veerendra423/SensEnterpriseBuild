#!/bin/bash
#
# One time configuration of TPM for each new machine deployed
#
maindir=.
if [ "$1" ];then
  maindir=$1
fi
pushd $maindir/operator >> /dev/null
docker-compose run SensLAS /SensAttest/SensAttest -sha256 -keyHandleId=0 create-load-internal-key
docker-compose run SensLAS /SensAttest/SensAttest -nvramIndex=0 -keyHandleId=0 create-load-eddsa-key
popd >> /dev/null

source $maindir/start_senslas.sh
