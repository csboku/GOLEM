#!/bin/bash

#SBATCH -N 4
#SBATCH --partition=mem_0096
#SBATCH --qos=p71391_0096
##SBATCH --account=p71391
#SBATCH -J Wrfchem
##SBATCH --mem=90G
#SBATCH --ntasks-per-node=48
#SBATCH --ntasks-per-core=1
##SBATCH --output=/home/lv71391/karlicky/data/wrfchem/UCCI_9km_pokus1/
##SBATCH --error=/home/lv71391/karlicky/data/wrfchem/UCCI_9km_pokus1/error/

#module purge
#. /binfl/lv71391/karlicky/bin/ifortvars.sh
#cd /binfl/lv71391/karlicky/projects/wrfchem/UCCI_9km_pokus1/run/
##ulimit -s unlimited
##srun -l -N1 -n1 wrf.exe
##srun -n 48 -N 1 ./WRF.sh

. /home/lv71391/karlicky/bin/ifortsource.sh
cd /home/lv71391/karlicky/projects/wrfchem/UCCI_9km_pokus1/run/
ulimit -s unlimited
mpirun -n 192 ./wrf.exe
