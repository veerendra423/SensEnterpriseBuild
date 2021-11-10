#!/bin/bash

set -euo pipefail

source "${BASH_SOURCE%/*}/../common_variables.sh"

export SCONE_CLI_CONFIG="~/.cas/outputowner-config.json"


# ================ Attest CAS ================

# attest CAS before uploading the session file, accept CAS running in debug
# mode (--only_for_testing-debug) and outdated TCB (-G)
echo "Attesting CAS ..."
scone cas attest --accept-sw-hardening-needed --only_for_testing-debug --accept-group-out-of-date --only_for_testing-ignore-signer "$CAS_ADDR" "$CAS_MRENCLAVE"

# ================ Session 5: SensDecrypt ================

# set input path
INPUT_PATH="/encrypted-output"

echo "Uploading policy session 5: SensDecrypt ..."
scone session read "${SENSDECRYPT_POLICY_NAME}" 2> /dev/null | yq -y -S 'del(.creator)' > current_sensdecrypt_session.yml || true
policy_name=$(cat current_sensdecrypt_session.yml | yq .name)
if [[ "$policy_name" == *"${SENSDECRYPT_POLICY_NAME}"* ]]; then
    SENSDECRYPT_PREDECESSOR_HASH=$(scone session verify --use-env "current_sensdecrypt_session.yml") || true
    cat current_sensdecrypt_session.yml | yq -y -S '.predecessor="'$SENSDECRYPT_PREDECESSOR_HASH'"' > temp.yml
    cat temp.yml > current_sensdecrypt_session.yml
#    cat current_sensdecrypt_session.yml | yq -y -S '.volumes[0].fspf_tag="'$SENSDECRYPT_FSPF_TAG'"' > temp.yml
#    cat temp.yml > current_sensdecrypt_session.yml
    cat current_sensdecrypt_session.yml | yq -y -S '.volumes[0].fspf_key="'$SENSDECRYPT_FSPF_KEY'"' > temp.yml
    cat temp.yml > current_sensdecrypt_session.yml
    scone session update "current_sensdecrypt_session.yml"
else
    scone session create --use-env -e "INPUT_PATH=$INPUT_PATH" "${BASH_SOURCE%/*}/templates/5_SSP_SensDecrypt.yml"
fi
echo ""
rm -f current_sensdecrypt_session.yml temp.yml
unset INPUT_PATH
