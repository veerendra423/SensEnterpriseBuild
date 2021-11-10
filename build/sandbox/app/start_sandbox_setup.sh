#!/bin/bash
main_dir=.
if [ "$1" ];then
  main_dir=/opt/$1/app
fi
docker login -u bb3fd7f0-72e4-4d76-ace4-b17582cc1993 -p mHhFNKgo-Bp2sY9pylu~ayLSMCPJuV3S1r sensoriant.azurecr.io
echo "$(date)" > start_sandbox.log
{
$main_dir/update_images.sh $main_dir
$main_dir/start_senslls.sh $main_dir
$main_dir/wait_ras_server.sh $main_dir
$main_dir/start_senslas.sh $main_dir
# Copy required files from the aprep container image
pushd $main_dir >> /dev/null
./setup_pipeline_agent.sh
popd >> /dev/null
# Start scli
pushd $main_dir/operator >> /dev/null
cp ../.env .env
docker-compose up -d senscli
popd >> /dev/null
#
# If SGX driver detected then launch SCONE LAS
#
exists=$(lsmod | grep -c isgx)
if [ $exists -eq 1 ]; then
    echo "SGX installed, launching SCONE LAS"
    $main_dir/start_las.sh $main_dir
fi
} >> $main_dir/start_sandbox.log 2>&1

pushd $main_dir >> /dev/null
# Monitors for pipeline.json to be submitted
# Does not return from this script
./run_pipelines.sh
