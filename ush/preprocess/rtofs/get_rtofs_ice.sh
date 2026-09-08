#!/bin/bash

#Retrieve global RTOFS ice forecast and consolidate in single NetCDF filesin

tmpdir="$COMINlocal/tmp.rtofsIce.$PDY"
filesin="$COMINrtofs/*ice.nc"
dirout="$COMINlocal/ice.$PDY.$cyc"
flout="$dirout/rtofs.ice.$PDY.nc"

mkdir $tmpdir
cp $filesin $tmpdir/
echo $tmpdir
echo $flout

PDYCC="${PDY}${cyc}"
echo $PDYCC
python rtofs/get_rtofs_ice_fcst.py $tmpdir $PDYCC $flout

