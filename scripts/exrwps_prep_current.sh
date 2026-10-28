#!/bin/sh
###############################################################################
# This script retrieves forecasts for current for a forecast date and cycle
# and processes the current forecasts for a particular RWPS mesh.
###############################################################################
set -x

cd ${DATA}

# retrieve global RTOFS and STOFS current forecasts as netcdf files

###############################################################################
# (A)
${USHrwps}/preprocess/rtofs/get_rtofs.sh ${PDY}
export err=$?; err_chk
###############################################################################

###############################################################################
# (B)
${USHrwps}/preprocess/stofs/get_stofs.sh ${PDY} ${cyc} current
export err=$?; err_chk
###############################################################################

# (A) and (B) can be executed in parallel but must both compleate before (C)

###############################################################################
# (C)
${HOMErwps}/ush/preprocess/process_current.sh
export err=$?; err_chk
###############################################################################
