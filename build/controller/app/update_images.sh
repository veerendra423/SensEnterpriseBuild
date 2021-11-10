#
# This script pulls in all of the images needed for this pipeline
# The versions to be pulled in are in the ./.env file
#
# Get prepare_policies image
#
maindir=.
if [ "$1" ];then
  maindir=$1
  cd $maindir
fi

docker-compose pull

#
# Get algorithm image
#
cp $maindir/.env $maindir/algorithmowner/
pushd $maindir/algorithmowner >> /dev/null
docker-compose pull
popd >> /dev/null

#
# Get operator images
#
cp  $maindir/.env $maindir/operator/
pushd $maindir/operator >> /dev/null
docker-compose pull
popd >> /dev/null

#
# Get outputowner images
#
cp $maindir/.env $maindir/outputowner/
pushd $maindir/outputowner >> /dev/null
docker-compose pull
popd >> /dev/null
#
# Get dataowner images
#
cp $maindir/.env $maindir/dataowner/
pushd $maindir/dataowner >> /dev/null
docker-compose pull
popd >> /dev/null
