#
# This script pulls in all of the images needed for the operator services
# The versions to be pulled in are in the ./.env file
#
#
# Get controller images
#
cd /opt/$1/app/operator
cp  ../.env .
docker-compose pull

#
# Set up SensRLS and SensLLS hostname
#
echo "SENSLLS_HOSTNAME=$(hostname)" >> .env
echo "SENSRLS_HOSTNAME=$(hostname)" >> .env
echo "SECURE_CLOUD_API_HOSTNAME=$(hostname)" >> .env

#
# Bring up the containers
#
docker-compose -f /opt/$1/app/operator/docker-compose.yml --project-directory /opt/$1/app/operator up -d SensRLS
sleep 10 # make sure RLS is up before LLS. Add wait here in future.
docker-compose -f /opt/$1/app/operator/docker-compose.yml --project-directory /opt/$1/app/operator up -d SensArchiver
docker-compose -f /opt/$1/app/operator/docker-compose.yml --project-directory /opt/$1/app/operator up -d SensLLS
docker-compose -f /opt/$1/app/operator/docker-compose.yml --project-directory /opt/$1/app/operator up -d SensMariaDb
docker-compose -f /opt/$1/app/operator/docker-compose.yml --project-directory /opt/$1/app/operator up -d cas
docker-compose -f /opt/$1/app/operator/docker-compose.yml --project-directory /opt/$1/app/operator up -d senscli
docker-compose -f /opt/$1/app/operator/docker-compose.yml --project-directory /opt/$1/app/operator up -d secure_cloud_api_container
docker-compose -f /opt/$1/app/operator/docker-compose.yml --project-directory /opt/$1/app/operator up -d nginx
docker-compose -f /opt/$1/app/operator/docker-compose.yml --project-directory /opt/$1/app/operator up -d SensPipelineMgr
sleep 10 # make sure everything is stable
docker-compose -f /opt/$1/app/operator/docker-compose.yml --project-directory /opt/$1/app/operator up -d ras_server
