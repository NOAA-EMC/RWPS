#!/bin/bash

# This script retrieves ice forecasts for global RTOFS and Alaska NBM as netcdf files
# PDY=YYYYMMDD, 
# cyc=00,06... two digit cycle number

cd ${DATA}

${HOMErwps}/ush/preprocess/rtofs/get_rtofs_ice.sh ${PDY} ${cyc} &
${HOMErwps}/ush/preprocess/nbm/get_nbm_ice.sh ${PDY} ${cyc} &
wait;
