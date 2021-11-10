#!/bin/bash
#
# This script pulls in the SCONE LAS image and launches the docker
#

maindir=.
if [ "$1" ];then
  maindir=$1
fi
source $maindir/.env

pushd $maindir/operator > /dev/null
docker-compose up -d las
popd > /dev/null
