#!/bin/bash

source ./.env

docker pull $SENSPAGENT_IMAGENAME:$SENSPAGENT_TAG
docker tag $SENSPAGENT_IMAGENAME:$SENSPAGENT_TAG senspagent

if ! test -d originalfiles; then
   mkdir originalfiles
   mv run.sh originalfiles
   mv prepare_pipeline.sh originalfiles
   mv start_pipeline.sh originalfiles
   mv upload_policies.sh originalfiles
fi

sudo mkdir -p /pscripts
idu=$(id -u $NO_KUBE_SANDBOX_USER)
idg=$(id -g $NO_KUBE_SANDBOX_USER)
sudo chown $idu:$idg /pscripts
sudo chown $idu:$idg *.sh *.py
#sudo unlink /opt/default > /dev/null

sudo ln -sfn /opt/$RELEASE_TAG /opt/default
sudo mkdir -p /opt/default/app/operator/SensADK
sudo chown -R $idu:$idg /opt/default/app/operator/SensADK

docker run --rm -u $idu:$idg  -v $PWD:/sb senspagent bash -c "cp /opt/default/app/*.sh /sb; cp /opt/default/app/no_kube/*.* /sb"
docker run --rm -u $idu:$idg  -v $PWD:/sb senspagent bash -c "cp -R /opt/default/app/operator/SensADK/sandbox /sb/operator/SensADK"
