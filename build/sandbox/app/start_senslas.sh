#!/bin/bash

maindir=.
if [ "$1" ];then
  maindir=$1
fi

source $maindir/.env

SENSLAS_URL=${SENSLAS_URL}
SENSLAS_PORT=${SENSLAS_PORT}
# To up the senslas
pushd $maindir/operator > /dev/null
docker-compose up -d SensLAS
popd > /dev/null


sleep 10

#Get platform key..
echo "In get_platform_signing_key"
curl -s -o $maindir/platformEDDSAKey.json -X POST $SENSLAS_URL:$SENSLAS_PORT/GetPlatformEDDSAKey?keyHandleId=0&nvramId=0
sleep 1
echo "PLATFORM_EDDSA_KEY=`cat $maindir/platformEDDSAKey.json | jq -r '.platformSigningKey'`"
echo "PLATFORM_EDDSA_KEY=`cat $maindir/platformEDDSAKey.json | jq -r '.platformSigningKey'`" >> $maindir/.env
rm $maindir/platformEDDSAKey.json
cp $maindir/.env $maindir/operator/
echo -e "\nDone.."



#To up the ras_agent
pushd $maindir/operator > /dev/null
docker-compose up -d ras_agent
popd > /dev/null
