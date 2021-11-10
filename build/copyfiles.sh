RELEASE_DIR=/data/www/releases/$1
ssh -i ccf.pem ccf@sensccf.eastus.cloudapp.azure.com 'mkdir -p '$RELEASE_DIR
scp -i ccf.pem controller/controller-$1.tar.gz ccf@sensccf.eastus.cloudapp.azure.com:$RELEASE_DIR
scp -i ccf.pem sandbox/sandbox-$1.tar.gz ccf@sensccf.eastus.cloudapp.azure.com:$RELEASE_DIR
scp -i ccf.pem ../staging.env ccf@sensccf.eastus.cloudapp.azure.com:$RELEASE_DIR
sudo mkdir -p /mnt/staging/releases/$1
sudo cp ../staging.env /mnt/staging/releases/$1
sudo cp clienttools/clienttools-$1.tar.gz /mnt/staging/releases/$1
sudo cp /mnt/staging/default-creds.env /mnt/staging/releases/$1
sleep 10
ssh -i ccf.pem build@34.86.224.5 bash -c ./read_artifacts


