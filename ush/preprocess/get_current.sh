#!/bin/bash

# This script retrieves global RTOFS and STOFS as netcdf files
# Requires environmental variables:
# PDY=YYYYMMDD, 
# cyc=00,06... two digit cycle number

cd ${DATA}

${USHrwps}/preprocess/rtofs/get_rtofs.sh ${PDY} &
${USHrwps}/preprocess/stofs/get_stofs.sh ${PDY} ${cyc} current &
wait;
