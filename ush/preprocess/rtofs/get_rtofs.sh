#!/bin/bash

#Retrieve global RTOFS currents and consolidate into a single NetCDF file
# Requires environmental variables:
# {PDY}=YYYYMMDD, 
# call as:
# $ sh get_rtofs.sh 20260829
# tmp = work directory to write output files to
# COMINrtofs = directory path to rtofs forecast


tmpdir="${DATA}/tmp.rtofs.${PDY}"
filesin="${COMINrtofs}/*prog.nc"
flout="${DATA}/rtofs.${PDY}.nc"

mkdir -p ${tmpdir}
cp ${filesin} ${tmpdir}/
python ${USHrwps}/preprocess/rtofs/get_rtofs_fcst.py ${tmpdir} ${flout}

