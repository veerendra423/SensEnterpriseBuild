#!/bin/bash 

uname -r | grep -e "-azure" > /dev/null 2>&1
if [ $? -ne 0 ]; then
   echo "Build must be done on an Azure machine"
   exit 1
fi

#
exit_usage()
{
   echo "usage : $1 VERSION_X_X_X command "
   echo "commands - "
   echo "          build"
   echo "          build push"
   echo "          clean "
   echo "          lock "
   echo "          push"
   echo "          tag"
   echo "          unlock "
   echo "          update"
   exit 1
}

chmod 600 ccf.pem

# The build type arg is mandatory
if [ $# -lt 1 ]
then
    exit_usage
fi

RELEASE_TAG=`grep "^RELEASE_TAG" ../staging.env | awk -F "=" '{print $2}'`

if [ $1 != $RELEASE_TAG ];then
	echo "Release TAG=$RELEASE_TAG does not match the build tag $1. Please update the RELEASE_TAG in staging.env"
	exit 0
fi

source /mnt/staging/default-creds.env

BUILD_DIRECTORY=$PWD/..
SENS_REGISTRY=$SENSCR_NAME
SENS_REGISTRY_NAME=sensoriant
SENS_REPOSITORY_DIR=$SENSCR_IMGREPO_NAME
SENS_RELEASE_VERSION=$1
SENS_CMD=$2
SENS_SUBCMD=""
# Source some common function definitions
. common_functions.sh

check_target_arg $1
check_command_arg $2
if [ $? -ne 0 ]; then
    exit_usage
fi
check_subcommand_arg $3
if [ $? -ne 0 ]; then
SENS_SUBCMD=""
else
SENS_SUBCMD=$3
fi

update_code_from_master()
{
    echo_header " === Update code to master  ==="
    pushd ../  > /dev/null
    git pull
    ./update_submodules
    popd > /dev/null
}

if [ $SENS_CMD == "help" ];then
    exit 0
elif [ $SENS_CMD == "update" ];then
    update_code_from_master
    exit 0
fi

build_copy_files()
{
	echo "Copying $1"
        CURFILE=$(echo "$1")
	CURFILE="${CURFILE%\"}"
	CURFILE="${CURFILE#\"}"
	#foreach file copy from src to dest
	FILESRC=$(yq '.files.'"${CURFILE}"'.src' services.yml);FILESRC="${FILESRC%\"}";FILESRC="${FILESRC#\"}";
	FILEDEST=$(yq '.files.'"${CURFILE}"'.dest' services.yml);FILEDEST="${FILEDEST%\"}";FILEDEST="${FILEDEST#\"}";
	#set -x
	cp -rp ../../${FILESRC} target/${SENS_RELEASE_VERSION}/${FILEDEST}
	#set +x
}

build_service()
{
	#set -x
    CWD=$PWD
	###  Prune quotes from name
    CURSERVICE=$(echo "${service}")
	CURSERVICE="${CURSERVICE%\"}"
	CURSERVICE="${CURSERVICE#\"}"
	# foreach service build the docker 
    echo_debug " Service ${CURSERVICE}"
	BUILD_FLAG=$(yq '.services.'"${CURSERVICE}"'.build' services.yml)
	ENVFILE=$(yq '.services.'"${CURSERVICE}"'.environment' services.yml);ENVFILE="${ENVFILE%\"}";ENVFILE="${ENVFILE#\"}";
	SERVICE_NAME=$(yq '.services.'"${CURSERVICE}"'.name' services.yml);SERVICE_NAME="${SERVICE_NAME%\"}";SERVICE_NAME="${SERVICE_NAME#\"}";
	SOURCE_DIR=$(yq '.services.'"${CURSERVICE}"'.source' services.yml);SOURCE_DIR="${SOURCE_DIR%\"}";SOURCE_DIR="${SOURCE_DIR#\"}";
	TARGET_NAME=$(yq '.services.'"${CURSERVICE}"'.target' services.yml);TARGET_NAME="${TARGET_NAME%\"}";TARGET_NAME="${TARGET_NAME#\"}";
	IMAGE_TAG_NAME="${SENS_REGISTRY}/${SENS_REPOSITORY_DIR}/${TARGET_NAME}:${SENS_RELEASE_VERSION}"

	if ${BUILD_FLAG}; then
	   echo "Building ${SERVICE_NAME} with ${IMAGE_TAG_NAME} using ENVFILE ${ENVFILE}"
       # Extra step needed for Safectl to set up the correct Version information 
       if [ "${CURSERVICE}" == "Safectl" ];then
           pushd ../../images/Safectl >> /dev/null
           echo "Updating Version information in Safectl"
           make IMAGE_REGISTRY_RELEASE_TAG=${SENS_RELEASE_VERSION} releasetags
           popd >> /dev/null
       fi
	   #set -x
	   cat ../../${SOURCE_DIR}/docker-compose.yml | yq '.services."'"${SERVICE_NAME}"'".image = "'"${IMAGE_TAG_NAME}"'"' > ${CURSERVICE}.docker-compose.yml
	   #cp  ../../${SOURCE_DIR}/${ENVFILE} ${CURSERVICE}.${ENVFILE};
	   #docker-compose -f ${CURSERVICE}.docker-compose.yml --project-directory ../../${SOURCE_DIR}/ --env-file ${CWD}/${CURSERVICE}.${ENVFILE} build ${SERVICE_NAME}
	   cp  ../../staging.${CURTARGET}.env ${CURSERVICE}.${ENVFILE};
	   docker-compose -f ${CURSERVICE}.docker-compose.yml --project-directory ../../${SOURCE_DIR}/ --env-file ${CWD}/${CURSERVICE}.${ENVFILE} build -q ${SERVICE_NAME}
	   if [ $? -ne 0 ]; then
              echo_debug "Build failed for service ${CURSERVICE}"  
              exit 1 
       fi
	   #set +x
    fi
    
    # If Service is safectl then we have to copy out the dist directory from the container to the build area
    if [ "${CURSERVICE}" == "Safectl" ];then
        docker run --rm -v $CWD/../../images/Safectl:/temp ${IMAGE_TAG_NAME} cp -rp /usr/src/myapp/dist/ /temp
    fi
}

build_push()
{
    CWD=$PWD
    CURSERVICE=$(echo "${service}")
	CURSERVICE="${CURSERVICE%\"}"
	CURSERVICE="${CURSERVICE#\"}"
	PUSH_FLAG=$(yq '.services.'"${CURSERVICE}"'.push' services.yml)
	ENVFILE=$(yq '.services.'"${CURSERVICE}"'.environment' services.yml);ENVFILE="${ENVFILE%\"}";ENVFILE="${ENVFILE#\"}";
	SERVICE_NAME=$(yq '.services.'"${CURSERVICE}"'.name' services.yml);SERVICE_NAME="${SERVICE_NAME%\"}";SERVICE_NAME="${SERVICE_NAME#\"}";
	SOURCE_DIR=$(yq '.services.'"${CURSERVICE}"'.source' services.yml);SOURCE_DIR="${SOURCE_DIR%\"}";SOURCE_DIR="${SOURCE_DIR#\"}";
	TARGET_NAME=$(yq '.services.'"${CURSERVICE}"'.target' services.yml);TARGET_NAME="${TARGET_NAME%\"}";TARGET_NAME="${TARGET_NAME#\"}";
	IMAGE_TAG_NAME="${SENS_REGISTRY}/${SENS_REPOSITORY_DIR}/${TARGET_NAME}:${SENS_RELEASE_VERSION}"
	if ${PUSH_FLAG}; then
		#set -x
            echo "Pushing image ${IMAGE_TAG_NAME} for service ${CURSERVICE}"  
	    cat ../../${SOURCE_DIR}/docker-compose.yml | yq '.services."'"${SERVICE_NAME}"'".image = "'"${IMAGE_TAG_NAME}"'"' > ${CURSERVICE}.docker-compose.yml
	    #cp  ../../${SOURCE_DIR}/${ENVFILE} ${CURSERVICE}.${ENVFILE};
	    echo $CWD
	    cp  ../../staging.${CURTARGET}.env ${CURSERVICE}.${ENVFILE};

    	    docker-compose -f ${CURSERVICE}.docker-compose.yml --project-directory ../../${SOURCE_DIR}/ --env-file ${CWD}/${CURSERVICE}.${ENVFILE} push ${SERVICE_NAME}
            if [ $? -ne 0 ]; then
	        echo_header "Push failed for service ${CURSERVICE}"
                #exit 0; 
            fi
	    DIGEST_VAL=`az acr repository show -n "$SENS_REGISTRY_NAME" --image "${SENS_REPOSITORY_DIR}/${TARGET_NAME}:${SENS_RELEASE_VERSION}" | jq -r '.digest' | cut -d ":" -f 2`
	    #DIGEST_NAME=`grep -w ${SENS_REPOSITORY_DIR}/${TARGET_NAME} ../../staging.env | cut -d "=" -f 1 | sed 's/_IMAGENAME/_DIGEST/g'`
	    DIGEST_NAME=`grep -w /${TARGET_NAME}$ ../../staging.env | cut -d "=" -f 1 | sed 's/_IMAGENAME/_DIGEST/g'`
	    if [ ! -z "$DIGEST_NAME" ]; then
	        echo $DIGEST_NAME=$DIGEST_VAL >> digest.env 
        fi
	    #set +x
    fi
}

build_lock()
{
        WRITE_ENABLE=$2
        CWD=$PWD
        CURSERVICE=$(echo "${service}")
	CURSERVICE="${CURSERVICE%\"}"
	CURSERVICE="${CURSERVICE#\"}"
	#set -x
	LOCK_FLAG=$(yq '.services.'"${CURSERVICE}"'.lock' services.yml)
	ENVFILE=$(yq '.services.'"${CURSERVICE}"'.environment' services.yml);ENVFILE="${ENVFILE%\"}";ENVFILE="${ENVFILE#\"}";
	SERVICE_NAME=$(yq '.services.'"${CURSERVICE}"'.name' services.yml);SERVICE_NAME="${SERVICE_NAME%\"}";SERVICE_NAME="${SERVICE_NAME#\"}";
	SOURCE_DIR=$(yq '.services.'"${CURSERVICE}"'.source' services.yml);SOURCE_DIR="${SOURCE_DIR%\"}";SOURCE_DIR="${SOURCE_DIR#\"}";
	TARGET_NAME=$(yq '.services.'"${CURSERVICE}"'.target' services.yml);TARGET_NAME="${TARGET_NAME%\"}";TARGET_NAME="${TARGET_NAME#\"}";
	if ${LOCK_FLAG}; then
	    IMAGE_NAME="${SENS_REPOSITORY_DIR}/${TARGET_NAME}:${SENS_RELEASE_VERSION}"
	    if [ ${WRITE_ENABLE} == true ];then
                echo "Unlocking image ${IMAGE_NAME} for service ${CURSERVICE}"
	        az acr repository update --name sensoriant --image ${IMAGE_NAME} --write-enabled ${WRITE_ENABLE}
            else
                echo "Locking image ${IMAGE_NAME} for service ${CURSERVICE}"  
	        az acr repository update --name sensoriant --image ${IMAGE_NAME} --write-enabled ${WRITE_ENABLE}
            fi
	fi
	#set +x

}

build_target()
{
    CURTARGET=$(echo "$1")
    echo_header " === Building ${CURTARGET} ==="
    pushd ${CURTARGET}  > /dev/null
    rm -rf target/${SENS_RELEASE_VERSION}/
    mkdir -p target/${SENS_RELEASE_VERSION}
    if [ "${CURTARGET}" != "clienttools" ];then
        cp -rp app target/${SENS_RELEASE_VERSION}
    fi
    BUILDERROR=0

    SERVICELIST=$(yq '.services | keys[]' services.yml )
    echo "#Generated from build_target.sh" > digest.env
    for service in $SERVICELIST 
    do
	#set -x
        if [ "${SENS_CMD}" == "build" ];then
            build_service ${service}
        fi
        if [ "${SENS_CMD}" == "push" ] || [ "${SENS_SUBCMD}" == "push" ];then
            build_push ${service}
        fi
        if [ "${SENS_CMD}" == "lock" ];then
            build_lock ${service} false
        fi
        if [ "${SENS_CMD}" == "unlock" ];then
            build_lock ${service} true
        fi
	#set +x
    done
   
    if [ "${SENS_CMD}" == "build" ] || [ "${SENS_CMD}" == "push" ];then
        FILELIST=$(yq '.files | keys[]' services.yml )
        for file in $FILELIST
        do
            build_copy_files ${file}
        done
    fi

    if [ "${SENS_CMD}" == "push" ] || [ "${SENS_SUBCMD}" == "push" ];then
        pushd target/${SENS_RELEASE_VERSION} >> /dev/null
        if [ "${CURTARGET}" != "clienttools" ];then        
            cat ../../digest.env >>  ./app/.env

            #
	        # Should be optimized
	        #
	        HW_MRENCLAVE_SENSGCSPULL=$(ssh -i ../../../ccf.pem build@sensccf.eastus.cloudapp.azure.com ./genmr/genmr.sh SensGcsPullAttested-hw ${SENS_RELEASE_VERSION})
    	    HW_MRENCLAVE_SENSGCSPUSH=$(ssh -i ../../../ccf.pem build@sensccf.eastus.cloudapp.azure.com ./genmr/genmr.sh SensGcsPushAttested-hw ${SENS_RELEASE_VERSION})
    	    echo "
HW_MRENCLAVE_SENSGCSPULL=${HW_MRENCLAVE_SENSGCSPULL}
HW_MRENCLAVE_SENSGCSPUSH=${HW_MRENCLAVE_SENSGCSPUSH}
if [ \"\${SENSORIANT_PLATFORM_PROVIDER}\" == \"AZURE\" ]; then
   MRENCLAVE_SENSGCSPULL=\${HW_MRENCLAVE_SENSGCSPULL}
   MRENCLAVE_SENSGCSPUSH=\${HW_MRENCLAVE_SENSGCSPUSH}
fi
    	" >> ./app/.env
        fi
	    tar cvzf ../../${CURTARGET}-${SENS_RELEASE_VERSION}.tar.gz * 
        popd >> /dev/null
    fi
    popd
}

az acr login --name sensoriant

sed '/#Generated from build_target.sh/,$d' ../staging.env > tmpstaging.env
mv tmpstaging.env ../staging.env

TARGETLIST=$(cat ${TARGETLISTFILE} | tr "\n" " ")
for target in $TARGETLIST
do
    cp ../staging.env ../staging.${target}.env
    build_target ${target}
done
if [ "${SENS_CMD}" == "push" ] || [ "${SENS_SUBCMD}" == "push" ];then
    cat controller/digest.env sandbox/digest.env | sort -u >> ../staging.env
    rm controller/digest.env
    rm sandbox/digest.env
    rm clienttools/digest.env
    #set -x
    HW_MRENCLAVE_SENSGCSPULL=$(ssh -i ccf.pem build@sensccf.eastus.cloudapp.azure.com ./genmr/genmr.sh SensGcsPullAttested-hw ${SENS_RELEASE_VERSION})
    HW_MRENCLAVE_SENSGCSPUSH=$(ssh -i ccf.pem build@sensccf.eastus.cloudapp.azure.com ./genmr/genmr.sh SensGcsPushAttested-hw ${SENS_RELEASE_VERSION})
    echo "
HW_MRENCLAVE_SENSGCSPULL=${HW_MRENCLAVE_SENSGCSPULL}
HW_MRENCLAVE_SENSGCSPUSH=${HW_MRENCLAVE_SENSGCSPUSH}
if [ \"\${SENSORIANT_PLATFORM_PROVIDER}\" == \"AZURE\" ]; then
   MRENCLAVE_SENSGCSPULL=\${HW_MRENCLAVE_SENSGCSPULL}
   MRENCLAVE_SENSGCSPUSH=\${HW_MRENCLAVE_SENSGCSPUSH}
fi
    " >> ../staging.env
    cp ../staging.env ../staging.controller.env
    cp ../staging.env ../staging.sandbox.env
    cp ../staging.env ../staging.clienttools.env
    cp ../staging.env ../dev.env
    cp ../staging.env ../.env    
    ./copyfiles.sh ${SENS_RELEASE_VERSION}
    ./push_safectl_images.sh ${SENS_RELEASE_VERSION}
    pushd ../images/SensHelmCharts >> /dev/null
    ./pushcharts.sh ${SENS_RELEASE_VERSION}
    popd >> /dev/null
    ./copybuildimages.sh ${SENS_RELEASE_VERSION}
    #set +x
fi
if [ "${SENS_CMD}" == "tag" ] ;then
    echo_header " === Tagging source for release ${SENS_RELEASE_VERSION} ==="
    ./tag_release.sh ${SENS_RELEASE_VERSION}
fi
