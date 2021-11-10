#!/bin/bash
  
source ./.env

env_vars=()
env_vars+=( "SBOX_SUPPRESS_CMD_RCVD=true" )
env_vars+=( "SBOX_PRODUCT_VERSION=$SBOX_PROD_VERSION" )
env_vars+=( "SBOX_PRODUCT_VERSION=$SBOX_PROD_VERSION" )
env_vars+=( "SBOX_SENSE_REG=$SENSCLI_DREG" )
env_vars+=( "SBOX_SENSE_REG_USER=$SENSCLI_DCRED" )
if [ ! -z "$SBOX_KEEP_KEYS" ]; then
        env_vars+=( "SBOX_KEEP_KEYS_ON_DISK=$SBOX_KEEP_KEYS" )
else
        env_vars+=( "SBOX_KEEP_KEYS_ON_DISK=false" )
fi

for x in ${env_vars[@]}; do
        echo $x
done
