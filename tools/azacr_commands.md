##  List tag status of a repo in registry
az acr repository show \
    --name sensoriant.azurecr.io --image nference/prepare_policies:VERSION_0_1_2 \
    --output jsonc


##  Lock tag of a repo in registry
az acr repository update \
    --name sensoriant --image nference/prepare_policies:VERSION_0_1_2 \
    --write-enabled false
