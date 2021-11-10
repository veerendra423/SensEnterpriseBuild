#!/bin/bash

set -euo pipefail

cd "${BASH_SOURCE%/*}"

DATAOWNER_CREDENTIAL=$(./get_public_credential.sh)
export DATAOWNER_CREDENTIAL
echo "Data owner credential is: $DATAOWNER_CREDENTIAL"

echo "Uploading algorithm owner policy sessions ..."
./algorithmowner/upload_policies.sh

echo "Uploading data owner policy sessions ..."
./dataowner/upload_policies.sh  

echo "Uploading output owner policy sessions ..."
./outputowner/upload_policies.sh

echo "Uploading sensgcspush policy sessions ..."
./sensgcspush/upload_policies.sh

echo "Uploading sensgcspull policy sessions ..."
./sensgcspull/upload_policies.sh

#
# Add this back to run the SensAttestLibTest option on menu
#echo "Uploading test owner policy sessions ..."
#./testowner/upload_policies.sh
