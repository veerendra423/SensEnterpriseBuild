#!/bin/bash

set -o pipefail

# Define policy names, used in templates
export SENSENCRYPT_POLICY_NAME=$(cat /conf/config.yml | yq -r .config.policies.SENSENCRYPT_POLICY_NAME)
export ALGORITHM_POLICY_NAME=$(cat /conf/config.yml | yq -r .config.policies.ALGORITHM_POLICY_NAME)
export SENSDECRYPT_POLICY_NAME=$(cat /conf/config.yml | yq -r .config.policies.SENSDECRYPT_POLICY_NAME)
export SENSATTESTLIBTEST_POLICY_NAME=$(cat /conf/config.yml | yq -r .config.policies.SENSATTESTLIBTEST_POLICY_NAME)
export SENSGCSPUSH_POLICY_NAME=$(cat /conf/config.yml | yq -r .config.policies.SENSGCSPUSH_POLICY_NAME)
export SENSGCSPULL_POLICY_NAME=$(cat /conf/config.yml | yq -r .config.policies.SENSGCSPULL_POLICY_NAME)

# Define enclave measurements for the different components
# TODO these must be updated!
# The MRENCLAVEs can be queried by running the command from the comments below from within the appropriate container
export CAS_MRENCLAVE=$(cat /conf/config.yml | yq -r .config.mrenclave.CAS_MRENCLAVE)
export MRENCLAVE_SENSENCRYPT=$(cat /conf/config.yml | yq -r .config.mrenclave.MRENCLAVE_SENSENCRYPT)
export MRENCLAVE_ALGORITHM=$(cat /conf/config.yml | yq -r .config.mrenclave.MRENCLAVE_ALGORITHM)
export MRENCLAVE_SENSDECRYPT=$(cat /conf/config.yml | yq -r .config.mrenclave.MRENCLAVE_SENSDECRYPT)
export MRENCLAVE_SENSGCSPUSH=$(cat /conf/config.yml | yq -r .config.mrenclave.MRENCLAVE_SENSGCSPUSH)
export MRENCLAVE_SENSGCSPULL=$(cat /conf/config.yml | yq -r .config.mrenclave.MRENCLAVE_SENSGCSPULL)

# Define shared variables
export CAS_ADDR=$(cat /conf/config.yml | yq -r .config.hosts.CAS_ADDR)
export SENSENCRYPT_FSPF_KEY=$(cat /conf/config.yml | yq -r .config.SensEncrypt.fspfkey)
export SENSENCRYPT_FSPF_TAG=$(cat /conf/config.yml | yq -r .config.SensEncrypt.fspftag)
export SENSDECRYPT_FSPF_KEY=$(cat /conf/config.yml | yq -r .config.SensDecrypt.fspfkey)
export SENSDECRYPT_FSPF_TAG=$(cat /conf/config.yml | yq -r .config.SensDecrypt.fspftag)
export ALGORITHM_FSPF_KEY=$(cat /conf/config.yml | yq -r .config.algorithm.fspfkey)
export ALGORITHM_FSPF_TAG=$(cat /conf/config.yml | yq -r .config.algorithm.fspftag)
export ALGORITHM_COMMAND=$(cat /conf/config.yml | yq -r .config.algorithm.command)
export PLATFORM_EDDSA_KEY=$(cat /conf/config.yml | yq -r .config.platform.platform_eddsa_key)

# GCS Push variables
export PUSH_BUCKET_NAME=$(cat /conf/config.yml | yq -r .config.SensStoragePush.bucket_name)
echo "PUSH_BUCKET_NAME=$PUSH_BUCKET_NAME"
export PUSH_INPUT_PATH=$(cat /conf/config.yml | yq -r .config.SensStoragePush.folder_path)
echo "PUSH_INPUT_PATH=$PUSH_INPUT_PATH"
export PUSH_OBJECT_PREFIX=$(cat /conf/config.yml | yq -r .config.SensStoragePush.object_prefix)
echo "PUSH_OBJECT_PREFIX=$PUSH_OBJECT_PREFIX"
export PUSH_STORAGE_CREDENTIALS=$(cat /conf/config.yml | yq -r .config.SensStoragePush.storage_credentials)
echo "PUSH_STORAGE_CREDENTIALS=REDACTED"
export PUSH_STORAGE_PROVIDER=$(cat /conf/config.yml | yq -r .config.SensStoragePush.storage_provider)
echo "PUSH_STORAGE_PROVIDER=$PUSH_STORAGE_PROVIDER"

# GCS Pull variables
export PULL_BUCKET_NAME=$(cat /conf/config.yml | yq -r .config.SensStoragePull.bucket_name)
echo "PULL_BUCKET_NAME=$PULL_BUCKET_NAME"
export PULL_OUTPUT_PATH=$(cat /conf/config.yml | yq -r .config.SensStoragePull.folder_path)
echo "PULL_OUTPUT_PATH=$PULL_OUTPUT_PATH"
export PULL_OBJECT_PREFIX=$(cat /conf/config.yml | yq -r .config.SensStoragePull.object_prefix)
echo "PULL_OBJECT_PREFIX=$PULL_OBJECT_PREFIX"
export PULL_STORAGE_CREDENTIALS=$(cat /conf/config.yml | yq -r .config.SensStoragePull.storage_credentials)
echo "PULL_STORAGE_CREDENTIALS=REDACTED"
export PULL_STORAGE_PROVIDER=$(cat /conf/config.yml | yq -r .config.SensStoragePull.storage_provider)
echo "PULL_STORAGE_PROVIDER=$PULL_STORAGE_PROVIDER"
