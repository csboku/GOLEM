#!/bin/bash

echo "debug"
. /home/lv71391/karlicky/bin/ifortsource.sh
cd /home/lv71391/karlicky/projects/wrfchem/UCCI_9km_pokus1/run/
ulimit -s unlimited
mpirun -n 48 ./wrf.exe