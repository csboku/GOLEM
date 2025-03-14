#!/bin/bash

echo "### "`date`" Starting job $0: WRF clim run"

PROJECTS_DIR=/home/lv71391/karlicky/projects
LOCAL_DATA_DIR=/home/lv71391/karlicky/data
PROJECT=wrfchem
EXP=UCCI_9km_pokus1

WRF_WORK_DIR=$PROJECTS_DIR/$PROJECT/$EXP
WRF_DATA_DIR=$LOCAL_DATA_DIR/$PROJECT/$EXP

export PROJECT
export EXP
export WRF_WORK_DIR
export WRF_DATA_DIR

cd $WRF_WORK_DIR
if [[ `printenv SIM_NUM` ]]; then
    WRF_DATA_DIR=$LOCAL_DATA_DIR/$PROJECT/$EXP/$SIM_NUM
    export WRF_DATA_DIR
    echo "   ..."$SIM_NUM
else
    echo "   ...not managed run"
. ./WRFchem_config.sh
fi
#. ./WRFchem_preproc.sh
. ./WRFchem_main.sh

echo "### "`date`" End of script"