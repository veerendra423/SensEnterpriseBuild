#!/bin/bash

set -euo pipefail

source "${BASH_SOURCE%/*}/../common_variables.sh" algorithm
source "${BASH_SOURCE%/*}/algorithm_variables.sh"

export SCONE_CLI_CONFIG="~/.cas/algorithmowner-config.json"


# ================ Attest CAS ================

# attest CAS before uploading the session file, accept CAS running in debug
# mode (--only_for_testing-debug) and outdated TCB (-G)
echo "Attesting CAS ..."
scone cas attest --accept-sw-hardening-needed --only_for_testing-debug --accept-group-out-of-date --only_for_testing-ignore-signer "$CAS_ADDR" "$CAS_MRENCLAVE"

# ================ Session 4: Algorithm ================
echo "Uploading policy session 4: algorithm ..."
rm -f current_alg_session.yml
scone session read "${ALGORITHM_POLICY_NAME}" 2> /dev/null | yq -y -S 'del(.creator)' > current_alg_session.yml || true
policy_name=$(cat current_alg_session.yml | yq .name)
if [[ "$policy_name" == *"${ALGORITHM_POLICY_NAME}"* ]]; then
    PREDESSESOR_HASH=$(scone session verify --use-env "current_alg_session.yml") || true
    cat  current_alg_session.yml | yq -y -S '.services[0].fspf_key="'$ALGORITHM_FSPF_KEY'"' > temp.yml
    cat temp.yml > current_alg_session.yml
    cat  current_alg_session.yml | yq -y -S '.services[0].fspf_tag="'$ALGORITHM_FSPF_TAG'"' > temp.yml
    cat temp.yml > current_alg_session.yml
    cat  current_alg_session.yml | yq -y -S '.services[0].mrenclaves[0]="'$MRENCLAVE_ALGORITHM'"' > temp.yml
    cat temp.yml > current_alg_session.yml
    cat  current_alg_session.yml | yq -y -S '.security.attestation.trusted_scone_qe_pubkeys[0]="'$PLATFORM_EDDSA_KEY'"' > temp.yml
    cat temp.yml > current_alg_session.yml
    cat  current_alg_session.yml | yq -y -S '.predecessor="'$PREDESSESOR_HASH'"' > temp.yml
    cat temp.yml > current_alg_session.yml
#    scone session update "current_alg_session.yml" > predessesor_hash
    scone session update "current_alg_session.yml"
    rm -f current_alg_session.yml temp.yml
    echo -e "\nAlgorithm Policy updated"
    export ALGORITHM_UPDATED=true
else
    scone session create --use-env "${BASH_SOURCE%/*}/templates/4_SSP_Algorithm.yml"
    echo ""
fi
