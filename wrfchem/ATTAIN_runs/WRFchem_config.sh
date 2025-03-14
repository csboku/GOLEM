#!/bin/bash

echo "### "`date`" Starting $0: WRF configuration settings"

export SIMULATION_TIMESPAN=2 # simulation timespan in days
export START_Y=2007
export START_M=01
export START_D=01
export START_H=00
export END_Y=2007
export END_M=01
export END_D=03
export END_H=00

# main
export TIM_REST='.false.'
export TIM_RESTIN=14400
export DOM_TS=50

# wps
export GLOBAL_MODEL=ERAINT
