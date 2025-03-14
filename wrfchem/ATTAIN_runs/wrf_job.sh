#!/bin/bash

#SBATCH -J Attain_wrf
#SBATCH -N 2
#SBATCH --partition=skylake_0096
#SBATCH --qos=p71391_0096 
#SBATCH --account=p71391   
#SBATCH --ntasks-per-node=48
#SBATCH --ntasks-per-core=1
#SBATCH --mail-type=BEGIN    # first have to state the type of event to occur 
#SBATCH --mail-type=END    

#SBATCH --mail-user=christian.schmidt@boku.ac.at
module purge

source $DATA/wrf/wenv_one.sh

ulimit -s unlimited

mpirun -np 64 ./wrf.exe
