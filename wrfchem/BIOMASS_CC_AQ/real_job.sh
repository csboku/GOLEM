#!/bin/bash
#SBATCH -J cs_real
#SBATCH -N 1
#SBATCH --partition=skylake_0384
#SBATCH --qos=p71391_0384
#SBATCH --account=p71391
#SBATCH --ntasks-per-node=48
#SBATCH --ntasks-per-core=2
#SBATCH --mail-type=BEGIN
#SBATCH --mail-type=END
#SBATCH --mail-user=christian.schmidt@boku.ac.at

module purge
source /gpfs/data/fs71391/cschmidt/projects/STOA/WRFCHEM/wrf_mpiifort/env.sh
ulimit -s unlimited

export I_MPI_PMI_LIBRARY=${SLURMBASE}/lib/libpmi.so


# Use srun instead of mpirun
srun -n 48 -N 1 ./real.exe
