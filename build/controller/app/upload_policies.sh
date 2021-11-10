#!/bin/bash

set -e
set -a
if test -f "./keys/algorithm/.env"; then
    source ./keys/algorithm/.env >> /dev/null
fi
set +a
export ALGORITHM_FSPF_KEY="${FSPF_KEY}"
export ALGORITHM_FSPF_TAG="${FSPF_TAG}"
export SENSENCRYPT_FSPF_KEY="${SENSENCRYPT_FSPF_KEY}"
export SENSDECRYPT_FSPF_KEY="${SENSDECRYPT_FSPF_KEY}"
echo "ALGORITHM_FSPF_KEY=${ALGORITHM_FSPF_KEY::8}"
echo "ALGORITHM_FSPF_TAG=${ALGORITHM_FSPF_TAG::8}"
echo "SENSENCRYPT_FSPF_KEY=${SENSENCRYPT_FSPF_KEY::8}"
echo "SENSDECRYPT_FSPF_KEY=${SENSDECRYPT_FSPF_KEY::8}"

source ./.env
export CAS_MRENCLAVE=${CAS_MRENCLAVE}
export CAS_IP_ADDR=${CAS_IP_ADDR}
echo "CAS_MRENCLAVE = ${CAS_MRENCLAVE::8}"
echo "CAS_IP_ADDR = ${CAS_IP_ADDR}"
export PLATFORM_EDDSA_KEY="${PLATFORM_EDDSA_KEY}"
echo "PLATFORM_EDDSA_KEY = ${PLATFORM_EDDSA_KEY::8}"
export POLICY_NAMESPACE=${POLICY_NAMESPACE}
echo "POLICY_NAMESPACE = $POLICY_NAMESPACE"
export ALGORITHM_ENTRYPOINT=${ALGORITHM_ENTRYPOINT}
echo "ALGORITHM_ENTRYPOINT=$ALGORITHM_ENTRYPOINT"

#
# Bring up LAS if not already up
# Azure Only
#pushd ./operator
#CAS_MRENCLAVE="$(docker-compose run --no-deps -eSCONE_HASH=1 cas | tail -1)"
#docker-compose up -d las
#popd > /dev/null


pushd ./algorithmowner > /dev/null
if [ $ALGORITHM_MODE = "hw" ]
then
	MRENCLAVE_ALGORITHM="$(docker-compose run --no-deps -eSCONE_HASH=1 algorithm-$ALGORITHM_MODE | tail -1)"
else
	MRENCLAVE_ALGORITHM="$(docker-compose run --no-deps -eSENS_HASH=1 algorithm-$ALGORITHM_MODE | tail -1)"
fi
rc=${PIPESTATUS[0]}
echo "MRENCLAVE_ALGORITHM = ${MRENCLAVE_ALGORITHM::8}"
popd > /dev/null
if [ $rc -ne 0 ]; then
     exit $rc
fi


cat <<< "
config:
    mrenclave:
        CAS_MRENCLAVE: $CAS_MRENCLAVE 
        MRENCLAVE_SENSENCRYPT: $MRENCLAVE_SENSENCRYPT
        MRENCLAVE_ALGORITHM: $MRENCLAVE_ALGORITHM
        MRENCLAVE_SENSDECRYPT: $MRENCLAVE_SENSDECRYPT
    policies:
        SENSENCRYPT_POLICY_NAME: $POLICY_NAMESPACE-SensEncrypt_policy
        ALGORITHM_POLICY_NAME: $POLICY_NAMESPACE-algorithm_policy
        SENSDECRYPT_POLICY_NAME: $POLICY_NAMESPACE-SensDecrypt_policy
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
    platform:
        platform_eddsa_key: $PLATFORM_EDDSA_KEY
    hosts:
        CAS_ADDR: cas
" > ./config.yml


echo ""
echo "Uploading policy sessions ..."
docker-compose run prepare_policies
rc=$?
if [ $rc -ne 0 ]; then
     echo "Policy Upload Failed.."
     exit $rc
fi
echo ""
echo "Policy upload completed."
