#!/bin/sh
###############################################################################
# This script retrieves forecasts for water level for forecast date and cycle
# and processes the waterlevel forecasts for a particular RWPS mesh.
###############################################################################
set -x

cd ${DATA}

# retrieve global STOFS water level forecast as netcdf file
${USHrwps}/preprocess/stofs/get_stofs.sh ${PDY} ${cyc} waterlevel 
export err=$?; err_chk

${HOMErwps}/ush/preprocess/process_waterlevel.sh
export err=$?; err_chk
