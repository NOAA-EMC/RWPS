#!/bin/sh
###############################################################################
# This script retrieves forecasts for ice for a particular forecast date and 
# cycle and processes the ice forecasts for a particular RWPS mesh.
###############################################################################
set -x

cd ${DATA}

# retrieve ice forecasts for global RTOFS and Alaska NBM as netcdf files
(
    ${USHrwps}/preprocess/rtofs/get_rtofs_ice.sh ${PDY} ${cyc}
    export err=$?; err_chk
)&
(
    ${USHrwps}/preprocess/nbm/get_nbm_ice.sh ${PDY} ${cyc}
    export err=$?; err_chk
) &

wait;

${HOMErwps}/ush/preprocess/process_ice.sh
export err=$?; err_chk
