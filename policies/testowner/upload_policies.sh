#!/bin/bash

set -euo pipefail

source "${BASH_SOURCE%/*}/../common_variables.sh" algorithm
source "${BASH_SOURCE%/*}/test_variables.sh"

export SCONE_CLI_CONFIG="~/.cas/testowner-config.json"


# ================ Attest CAS ================

# attest CAS before uploading the session file, accept CAS running in debug
# mode (--only_for_testing-debug) and outdated TCB (-G)
echo "Attesting CAS ..."
scone cas attest -G --only_for_testing-debug "$CAS_ADDR" "$CAS_MRENCLAVE"


# ================ Session 6: Test ================
echo "Uploading policy session 6: test ..."
rm -f current_test_session.yml
scone session read "${SENSATTESTLIBTEST_POLICY_NAME}" 2> /dev/null | yq -y -S 'del(.creator)' > current_test_session.yml || true
policy_name=$(cat current_test_session.yml | yq .name)
if [[ "$policy_name" == *"${SENSATTESTLIBTEST_POLICY_NAME}"* ]]; then
    PREDESSESOR_HASH=$(scone session verify --use-env "current_test_session.yml") || true
    cat  current_test_session.yml | yq -y -S '.predecessor="'$PREDESSESOR_HASH'"' > temp.yml
    cat temp.yml > current_test_session.yml
    scone session update "current_test_session.yml" > predessesor_hash
    rm -f current_test_session.yml temp.yml
    echo -e "\nTest Policy updated"
    export TEST_UPDATED=true
else
    scone session create --cas cas --only_for_testing-disable-attestation-verification --use-env "${BASH_SOURCE%/*}/templates/session_template.yml"
    echo ""
fi

