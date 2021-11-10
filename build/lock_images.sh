#!/bin/bash

# To access the .env file
. ./.env

# Array of Docker Released images with tags

arr=('nference/prepare_policies:'$PREPARE_POLICIES_TAG'' 'nference/sensencrypt:'$SENSENCRYPT_TAG'' 'nference/sensgcspush:'$SENSGCSPUSH_TAG'' 'nference/sensgcspull:'$SENSGCSPULL_TAG'' 'nference/ras-server:'$SENSRAS_SERVER_TAG'' 'nference/ras-agent:'$SENSRAS_AGENT_TAG'' 'priv-comp/las:'$LAS_TAG'' 'nference/secure-cloud-api:'$SECURE_CLOUD_API_TAG'' 'nference/docker-registry-api:'$DOCKER_REGISTRY_API_TAG'' 'nginx:'$NGINX_TAG'' 'priv-comp/prefect_image:'$PREFECT_TAG'' 'priv-comp/cas-preprovisioned:'$CAS_TAG'' 'nference/senslas:'$SENSLAS_TAG'' 'nference/scli:'$SENSCLI_TAG'' 'nference/sensdecrypt:'$SENSDECRYPT_TAG'' 'nference/algorithm:'$ALGORITHM_TAG'' )


# Signs and pushes into the sensoriant registry then locks with its image tag

for i in "${arr[@]}"
do
        #echo 'docker push --disable-content-trust=false sensoriant.azurecr.io/'$i''
        #docker push --disable-content-trust=false sensoriant.azurecr.io/$i
        echo 'az acr repository update --name sensoriant --image '$i' --write-enabled false'
        az acr repository update --name sensoriant --image $i --write-enabled false
done
