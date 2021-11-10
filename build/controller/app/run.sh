#!/bin/bash
source ./.env
RELEASE_TAG=${RELEASE_TAG}
SENSLAS_URL=${SENSLAS_URL}
SENSLAS_PORT=${SENSLAS_PORT}

replace_var()
{
        rc=`grep "^$1=" $3`
        if [ -z "$rc" ]; then
                echo $1=$2 >> $3
        else
                sed "\|^$1|s|=.*$|=$2|1" $3 > t
                mv t $3
        fi
}

get_platform_signing_key()
{
    echo "In get_platform_signing_key()"
    rc=`curl -s -w "%{http_code}" -o platformEDDSAKey.json -X POST $SENSLAS_URL:$SENSLAS_PORT/GetPlatformEDDSAKey?keyHandleId=0&nvramId=0`
    sleep 1
    if [ ! $rc == "200" ]; then
        echo "Error: Return Code from SensLAS = $rc"
	exit 1
    fi
    PLATFORM_EDDSA_KEY=`cat platformEDDSAKey.json | jq -r '.platformSigningKey'`
    replace_var PLATFORM_EDDSA_KEY ${PLATFORM_EDDSA_KEY} .env
    # echo "PLATFORM_EDDSA_KEY=$PLATFORM_EDDSA_KEY"
    rm platformEDDSAKey.json
    cp .env operator/
    echo -e "\nDone.."
}

prepare_pipeline()
{
    echo "In prepare_pipeline()"
    #cp /home/nference/.pipelineJsons/mostRecentPipeline.json ./operator/SensADK/sandbox/pipeline.json
    pushd operator/SensADK/sandbox >> /dev/null
    ./sbox-menu.sh
    rc=$?
    popd >> /dev/null
    if [ $rc -ne 0 ]; then
         exit $rc
    fi
#    cp .env algorithmowner/.env
#    source ./.env
    pushd operator/SensADK/sandbox >> /dev/null
    keyvars=$(./fetchkeys.sh)
    if [ $? -ne 0 ]; then
        echo "No keys to export"
        exit 1
    fi
    for x in ${keyvars[@]}; do
        echo $x | grep "^ *#" >> /dev/null
        if [ $? -ne 0 ]; then
		if [ "$SBOX_KEEP_KEYS" = "true" ]; then
		    echo $x >> ../../../keys/algorithm/.env
		fi
                export $x
        fi
    done
    popd >> /dev/null
    cp .env algorithmowner/.env
    source ./.env
    echo "Back to main.."
}

upload_policies()
{
    echo "In upload_policies()"
    ./upload_policies.sh
    rc=$?
    if [ ! "$SBOX_KEEP_KEYS" = "true" ]; then
	rm -f config.yml
    fi    
    if [ $rc -ne 0 ]; then
        echo "upload_policies failed!!"
        exit $rc
    fi
    echo "Done.."
}

pull_input_files_from_gcs()
{
    echo "In pull_input_files_from_gcs()"
    pushd ./algorithmowner > /dev/null
    docker-compose run -e GCS_OBJECT_PREFIX="${INPUT_DATASET_NAME}" -v $PWD/volumes/algorithm-input:/opt/sensoriant/gcs/pull/filesFromBucket SensGcsPull
    rc=$?
    popd > /dev/null
    if [ $rc -ne 0 ]; then
         exit $rc
    fi
    echo "Done.."
}

run_algorithm()
{
    echo "In run_algorithm()"
    echo "ALGORITHM_MODE = $ALGORITHM_MODE"
    echo "Starting algorithm docker...this may take a few seconds..."
    pushd ./algorithmowner > /dev/null
    docker-compose run --rm algorithm-$ALGORITHM_MODE 2>&1
    rc=$?
    docker rmi -f $ALGORITHM_IMAGE
    popd > /dev/null
    if [ $rc -ne 0 ]; then
         exit $rc
    fi
    echo "Done.."
}

push_output_files_to_gcs()
{
    echo "In push_output_files_to_gcs()"
    pushd ./algorithmowner > /dev/null
    docker-compose run -e GCS_OBJECT_PREFIX="${PIPELINE_ID}-${OUTPUT_DATASET_NAME}" -v $PWD/volumes/algorithm-output:/opt/sensoriant/gcs/push/filesToBucket SensGcsPush
    rc=$?
    popd > /dev/null
    if [ $rc -ne 0 ]; then
         exit $rc
    fi
    echo "Done.."
}

encrypt_output_key()
{
    echo "In encrypt_output_key()"
    if test -f "./keys/algorithm/.env"; then
        source ./keys/algorithm/.env >> /dev/null
    fi    
    echo $SENSDECRYPT_FSPF_KEY > operator/SensADK/sandbox/image/sdata/default/outputSymmetricKey
    pushd operator/SensADK/sandbox > /dev/null
    source ./config
    pushd image > /dev/null
    docker-compose run --rm SensCli sensec ek -b /algo/default/outputSymmetricKey -mpk /algo/output-rcvr-pub.pem -outdir /algo/default | tail -1 | jq -c 'del(."Command rcvd")'
    rc=$?
    popd > /dev/null
    popd > /dev/null
    rm -f operator/SensADK/sandbox/image/sdata/default/outputSymmetricKey
    if [ $rc -ne 0 ]; then
         exit $rc
    fi
    echo "Done.."
}    

