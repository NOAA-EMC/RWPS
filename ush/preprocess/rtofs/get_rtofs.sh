#!/bin/bash

#Retrieve global RTOFS currents and consolidate into a single NetCDF file

cd $HOMErwps/ush/preprocess

tmpdir="$COMINlocal/tmp.rtofs.$PDY"
filesin="$COMINrtofs/*prog.nc"
flout="$COMINlocal/rtofs.$PDY.nc"

mkdir -p $tmpdir
cp $filesin $tmpdir/
python rtofs/get_rtofs_fcst.py $tmpdir $flout

#rm -rf $tmpdir
