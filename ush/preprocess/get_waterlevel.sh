#!/bin/bash

# This script retrieves global STOFS water level as netcdf file
# environmental variables:
# PDY=YYYYMMDD 
# cyc=00,06... two digit cycle number
# must be set.
cd ${DATA}
${USHrwps}/preprocess/stofs/get_stofs.sh ${PDY} ${cyc} waterlevel 
