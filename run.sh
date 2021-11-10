#!/bin/bash
source ./.env
RELEASE_TAG=${RELEASE_TAG}
SENSLAS_URL=${SENSLAS_URL}
SENSLAS_PORT=${SENSLAS_PORT}

start_senslls()
{
    echo "In start_senslls()"
    docker-compose up -d SensLLS
}

start_senslas()
{
    echo "In start_senslas()"
    docker-compose up -d SensLAS
}

start_sensras_agent()
{
    echo "In start_senras_agent()"
    docker-compose up -d ras_agent
}

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
    echo "PLATFORM_EDDSA_KEY=$PLATFORM_EDDSA_KEY"
    rm platformEDDSAKey.json
    echo -e "\nDone.."
}

rebuild_algorithm()
{
    echo "In rebuild_algorithm()"
    pushd images/NferenceAlgorithm
    ./encrypt_algorithm.sh
    popd
    docker-compose build algorithm-$ALGORITHM_MODE
    echo "Done.."
}

generate_sensencrypt_key()
{
    echo "In generate_sensencrypt_key()"
    pushd images/SensEncrypt/empty-output
    ./prepare_empty_fspf.sh
    popd   
    cat images/SensEncrypt/empty-output/.env >> .env
}

generate_sensdecrypt_key()
{
    echo "In generate_sensdecrypt_key()"
    pushd images/SensDecrypt/empty-output
    ./prepare_empty_fspf.sh
    popd   
    cat images/SensDecrypt/empty-output/.env >> .env
}

upload_policies()
{
    echo "In upload_policies()"
    ./update_config.sh
    echo "Done.."
}

