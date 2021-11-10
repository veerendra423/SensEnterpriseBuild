#!/bin/bash

set -euo pipefail

source "${BASH_SOURCE%/*}/../common_variables.sh" mariadb

export SCONE_CLI_CONFIG="~/.cas/dataowner-config.json"


# ================ Attest CAS ================

# attest CAS before uploading the session file, accept CAS running in debug
# mode (--only_for_testing-debug), outdated TCB (-G) and hyper-thread enabled (-C)
echo "Attesting CAS ..."
scone cas attest --accept-sw-hardening-needed --only_for_testing-debug --accept-group-out-of-date --only_for_testing-ignore-signer "$CAS_ADDR" "$CAS_MRENCLAVE"

# ================ Session 1: SensEncrypt ================

echo "Uploading policy session 1: SensEncrypt ..."
scone session read "${SENSENCRYPT_POLICY_NAME}" 2> /dev/null | yq -y -S 'del(.creator)' > current_sensencrypt_session.yml || true
policy_name=$(cat current_sensencrypt_session.yml | yq .name)
if [[ "$policy_name" == *"${SENSENCRYPT_POLICY_NAME}"* ]]; then
    SENSENCRYPT_PREDESSESOR_HASH=$(scone session verify --use-env "current_sensencrypt_session.yml")
    cat current_sensencrypt_session.yml | yq -y -S '.predecessor="'$SENSENCRYPT_PREDESSESOR_HASH'"' > temp.yml
    cat temp.yml > current_sensencrypt_session.yml
    cat current_sensencrypt_session.yml | yq -y -S '.volumes[0].fspf_key="'$SENSENCRYPT_FSPF_KEY'"' > temp.yml
    cat temp.yml > current_sensencrypt_session.yml    
    scone session update "current_sensencrypt_session.yml"
else
    scone session create --use-env "${BASH_SOURCE%/*}/templates/1_SSP_SensEncrypt.yml"
fi
rm -f current_sensencrypt_session.yml temp.yml
echo ""


