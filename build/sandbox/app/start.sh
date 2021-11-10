#
# This script pulls in all of the images needed for the operator services
# The versions to be pulled in are in the ./.env file
#
#
# Get controller images
#
cd /opt/$1/app/operator && \
cp  ../.env . && \
docker-compose pull && \
docker-compose -f /opt/$1/app/operator/docker-compose.yml --project-directory /opt/$1/app/operator up -d cas
docker-compose -f /opt/$1/app/operator/docker-compose.yml --project-directory /opt/$1/app/operator up -d secure_cloud_api_container
docker-compose -f /opt/$1/app/operator/docker-compose.yml --project-directory /opt/$1/app/operator up -d docker_registry_api_container
docker-compose -f /opt/$1/app/operator/docker-compose.yml --project-directory /opt/$1/app/operator up -d sens-mariadb
docker-compose -f /opt/$1/app/operator/docker-compose.yml --project-directory /opt/$1/app/operator up -d nginx
docker-compose -f /opt/$1/app/operator/docker-compose.yml --project-directory /opt/$1/app/operator up -d ras_server
docker-compose -f /opt/$1/app/operator/docker-compose.yml --project-directory /opt/$1/app/operator up -d senscli
