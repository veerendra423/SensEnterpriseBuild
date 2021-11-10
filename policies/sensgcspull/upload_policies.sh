#!/bin/bash

set -euo pipefail

source "${BASH_SOURCE%/*}/../common_variables.sh"

export SCONE_CLI_CONFIG="~/.cas/sensgcspull-config.json"


# ================ Attest CAS ================

# attest CAS before uploading the session file, accept CAS running in debug
# mode (--only_for_testing-debug) and outdated TCB (-G)
echo "Attesting CAS ..."
scone cas attest ---accept-sw-hardening-needed --only_for_testing-debug --accept-group-out-of-date --only_for_testing-ignore-signer "$CAS_ADDR" "$CAS_MRENCLAVE"


# ================ Session 6: SensGcsPull ================
echo "Uploading policy session 6: SensGcsPull ..."
rm -f current_sensgcspull_session.yml
scone session read "${SENSGCSPULL_POLICY_NAME}" 2> /dev/null | yq -y -S 'del(.creator)' > current_sensgcspull_session.yml || true
policy_name=$(cat current_sensgcspull_session.yml | yq .name)
if [[ "$policy_name" == *"${SENSGCSPULL_POLICY_NAME}"* ]]; then
    echo "Updating SensGcsPull policy-${SENSGCSPULL_POLICY_NAME}"
    PREDESSESOR_HASH=$(scone session verify --use-env "current_sensgcspull_session.yml") || true
    cat  current_sensgcspull_session.yml | yq -y -S '.services[0].mrenclaves[0]="'$MRENCLAVE_SENSGCSPULL'"' > temp.yml
    cat temp.yml > current_sensgcspull_session.yml
    cat  current_sensgcspull_session.yml | yq -y -S '.security.attestation.trusted_scone_qe_pubkeys[0]="'$PLATFORM_EDDSA_KEY'"' > temp.yml
    cat temp.yml > current_sensgcspull_session.yml
    cat  current_sensgcspull_session.yml | yq -y -S '.predecessor="'$PREDESSESOR_HASH'"' > temp.yml
    cat temp.yml > current_sensgcspull_session.yml
    scone session update "current_sensgcspull_session.yml" > predessesor_hash
    rm -f current_sensgcspull_session.yml temp.yml
    echo -e "\nSENSGCSPULL Policy updated"
    export SENSGCSPUSH_UPDATED=true
else
    echo "Creating new SensGcsPull policy-${SENSGCSPULL_POLICY_NAME}"
    scone session create --use-env "${BASH_SOURCE%/*}/templates/sensgcspull_template.yml"
    echo ""
fi

