#!/bin/bash


# Program Name: proccess_waterlevel.sh
# Author(s)/Contact(s): Keston Smith (keston.smith@noaa.gov)
#
# Abstract: 
# This script processes water level forecast from stofs prepares it for use with WW3 as 
# pre-interpolated forcing (AI- already interpolated).  
#
# History Log:
#
# Usage:
#  Parameters: 
#    
#  Input Files: (see script for expected location)
#    stofslevcur      global stofs depth averaged current forecast file
#    stofs_wghts   interpolation weights to interpolate from stofs unstructured mesh to RWPS unstructured mesh
#    stofs_dists   distance to boundary stofs interpolation envelope for RWPS mesh as well as bathymetric depth.
#
#  Output File:
#    rwps_waterlevel  RWPS water level forcing
#
# Imported Shell Variables:
#    PDY            YYYYMMDD
#    cyc            two digit forecat cycle, i.e. 00, 06, etc.
#    meshname       filename of RWPS mesh geometry file without path or .msh suffix, i.e. rwps.oc_500m_10km
#    DATA           working directory containg stofs and rtofs forecasts
#    DATA            output directory to write RWPS current forecast to
#
# Exit codes:
#    0 success
#    1 missing stofs waterlevel forecast file
#    2 missing stofs waterlevel interpolation weights file
#
# User controllable options: 

set -x

stofslev="${DATA}/stofs.${PDY}.${cyc}/stofs_2d_glo.t${cyc}z.fields.cwl.nc"
stofs_wghts="${FIXrwps}/${meshID}/InterpolationWeights.${meshname}.stofs.nc"
stofs_dists="${FIXrwps}/${meshID}/DistToBndy.${meshname}.stofs.nc"
stofs_rwps="${DATA}/${meshname}.${PDY}.${cyc}.cwl.waterlevel.nc"

rwps_waterlevel="${DATA}/${meshname}.${PDY}.${cyc}.waterlevel.nc"

varnames="zeta"

if [ ! -f "${stofslev}" ]; then
    msg = "FATAL ERROR: missing stofs waterlevel forecast: ${stofslev}"
    echo "$msg"
    postmsg "$msg"      
    err=1;export err;err_chk
    exit 1
fi

if [ ! -f "${stofs_wghts}" ]; then
    msg = "FATAL ERROR: missing stofs interpolation weights file: ${stofs_wghts}"
    echo $msg
    postmsg "$msg"      
    err=2;export err;err_chk
    exit 2
fi

python ${USHrwps}/preprocess/interpolate_with_weights.py ${stofslev} ${stofs_wghts} ${rwps_waterlevel} ${varnames} 0
export err=$?; err_chk                 # error checking

python ${USHrwps}/preprocess/add_mesh_geom_to_file.py ${rwps_waterlevel} ${mesh}
export err=$?; err_chk                 # error checking

if [ ! -f "${stofs_dists}" ]; then
    echo "WARNING: missing stofs distance to boundary file: ${stofs_dists}"
    echo "compute with script compute_unstr_to_rwps_interp_weights.sh"
    echo "continuing without adding error variance field to waterlevel forecast"
else
    python ${USHrwps}/preprocess/add_err_var_to_file.py ${rwps_waterlevel} ${stofs_dists} 1.
    err=$?;export err;err_chk   
fi
