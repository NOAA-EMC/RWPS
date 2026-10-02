#!/bin/bash

#Retrieve global RTOFS ice forecast and consolidate in single NetCDF filesin
# Script to retrieve nbm ice forecast and convert to netcdf using wgrib2. 
# Requires environmental variables:
# {PDY}=YYYYMMDD, 
# {cyc}=00,06... two digit cycle number
# tmp = work directory to write output files to
#
# call as:
# $ sh get_rtofs_ice.sh

tmpdir="${DATA}/tmp.rtofsIce.${PDY}"
filesin="${COMINrtofs}/*ice.nc"
dirout="${DATA}/ice.${PDY}.${cyc}"
flout="${dirout}/rtofs.ice.${PDY}.nc"

mkdir -p ${tmpdir}
cp ${filesin} ${tmpdir}/

PDYCC="${PDY}${cyc}"
python ${HOMErwps}/ush/preprocess/rtofs/get_rtofs_ice_fcst.py ${tmpdir} ${PDYCC} ${flout}

