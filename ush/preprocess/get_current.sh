#!/bin/bash

# This script retrieves global RTOFS and STOFS as netcdf files
cd $HOMErwps/ush/preprocess

rtofs/get_rtofs.sh $PDY &
stofs/get_stofs.sh $PDY $cyc current&
wait;
