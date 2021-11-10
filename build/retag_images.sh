#!/bin/bash

# To access the .env file
source /mnt/staging/default-creds.env
source ../staging.env

# Array of docker released images
image_list=(''$PREPARE_POLICIES_IMAGENAME'' ''$SENSRAS_SERVER_IMAGENAME'' ''$DOCKER_REGISTRY_API_IMAGENAME'' ''$SECURE_CLOUD_API_IMAGENAME'' ''$SENSCLI_IMAGENAME'' ''$SENSLLS_IMAGENAME'' ''$SENSRLS_IMAGENAME'' ''$SENSPMGR_IMAGENAME'' ''$SENSPORCH_IMAGENAME'' ''$SENSARCHIVER_IMAGENAME'' ''$SENSLAS_IMAGENAME'' ''$SENSRAS_AGENT_IMAGENAME'' ''$SENSGCSPUSH_IMAGENAME'' ''$SENSGCSPULL_IMAGENAME'' ''$SENSPAGENT_IMAGENAME'' ''$SENSGCSPUSHATTESTED_SIM_IMAGENAME'' ''$SENSGCSPUSHATTESTED_HW_IMAGENAME'' ''$SENSGCSPULLATTESTED_SIM_IMAGENAME'' ''$SENSGCSPULLATTESTED_HW_IMAGENAME'' ''$SENSENCRYPT_IMAGENAME'' ''$SENSDECRYPT_IMAGENAME'')

echo "You are about to retag Safelishare images from $1 to $2"
read -p "Are you sure you want to continue? <y/N> " prompt
if [[ $prompt == "y" || $prompt == "Y" || $prompt == "yes" || $prompt == "Yes" ]]
then
    for image in "${image_list[@]}"
    do
        echo "Updating tag on $image:$1 to $image:$2"
        docker pull $image:$1
        docker tag $image:$1 $image:$2
        docker push $image:$2
    done
else
  exit 0
fi
