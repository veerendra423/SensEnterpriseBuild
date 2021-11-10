#!/bin/bash
main_dir=.
if [ "$1" ];then
  main_dir=/opt/$1/app
fi
docker login -u bb3fd7f0-72e4-4d76-ace4-b17582cc1993 -p 50b77c07-fc54-4c93-bd5b-e1d5aa5e26d1 sensoriant.azurecr.io
echo "$(date)" > start_sandbox.log
{
$main_dir/update_images.sh $main_dir
$main_dir/wait_ras_server.sh $main_dir
$main_dir/start_senslas.sh $main_dir

#
# If SGX driver detected then launch SCONE LAS
#
exists=$(lsmod | grep -c isgx)
if [ $exists -eq 1 ]; then
    echo "SGX installed, launching SCONE LAS"
    $main_dir/start_las.sh $main_dir
fi
} >> $main_dir/start_sandbox.log 2>&1
