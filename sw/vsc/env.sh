module load intel-oneapi-compilers/2022.2.1-gcc-9.5.0-xg435ds
module load netcdf-fortran/4.6.0-oneapi-2022.2.1-fkrzdbf
module load netcdf-c/4.9.0-oneapi-2022.2.1-zyjdmgo
module load flex/2.6.4-intel-2021.7.1-suzyavx


export FFLAGS='-O3 -fp-model=fast -fiopenmp'
export CFLAGS='-O3 -fp-model=fast -fiopenmp -Wno-strict-prototypes -Wint-conversion'
export CXXFLAGS='-O3 -fp-model=fast -fiopenmp'
export LDFLAGS='-O3 -fiopenmp'

export WRF_DIR=/gpfs/data/fs71391/cschmidt/repos/STOA/WRFCHEM/WRF
export EM_CORE=1
export WRF_CHEM=1
export WRF_KPP=1
export FLEX_LIB_DIR="/gpfs/opt/sw/skylake/spack-0.19.0/opt/spack/linux-almalinux8-skylake_avx512/intel-2021.7.1/flex-2.6.4-suzyavxiay7w7indionjg6bxeiupapah/lib"
export NETCDF="/gpfs/data/fs71391/cschmidt/repos/STOA/WRFCHEM/sw"
export YACC="/gpfs/data/fs71391/cschmidt/repos/STOA/WRFCHEM/sw/bin/yacc -d"
