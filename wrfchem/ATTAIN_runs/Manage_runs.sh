#!/bin/bash

ys=(00 2007    2007   2007   2007   2015   2015   2015   2015   2016   2016   2016   2016   2016   2016   2016   2016  )
ms=(00 01      01     01     01     06     08     09     11     01     02     04     06     07     09     10     12    )
ds=(00 01      02     03     04     19     08     27     16     05     24     14     03     23     11     31     20    )
ts=(00 1       1      1      50     50     50     50     50     50     50     50     50     50     50     50     50    )
re=(00 .false. .true. .true. .true. .true. .true. .true. .true. .true. .true. .true. .true. .true. .true. .true. .true.)

cd /home/lv71391/karlicky/projects/wrfchem/UCCI_9km_pokus1
i=1
imax=3 # number of simulations
while [ $i -le $imax ]; do
    echo "#### PART"$(printf %02d $i)
    export SIM_NUM=part$(printf %02d $i)
    export SIMULATION_TIMESPAN=${ts[i]} # simulation timespan in days
    export START_Y=${ys[i]}
    export START_M=${ms[i]}
    export START_D=${ds[i]}
    export START_H=00
    export END_Y=${ys[i+1]}
    export END_M=${ms[i+1]}
    export END_D=${ds[i+1]}
    export END_H=00
    export TIM_REST=${re[i]}
    export TIM_RESTIN=1440
    export DOM_TS=50
    export GLOBAL_MODEL=ERAINT
    echo $(printf %02d $i),${ts[i]},${ys[i]},${ms[i]},${ds[i]},${ys[i+1]},${ms[i+1]},${ds[i+1]},${re[i]}
    . ./WRFchem_run.sh
i=$((i+1))
done

echo "End of managing script"