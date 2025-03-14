#!/bin/bash

echo "### "`date`" Starting $0: WRF-Chem main: wrf.exe"

cd $WRF_WORK_DIR/run/
export CHEM_INP=1
. ../WRFchem_namelist.sh

#. /home/lv71391/karlicky/bin/ifortsource.sh
#ulimit -s unlimited
#mpirun -n 12 ./wrf.exe

cd ..
jobname=WRFC$(printf %02d $i)
sbatch -J $jobname WRFexe2.sh
while [[ `squeue -n $jobname | grep $jobname` != "" ]] ; do
    sleep 100;
done

cd run/
if [[ `cat rsl.out.0000 | grep SUCCESS` == "" ]]; then echo "Error occured !!!"; exit; fi

#store data
if [ ! -d /$WRF_DATA_DIR/ ]; then
 mkdir -p /$WRF_DATA_DIR/
fi
mv wrfout* /$WRF_DATA_DIR/
mv wrfxtrm* /$WRF_DATA_DIR/
mv wrfinput* /$WRF_DATA_DIR/
mv wrfbdy* /$WRF_DATA_DIR/
mv wrflowinp* /$WRF_DATA_DIR/
mv wrfbiochemi* /$WRF_DATA_DIR/
mv rsl.out.0000 /$WRF_DATA_DIR/
mv rsl.error.0000 /$WRF_DATA_DIR/
cp namelist.input /$WRF_DATA_DIR/

echo "### "`date`" Starting $0: End of WRF main run"

cd $WRF_WORK_DIR