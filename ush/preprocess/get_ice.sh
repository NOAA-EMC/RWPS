#!/bin/bash

# This script retrieves ice forecasts for global RTOFS and Alaska NBM as netcdf files
# PDY=YYYYMMDD, 
# cyc=00,06... two digit cycle number

cd ${DATA}

${USHrwps}/preprocess/rtofs/get_rtofs_ice.sh ${PDY} ${cyc} &
${USHrwps}/preprocess/nbm/get_nbm_ice.sh ${PDY} ${cyc} &
wait;
