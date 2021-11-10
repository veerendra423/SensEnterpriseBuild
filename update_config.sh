#!/bin/bash

set -e
set -a
source ./.env
set +a
echo "Algorithm in $ALGORITHM_MODE mode"
if [ $ALGORITHM_MODE = "hw" ]
then
    docker-compose up -d las
    MRENCLAVE_ALGORITHM="$(docker-compose run --no-deps -eSCONE_HASH=1 algorithm-$ALGORITHM_MODE | tail -1)"
    MRENCLAVE_SENSGCSPUSH="$(docker-compose run --no-deps -eSCONE_HASH=1 SensGcsPushAttested-$ALGORITHM_MODE | tail -1)"
    MRENCLAVE_SENSGCSPULL="$(docker-compose run --no-deps -eSCONE_HASH=1 SensGcsPullAttested-$ALGORITHM_MODE | tail -1)"
else
    docker-compose up -d SensLAS
    MRENCLAVE_ALGORITHM="$(docker-compose run --no-deps -eSENS_HASH=1 algorithm-$ALGORITHM_MODE | tail -1)"
    MRENCLAVE_SENSGCSPUSH="$(docker-compose run --no-deps -eSENS_HASH=1 SensGcsPushAttested-$ALGORITHM_MODE | tail -1)"
    MRENCLAVE_SENSGCSPULL="$(docker-compose run --no-deps -eSENS_HASH=1 SensGcsPullAttested-$ALGORITHM_MODE | tail -1)"
fi

export ALGORITHM_ENTRYPOINT=${ALGORITHM_ENTRYPOINT}
export CAS_MRENCLAVE=${CAS_MRENCLAVE}
export CAS_IP_ADDR=${CAS_IP_ADDR}
echo "CAS_MRENCLAVE = ${CAS_MRENCLAVE}"
echo "CAS_IP_ADDR = ${CAS_IP_ADDR}"
export SENSENCRYPT_FSPF_KEY="${SENSENCRYPT_FSPF_KEY}"
export SENSENCRYPT_FSPF_TAG="${SENSENCRYPT_FSPF_TAG}"
export SENSDECRYPT_FSPF_KEY="${SENSDECRYPT_FSPF_KEY}"
export SENSDECRYPT_FSPF_TAG="${SENSDECRYPT_FSPF_TAG}"
export PLATFORM_EDDSA_KEY="${PLATFORM_EDDSA_KEY}"
echo "PLATFORM_EDDSA_KEY = ${PLATFORM_EDDSA_KEY}"
export POLICY_NAMESPACE=${POLICY_NAMESPACE}

#
# Needed for SensGcsPushAttested and SensGcsPullAttested
#
export GCS_BUCKET_NAME=${GCS_BUCKET_NAME}
echo "GCS_BUCKET_NAME=$GCS_BUCKET_NAME"
export GCS_INPUT_PATH=${GCS_INPUT_PATH}
echo "GCS_INPUT_PATH=$GCS_INPUT_PATH"
export GCS_OUTPUT_PATH=${GCS_OUTPUT_PATH}
echo "GCS_OUTPUT_PATH=$GCS_OUTPUT_PATH"
export GCS_OBJECT_PREFIX=${GCS_OBJECT_PREFIX}
echo "GCS_OBJECT_PREFIX=$GCS_OBJECT_PREFIX"
export GCS_PUSH_CREDENTIALS=${GCS_PUSH_CREDENTIALS}
export GCS_PULL_CREDENTIALS=${GCS_PULL_CREDENTIALS}

set -a
source ./keys/algorithm/.env
set +a
export ALGORITHM_FSPF_KEY="${FSPF_KEY}"
export ALGORITHM_FSPF_TAG="${FSPF_TAG}"

#CAS_MRENCLAVE="$(docker-compose run --no-deps -eSCONE_HASH=1 cas)"

MRENCLAVE_SENSENCRYPT="$(docker-compose run --no-deps -eSCONE_HASH=1 SensEncrypt | tail -1)"
echo "MRENCLAVE_SENSENCRYPT = $MRENCLAVE_SENSENCRYPT"
echo "MRENCLAVE_ALGORITHM = $MRENCLAVE_ALGORITHM"
MRENCLAVE_SENSDECRYPT="$(docker-compose run --no-deps -eSCONE_HASH=1 SensDecrypt | tail -1)"
echo "MRENCLAVE_SENSDECRYPT = $MRENCLAVE_SENSDECRYPT"
MRENCLAVE_SENSATTESTLIBTEST="$(docker-compose run --no-deps -eSCONE_HASH=1 SensAttestLibTest | tail -1)"


cat <<< "
config:
    mrenclave:
        CAS_MRENCLAVE: $CAS_MRENCLAVE 
        MRENCLAVE_SENSENCRYPT: $MRENCLAVE_SENSENCRYPT
        MRENCLAVE_ALGORITHM: $MRENCLAVE_ALGORITHM
        MRENCLAVE_SENSDECRYPT: $MRENCLAVE_SENSDECRYPT
        MRENCLAVE_SENSATTESTLIBTEST: $MRENCLAVE_SENSATTESTLIBTEST
        MRENCLAVE_SENSGCSPUSH: $MRENCLAVE_SENSGCSPUSH
        MRENCLAVE_SENSGCSPULL: $MRENCLAVE_SENSGCSPULL
    policies:
        SENSENCRYPT_POLICY_NAME: ${POLICY_NAMESPACE}-SensEncrypt_policy
        ALGORITHM_POLICY_NAME: ${POLICY_NAMESPACE}-algorithm_policy
        SENSDECRYPT_POLICY_NAME: ${POLICY_NAMESPACE}-SensDecrypt_policy
        SENSATTESTLIBTEST_POLICY_NAME: ${POLICY_NAMESPACE}-test_policy
        SENGCSPUSH_POLICY_NAME: ${POLICY_NAMESPACE}-SensGcsPush_policy	
        SENGCSPULL_POLICY_NAME: ${POLICY_NAMESPACE}-SensGcsPull_policy	
    SensEncrypt:
        fspfkey: $SENSENCRYPT_FSPF_KEY
        fspftag: $SENSENCRYPT_FSPF_TAG
    SensDecrypt:
        fspfkey: $SENSDECRYPT_FSPF_KEY
        fspftag: $SENSDECRYPT_FSPF_TAG
    algorithm:
        fspfkey: $ALGORITHM_FSPF_KEY
        fspftag: $ALGORITHM_FSPF_TAG
        entrypoint: $ALGORITHM_ENTRYPOINT
    SensGcsPush:
        bucket_name: $GCS_BUCKET_NAME
        input_path: $GCS_INPUT_PATH
        object_prefix: $GCS_OBJECT_PREFIX
        google_application_credentials: $GCS_PUSH_CREDENTIALS        
    SensGcsPull:
        bucket_name: $GCS_BUCKET_NAME
        output_path: $GCS_OUTPUT_PATH
        object_prefix: $GCS_OBJECT_PREFIX
        google_application_credentials: $GCS_PULL_CREDENTIALS        
    platform:
        platform_eddsa_key: $PLATFORM_EDDSA_KEY
    hosts:
        CAS_ADDR: cas
" > ./config.yml

echo ""
echo "Uploading policy sessions ..."
docker-compose run prepare_policies

echo ""
echo "Policy upload completed."

