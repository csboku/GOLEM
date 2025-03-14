#!/bin/bash

echo "### "`date`" Starting $0: WRF Preprocesors:"

cd $WRF_WORK_DIR/run/

echo "### "`date`" Starting $0: 1. real.exe"
export CHEM_INP=0
export CHEM_BIOEM=0
. ../WRFchem_namelist.sh
#module purge
. /home/lv71391/karlicky/bin/ifortsource.sh
mpirun -n 4 ./real.exe
mv rsl.error.0000 rsl.error.real1
mv rsl.out.0000 rsl.out.real1
if [[ `cat rsl.out.real1 | grep SUCCESS` == "" ]]; then echo "Error occured !!!"; exit; fi

echo "### "`date`" Starting $0: 2. MEGAN"
./megan_bio_emiss < namelist.input > megan_bio_emiss.log

echo "### "`date`" Starting $0: 3. secondly real.exe"
export CHEM_BIOEM=3
. ../WRFchem_namelist.sh
mpirun -n 4 ./real.exe
mv rsl.error.0000 rsl.error.real2
mv rsl.out.0000 rsl.out.real2
if [[ `cat rsl.out.real2 | grep SUCCESS` == "" ]]; then echo "Error occured !!!"; exit; fi

echo "### "`date`" Starting $0: 4. mozbc"
./mozbc < RADM2SORGcch.inp > mozbc.out
if [[ `cat mozbc.out | grep completed` == "" ]]; then echo "Error occured !!!"; exit; fi

#echo "### "`date`" 5. link UBC"
#ln -s /net/meop-nas2.priv/volume2/data2/ucci/WRFchem/ICBC_chem/UBC/UBC_inputs/ubvals_b40.20th.track1_1996-2005.nc ./
#ln -s /net/meop-nas2.priv/volume2/data2/ucci/WRFchem/ICBC_chem/UBC/UBC_inputs/clim_p_trop.nc ./

cd $WRF_WORK_DIR