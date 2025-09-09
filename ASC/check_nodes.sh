#!/bin/bash
#SBATCH -J cs_test
#SBATCH -N 1
#SBATCH --ntasks=4
#SBATCH --partition=skylake_0096
#SBATCH --qos=p71391_0096
#SBATCH --account=p71391

# Check CPU frequency
echo "CPU Frequency on compute node:"
grep MHz /proc/cpuinfo | head -5
lscpu | grep MHz

# Compare with login node - run this directly on login:
# grep MHz /proc/cpuinfo | head -5
