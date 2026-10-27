#!/bin/sh
###############################################################################
# This script retrieves forecasts for current for a forecast date and cycle
# and processes the current forecasts for a particular RWPS mesh.
###############################################################################
set -x

cd ${DATA}

# retrieve global RTOFS and STOFS current forecasts as netcdf files
(
    ${USHrwps}/preprocess/rtofs/get_rtofs.sh ${PDY}
    export err=$?; err_chk
) &
(
    ${USHrwps}/preprocess/stofs/get_stofs.sh ${PDY} ${cyc} current
    export err=$?; err_chk
) &

wait;

${HOMErwps}/ush/preprocess/process_current.sh
export err=$?; err_chk