upload_output_key()
{
    echo "In upload_output_key"
    DSFile=./algorithmowner/datasets/$PIPELINE_ID-$OUTPUT_DATASET_NAME.json
    echo "DSFile = $DSFile"
    if ! test -f $DSFile; then
        echo "No encrypted dataset is present ... " 
	return
    fi

    echo "Creating DataSet key"
    dsname=`cat $DSFile | jq -r '.name'`
    dsid=`cat $DSFile | jq -r '.id'`
    ensymk=\"`base64 -w0 ./operator/SensADK/sandbox/image/sdata/default/outputSymmetricKey-eb`\"
    echo "{
        \"name\": \"${dsname}-KEY\",
        \"encryptedSymmetricKey\": $ensymk,
        \"secureStreamPlatform\": {
            \"name\": \"$PLATFORM_NAME\",
            \"id\": \"$PLATFORM_ID\"
          },
        \"dataset\": {
        \"name\": \"$dsname\",
	\"id\":\"$dsid\"
	}
    }" > ./dskreq.json

    rm -f operator/SensADK/sandbox/image/sdata/default/outputSymmetricKey-eb
    echo Uploading DataSet Key to API Server
    dskj=`cat ./dskreq.json`
    plinfo=`curl -s -w "%{http_code}" --keepalive-time 30  --connect-timeout 500  --insecure -X POST "https://$SECURE_CLOUD_API_SERVER_IP/secure_cloud_api/v1/datasets/keys" -H  "accept: application/json" -H  "Content-Type: application/json" -d "$dskj"`
    if [ ! `echo $plinfo | tail -c 4` == "201" ]; then
        echo "Upload Output Dataset Key failed ..."
        echo $plinfo
	exit 1
    else
        echo "Upload Output Dataset Key passed ..."
    fi
#	rm -f ./dskreq.json
    echo "Done.."
}

reset()
{
    echo "In reset()"
    pushd ./algorithmowner > /dev/null
    sudo rm -rf volumes/algorithm*
    popd > /dev/null
    echo "Done.."
}

run_all()
{
	     reset
	     get_platform_signing_key
             prepare_pipeline
             upload_policies
             pull_input_files_from_gcs
             run_algorithm
             push_output_files_to_gcs
             encrypt_output_key
             upload_output_key
}

show_options()
{
    echo "-------------------------------------------"
    echo "Sensoriant Pipeline Release: $RELEASE_TAG" 
    echo "Pipeline: $PipelineName" 
    echo "-------------------------------------------"
    PS3='Please enter your choice: '
    options=("Get Platform Signing Key" "Prepare Pipeline" "Upload Policies" "Pull Input Files from GCS" "Run Algorithm" "Push Output Files to GCS" "Encrypt Output Key" "Upload Output Key" "Run all" "Reset" "Quit")
    select opt in "${options[@]}"
    do
        case $opt in
            "Get Platform Signing Key")
             echo "Getting Platform Signing Key"; get_platform_signing_key
             ;;
            "Prepare Pipeline")
             echo "Preparing Pipeline"; prepare_pipeline
             ;;
            "Upload Policies")
             echo "Uploading Policies"; upload_policies
             ;;
            "Pull Input Files from GCS")
             echo "Pulling Input Files from GCS"; pull_input_files_from_gcs
             ;;
            "Run Algorithm")
             echo "Running Algorithm"; run_algorithm
             ;;
            "Push Output Files to GCS")
             echo "Pushing Output Files to GCS"; push_output_files_to_gcs
             ;;
            "Encrypt Output Key")
             echo "Encrypting Output Key"; encrypt_output_key
             ;;
            "Upload Output Key")
             echo "Uploading Output Key"; upload_output_key
             ;;
            "Run all")
             echo "Executing the pipeline"; run_all 
	     break
             ;;
            "Reset")
             echo "Reset";reset
             ;;
            "Quit")
                break
                ;;
            *)
            PS3="" # this hides the prompt
                echo asdf | select foo in "${options[@]}"; do break; done # dummy select
                PS3="Please enter your choice: " # this displays the common prompt
                ;;
        esac
    done
}

check_sgx()
{
    exists=$(lsmod | grep -c isgx)
    if [ $exists -eq 1 ]; then
    echo "SGX installed, using hw mode for algorithm"
    echo "ALGORITHM_MODE=hw" >> .env
    else
    echo "No SGX installed, using sim mode for algorithm"
    echo "ALGORITHM_MODE=sim" >> .env
    fi
    source ./.env
}

if [ -e $1 ]
then
    PipelineName="DefaultPipeline"
else
    PipelineName=$1
fi
if [ -e $2 ]
then
    InputDataSetName="DefaultInputDataSet"
else
    InputDataSetName=$2
fi
if [ -e $3 ]
then
    OutputDataSetName="DefaultOutputDataSet"
else
    OutputDataSetName=$3
fi
#check_sgx
show_options
