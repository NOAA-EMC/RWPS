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

#move forcing files from $DATA to $COMOUT and rename 
mkdir -p ${COMOUT}
cp ${DATA}/${NET}.${meshID}.${PDY}.${cyc}.waterlevel.nc ${COMOUT}/${NET}.t${cyc}z.${meshID}.waterlevel.nc

msg="JOB $job HAS COMPLETED NORMALLY."
postmsg "$msg"

