#!/bin/bash

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

replace_var ALGORITHM_IMAGE ${SBOX_IMAGE_UNENC_LOCALNAME} .env
replace_var PIPELINE_ID ${SBOX_PIPELINE_ID} .env
replace_var INPUT_DATASET_NAME ${SBOX_DATASET_NAME} .env
replace_var OUTPUT_DATASET_NAME ${SBOX_OUTPUT_DATASET_NAME} .env
replace_var PLATFORM_ID ${SBOX_SSP_ID} .env
replace_var PLATFORM_NAME ${SBOX_SSP_NAME} .env
replace_var POLICY_NAMESPACE ${SBOX_PIPELINE_ID} .env
replace_var GCS_PUSH_OBJECT_PREFIX ${SBOX_PIPELINE_ID}-${SBOX_OUTPUT_DATASET_NAME} .env
replace_var GCS_PULL_OBJECT_PREFIX ${SBOX_DATASET_NAME} .env

# any other stuff needed
