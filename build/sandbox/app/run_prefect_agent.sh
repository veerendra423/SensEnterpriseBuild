#!/bin/bash
set -a
source ./.env
set +a
export AZURE_HOST=$PREFECT_SERVER_ADDR
export PREFECT__SERVER__HOST=http://$AZURE_HOST
export PREFECT__SERVER__UI__GRAPHQL_URL=http://$AZURE_HOST:4200/graphql
export PREFECT__LOGGING__LEVEL=$PREFECT_LOG_LEVEL
export LC_ALL=C.UTF-8
export LANG=C.UTF-8
if [ $USE_PREFECT == false ]; then
    exit 0
fi
DEBIAN_FRONTEND=noninteractive
TZ="America/New_York"
sudo apt-get update -y && sudo apt-get install -y tzdata
sudo pip3 install prefect
prefect backend server
prefect agent local start &
sleep 15
python3 prefect_agent.py
