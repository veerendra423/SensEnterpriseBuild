#!/bin/bash
source ./.env
RELEASE_TAG=${RELEASE_TAG}

start_senslas()
{
    echo "In start_senslas"
    docker-compose up -d SensLAS
    echo "Done.."
}

get_platform_id()
{
    echo "In get_platform_id"
    curl -X POST $SENSLAS_URL:$SENSLAS_PORT/GetPlatformId
    echo "Done.."
}

get_platform_eddsa_key()
{
    echo "In get_platform_eddsa_key"
    curl -s -o platformEDDSAKey.json -X POST $SENSLAS_URL:$SENSLAS_PORT/GetPlatformEDDSAKey?keyHandleId=0&nvramId=0 
    sleep 2
    echo "PLATFORM_EDDSA_KEY=`cat platformEDDSAKey.json | jq -r '.platformSigningKey'`"
    rm platformEDDSAKey.json
    echo -e "\nDone.."
}
stop_senslas()
{
    echo "In stop_senslas"
    docker-compose stop SensLAS
    echo "Done.."
}

show_options()
{
    echo "-------------------------------------------"
    echo "Sensoriant SensLAS API test: $RELEASE_TAG" 
    echo "-------------------------------------------"
    PS3='Please enter your choice: '
    options=("Start SensLAS" "Get Platform Id" "Get Platform EDDSA Key" "Stop SensLAS" "Quit")
    select opt in "${options[@]}"
    do
        case $opt in
            "Start SensLAS")
             echo "Starting SensLAS"; start_senslas
             ;;
            "Get Platform Id")
             echo "Getting Platform Id"; get_platform_id
             ;;
            "Get Platform EDDSA Key")
             echo "Getting Platform EDDSA Key"; get_platform_eddsa_key
             ;;
            "Stop SensLAS")
             echo "Stopping SensLAS"; stop_senslas
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

show_options
