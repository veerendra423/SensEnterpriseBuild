#!/bin/bash
#
# This script launches the SensLLS (Local-Logging-Service) docker
#

maindir=.
if [ "$1" ];then
  maindir=$1
fi

#
# Set up the SensLLS hostname
#
echo "SENSLLS_HOSTNAME=$(hostname)" >> $maindir/.env
echo "SENSLLS_HOSTNAME=$(hostname)" >> $maindir/operator/.env
source $maindir/.env

pushd $maindir/operator > /dev/null
docker-compose up -d SensLLS
popd > /dev/null
