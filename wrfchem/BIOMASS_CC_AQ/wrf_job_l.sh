#!/bin/bash

#SBATCH -J cs_wrf
#SBATCH -N 2
#SBATCH --partition=skylake_0384
#SBATCH --qos=p71391_0384
#SBATCH --account=p71391
#SBATCH --ntasks-per-core=2
#SBATCH --mail-type=BEGIN    # first have to state the type of event to occur
#SBATCH --mail-type=END

#SBATCH --mail-user=christian.schmidt@boku.ac.at
module purge

pwd

source /gpfs/data/fs71391/cschmidt/projects/STOA/WRFCHEM/wrf_mpiifort/env.sh

ulimit -s unlimited

export I_MPI_PMI_LIBRARY=${SLURMBASE}/lib/libpmi.so

srun -n 92 -N 2 ./wrf.exe
