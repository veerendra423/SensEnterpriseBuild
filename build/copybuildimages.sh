#!/bin/bash

## copy from default azure internal registry to default google internal registry

if [ -z "$1" ]; then
   echo Please provide release version
   exit 1
fi

if ! test -f "/mnt/staging/default-creds.env"; then
   echo Default Azure creds not available
   exit 1
fi

if ! test -f "/mnt/staging/gkecreds/gke-defaults.env"; then
   echo Default Google creds not available
   exit 1
fi

releaseVersion=$1

extimages=(
   'python-3.8.1-ubuntu:11302020'
   'sensencrypt:'$releaseVersion
   'sensdecrypt:'$releaseVersion
   'sensgcspush:'$releaseVersion
   'sensgcspull:'$releaseVersion
   'scli:'$releaseVersion
   'sensrefimage:11302020'
   'python-3.8.1:20210928-small'
   )

intimages=(
    'las:VERSION_5_5_0'
    'cas-preprovisioned:VERSION_5_5_0'
    'prepare_policies:'$releaseVersion
    'secure-cloud-api:'$releaseVersion
    'prefect_image:VERSION_1_0_0'
    'senslas:'$releaseVersion
    'ras-server:'$releaseVersion
    'ras-agent:'$releaseVersion
    'scli:'$releaseVersion
    'senslls:'$releaseVersion
    'sensrls:'$releaseVersion
    'senspagent:'$releaseVersion
    'senspmgr:'$releaseVersion
    'minlin:latest'
    'sensgcspush:'$releaseVersion
    'sensgcspushattested-sim:'$releaseVersion
    'sensgcspushattested-hw:'$releaseVersion
    'sensgcspull:'$releaseVersion
    'sensgcspullattested-sim:'$releaseVersion
    'sensgcspullattested-hw:'$releaseVersion
    'sensencrypt:'$releaseVersion
    'sensdecrypt:'$releaseVersion
    'sensporch:'$releaseVersion
    'sensarchiver:'$releaseVersion
    'docker-registry-api:'$releaseVersion
    )

source /mnt/staging/default-creds.env
export HELM_EXPERIMENTAL_OCI=1
from=$SENSCR_NAME
fromimgreponame=$SENSCR_IMGREPO_NAME
fromhelmreponame=$SENSCR_HELMREPO_NAME
helm registry login $SENSCR_NAME -u $SENSCR_USER -p $SENSCR_PASSWD
echo $SENSCR_PASSWD | docker login $from --username $SENSCR_USER --password-stdin

source /mnt/staging/gkecreds/gke-defaults.env
to=$SENSCR_NAME
toimgreponame=$SENSCR_IMGREPO_NAME
tohelmreponame=$SENSCR_HELMREPO_NAME
helm registry login $SENSCR_NAME -u $SENSCR_USER -p $SENSCR_PASSWD
echo $SENSCR_PASSWD | docker login $to --username $SENSCR_USER --password-stdin

inthelmimages=('senscharts' 'senspcharts')
for i in "${inthelmimages[@]}"
do
   if [ -d "$i" ]; then
      echo $i dir already exists, try in another directory
      exit 1
   fi
   helm chart pull $from/$fromhelmreponame/$i:$releaseVersion 
   helm chart export $from/$fromhelmreponame/$i:$releaseVersion 
   helm chart save $i/ $to/$tohelmreponame/$i:$releaseVersion
   helm chart push $to/$tohelmreponame/$i:$releaseVersion
   rm -rf $i
done

for i in "${intimages[@]}"
do
   docker pull $from/$fromimgreponame/$i
   docker tag $from/$fromimgreponame/$i $to/$toimgreponame/$i
   docker push $to/$toimgreponame/$i
done

for i in "${extimages[@]}"
do
   docker pull $from/$fromimgreponame/$i
   docker tag $from/$fromimgreponame/$i $to/$toimgreponame/$i
   docker push $to/$toimgreponame/$i
done