encrypt_input_files()
{
    echo "In encrypt_input_files()"
    echo "Copying SensEncrypt volume.fspf to SensEncrypt output" 
    sudo cp ./images/SensEncrypt/empty-output/encrypted-output/* ./volumes/encrypt-output
    echo "Copying input files to SensEncrypt input directory" 
    sudo cp -r volumes/input/* volumes/encrypt-input/
    docker-compose run SensEncrypt
#    echo "TEMPORARY - By pass IPFS and GCS"
    sudo cp -r volumes/encrypt-output/* volumes/algorithm-input
    echo "Done.."
}

push_input_files_to_ipfs()
{
    echo "In push_input_files_to_ipfs()"
    #docker-compose run -e IPFS_DIR="${PipelineName}In" -v $PWD/volumes/encrypt-output:/sensipfspush-input SensIpfsPush
    echo "Done.."
}

pull_input_files_from_ipfs()
{
    echo "In pull_input_files_from_ipfs()"
    #docker-compose run -e IPFS_DIR="${PipelineName}In" -v $PWD/volumes/algorithm-input:/sensipfspull-output SensIpfsPull
    echo "Done.."
}

push_input_files_to_gcs()
{
    echo "In push_input_files_to_gcs()"
    #docker-compose run -e GCS_OBJECT_PREFIX="${PipelineName}In" -v $PWD/volumes/encrypt-output:/opt/sensoriant/gcs/push/filesToBucket SensGcsPush
    echo "Done.."
}

pull_input_files_from_gcs()
{
    echo "In pull_input_files_from_gcs()"
    #docker-compose run -e GCS_OBJECT_PREFIX="${PipelineName}In" -v $PWD/volumes/algorithm-input:/opt/sensoriant/gcs/pull/filesFromBucket SensGcsPull
    echo "Done.."
}

run_algorithm()
{
    echo "In run_algorithm()"
    echo "ALGORITHM_MODE = $ALGORITHM_MODE"
    #echo "Copying SensDecrypt volume.fspf to algorithm-output" 
    #sudo cp ./images/SensDecrypt/empty-output/encrypted-output/* ./volumes/algorithm-output    
    docker-compose run algorithm-$ALGORITHM_MODE
    echo "TEMPORARY - Bypass IPFS"
    sudo cp -r volumes/algorithm-output/* volumes/decrypt-input
    echo -e "\nDone.."
}

push_output_files_to_ipfs()
{
    echo "In push_output_files_to_ipfs()"
#    docker-compose run -e IPFS_DIR="${PipelineName}Out" -v $PWD/volumes/algorithm-output:/sensipfspush-input SensIpfsPush
    echo "Done.."
}

pull_output_files_from_ipfs()
{
    echo "In pull_output_files_from_ipfs()"
#    docker-compose run -e IPFS_DIR="${PipelineName}Out" -v $PWD/volumes/decrypt-input:/sensipfspull-output SensIpfsPull
    echo "Done.."
}

push_output_files_to_gcs()
{
    echo "In push_output_files_to_gcs()"
    #docker-compose run -e GCS_OBJECT_PREFIX="${PipelineName}Out" -v $PWD/volumes/algorithm-output:/opt/sensoriant/gcs/push/filesToBucket SensGcsPush
    echo "Done.."
}

pull_output_files_from_gcs()
{
    echo "In pull_output_files_from_gcs()"
    #docker-compose run -e GCS_OBJECT_PREFIX="${PipelineName}Out" -v $PWD/volumes/decrypt-input:/opt/sensoriant/gcs/pull/filesFromBucket SensGcsPull
    echo "Done.."
}

decrypt_output_files()
{
    echo "In decrypt_output_files()"
    docker-compose run SensDecrypt
    echo -e "\nDone.."
}

run_sensattestlibtest()
{
    echo "In run_sensattestlibtest()"
    echo "*****************************************************"
    echo "You must re-enable policy upload of test policy for this to work"
    echo "See policies/upload_policy.sh"
    echo "*****************************************************"
    docker-compose run SensAttestLibTest
    echo -e "\nDone.."
}

reset()
{
    echo "In reset()"
    sudo rm -rf volumes/encrypt*
    sudo rm -rf volumes/decrypt*
    sudo rm -rf volumes/algorithm*
#    sudo rm -rf volumes/algorithm-input/*
#    sudo rm -rf volumes/algorithm-output/*
    sudo rm -rf volumes/test*
    docker-compose down
    echo "Done.."
}

show_options()
{
    echo "--------------------------------------------------"
    echo "Sensoriant Pipeline Release: $RELEASE_TAG-Source"
    echo "Pipeline: $PipelineName" 
    echo "--------------------------------------------------"
    PS3='Please enter your choice: '
    options=("Start SensLLS" "Start SensLAS" "Start SensRAS Agent" "Get Platform Signing Key" "Generate SensEncrypt Key" "Generate SensDecrypt Key" "Rebuild Algorithm" "Upload Policies" "Encrypt Input Files" "Push Input Files to IPFS" "Pull Input Files from IPFS" "Push Input Files to GCS" "Pull Input Files from GCS" "Run Algorithm" "Push Output Files to IPFS" "Pull Output Files from IPFS" "Push Output Files to GCS" "Pull Output Files from GCS" "Decrypt Output Files" "Run SensAttestLibTest" "Reset" "Quit")
    select opt in "${options[@]}"
    do
        case $opt in
            "Start SensLLS")
             echo "Starting SensLLS"; start_senslls
             ;;
            "Start SensLAS")
             echo "Starting SensLAS"; start_senslas
             ;;
            "Start SensRAS Agent")
             echo "Starting SensRAS Agent"; start_sensras_agent
             ;;
            "Get Platform Signing Key")
             echo "Getting Platform Signing Key"; get_platform_signing_key
             ;;
            "Generate SensEncrypt Key")
             echo "Generating SensEncrypt Key"; generate_sensencrypt_key
             ;;
            "Generate SensDecrypt Key")
             echo "Generating SensDecrypt Key"; generate_sensdecrypt_key
             ;;
            "Rebuild Algorithm")
             echo "Rebuilding Algorithm"; rebuild_algorithm
             ;;
            "Upload Policies")
             echo "Uploading Policies"; upload_policies
             ;;
            "Encrypt Input Files")
             echo "Encrypting Files"; encrypt_input_files
             ;;
            "Push Input Files to IPFS")
             echo "Pushing Input Files to IPFS"; push_input_files_to_ipfs
             ;;
            "Pull Input Files from IPFS")
             echo "Pulling Input Files from IPFS"; pull_input_files_from_ipfs
             ;;
            "Push Input Files to GCS")
             echo "Pushing Input Files to GCS"; push_input_files_to_gcs
             ;;
            "Pull Input Files from GCS")
             echo "Pulling Input Files from GCS"; pull_input_files_from_gcs
             ;;
            "Run Algorithm")
             echo "Running Algorithm"; run_algorithm
             ;;
            "Push Output Files to IPFS")
             echo "Pushing Output Files to IPFS"; push_output_files_to_ipfs
             ;;
            "Pull Output Files from IPFS")
             echo "Pulling Output Files from IPFS"; pull_output_files_from_ipfs
             ;;
            "Push Output Files to GCS")
             echo "Pushing Output Files to GCS"; push_output_files_to_gcs
             ;;
            "Pull Output Files from GCS")
             echo "Pulling Output Files from GCS"; pull_output_files_from_gcs
             ;;
            "Decrypt Output Files")
             echo "Decrypting Output Files"; decrypt_output_files
             ;;
            "Run SensAttestLibTest")
             echo "Running SensAttestLibTest"; run_sensattestlibtest
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
    	replace_var ALGORITHM_MODE "hw" .env	
    else
	echo "No SGX installed, using sim mode for algorithm"
    	replace_var ALGORITHM_MODE "sim" .env	
    fi
    source ./.env
}

if [ -e $1 ]
then
    PipelineName="DefaultPipeline"
else
    PipelineName=$1
fi
check_sgx
show_options

