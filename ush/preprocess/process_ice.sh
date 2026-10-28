#!/bin/bash

# Program Name: proccess_ice.sh
# Author(s)/Contact(s): Keston Smith (keston.smith@noaa.gov)
#
# Abstract: 
# This script processes ice forecasts and prepares them for use with WW3 as pre-interpolated
# forcing (AI- already interpolated). Currently this script is configured to combine a 
# background forecast from rtofs global domain with the higher resolution nbm ak domain ice 
# forecast.
#
# History Log:
#
# Usage:
#  Parameters: 
#    
#  Input Files: (see script for expected location)
#    rtofsice      global rtofs ice concentration forecast file
#    nbmice        ak domain nbm ice concentration forecast file
#    stofs_wghts   interpolation weights to interpolate from stofs unstructured mesh to RWPS unstructured mesh
#    stofs_dists   distance to boundary stofs interpolation envelope for RWPS mesh as well as bathymetric depth.
#    rtofs_wghts   interpolation weights to interpolate from rtofs grid to RWPS unstructured mesh for ice field
#    rtofs_dists   distance to boundary of rtofs interpolation envelope for RWPS mesh

#  Output File:
#    rwps_ice  RWPS ice forcing
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
#    1 missing nbm ice forecast file
#    2 missing nbm ice interpolation weights file
#    3 missing nbm ice distance to boundary file
#    4 missing rtofs ice forecast file
#    5 missing rtofs ice interpolation weights file
#    6 missing rtofs ice distance to boundary file
#
#￼ User controllable options:
#    Error variance parameter specification for each forecast domain, defined by [interior error variance(m/s)]**2:[boundary error variance(m/s)**2]:[transition lengscale(km)] 
#    or
#    Error variance parameter specification for each forecast domain, defined by [constant error variance (m/s)**2] 

set -x

inpdir=${DATA}/ice.${PDY}.${cyc}

nbmice=$inpdir/nbm.${PDY}.${cyc}.ice.ak.nc
rtofsice=$inpdir/rtofs.ice.${PDY}.nc

rtofs_wghts="${FIXrwps}/${meshID}/InterpolationWeights.${meshname}.rtofs.ice.nc"
rtofs_dists="${FIXrwps}/${meshID}/DistToBndy.${meshname}.rtofs.ice.nc"
nbm_ak_wghts="${FIXrwps}/${meshID}/InterpolationWeights.${meshname}.nbm.ak.nc"
nbm_ak_dists="${FIXrwps}/${meshID}/DistToBndy.${meshname}.nbm.ak.nc"

rtofs_rwps="${DATA}/${meshname}.${PDY}.ice.rtofs.nc"
rtofs_rwps_ti="${DATA}/${meshname}.${PDY}.${cyc}.ice.rtofs.ti.nc"

nbm_rwps="${DATA}/${meshname}.${PDY}.${cyc}.ice.nbm.ak.nc"
nbm_rwps_ti="${DATA}/${meshname}.${PDY}.${cyc}.ice.nbm.ak.ti.nc"

varnames="ICEC_surface"

rwps_ice="${DATA}/${meshname}.${PDY}.${cyc}.ice.nc"

#TODO: nbmice should be treated as optional - need to update logic to fallback to just global rtofs ice
if [ ! -f "${nbmice}" ]; then
    msg = "FATAL ERROR: missing nbm ice concentration file: ${nbmice}"
    echo "$msg"
    postmsg "$msg"      
    err=1;export err;err_chk
    exit $err
fi
if [ ! -f "${nbm_ak_wghts}" ]; then
    echo msg = "FATAL ERROR: missing nbm ak interpolation weights file: ${nbm_ak_wghts}"
    echo "$msg"
    postmsg "$msg"      
    err=2;export err;err_chk
    exit $err
fi
if [ ! -f "${nbm_ak_dists}" ]; then
    msg = "FATAL ERROR: missing nbm ak  distance to boundary file: ${nbm_ak_dists}"
    echo "$msg"
    postmsg "$msg"      
    err=3;export err;err_chk
    exit $err
fi

###############################################################################
# (A)
# no extrapolation of ice beyond ak grid coverage
python ${USHrwps}/preprocess/interpolate_with_weights.py ${nbmice} ${nbm_ak_wghts} ${nbm_rwps} ${varnames} -1
export err=$?; err_chk                 # error checking
###############################################################################

###############################################################################
# (B)
if [ ! -f "${rtofsice}" ]; then
    echo msg = "FATAL ERROR: missing rtofs ice concentration file: ${rtofsice}"
    echo "$msg"
    postmsg "$msg"      
    err=4;export err;err_chk
    exit $err
fi
if [ ! -f "${rtofs_wghts}" ]; then
   msg = "FATAL ERROR: missing rtofs interpolation weights file: ${rtofs_wghts}"
   echo "$msg"
   postmsg "$msg"      
   err=5;export err;err_chk
   exit $err
fi
if [ ! -f "${rtofs_dists}" ]; then
   msg = "FATAL ERROR: missing stofs distance to boundary file: ${rtofs_dists}"
   echo "$msg"
   postmsg "$msg"      
   err=6;export err;err_chk
   exit $err
fi
# extrapolate with 0 as fill
python ${USHrwps}/preprocess/interpolate_with_weights.py ${rtofsice} ${rtofs_wghts} ${rtofs_rwps} ${varnames} 0
export err=$?; err_chk                 # error checking
###############################################################################

# (A) and (B) can be executed in parallel but must both compleate before (C) 

###############################################################################
# (C)
python ${USHrwps}/preprocess/add_mesh_geom_to_file.py ${rtofs_rwps} ${mesh}
export err=$?; err_chk                 # error checking
python ${USHrwps}/preprocess/add_mesh_geom_to_file.py ${nbm_rwps} ${mesh}
export err=$?; err_chk                 # error checking
###############################################################################

# after (C) compleates (D) and (E) can be executed in parallel

###############################################################################
# (D)
# interpolate from stofs to common stofs and rtofs times within range of stofs time
python ${USHrwps}/preprocess/interp_time.py ${rtofs_rwps} ${nbm_rwps} ${rtofs_rwps_ti} ${varnames} False 
export err=$?; err_chk                 # error checking
###############################################################################

###############################################################################
# (E)
# interpolate from rtofs to common stofs and rtofs times within range of stofs time
# values out of range are extrapolated to assuming persistance
python ${USHrwps}/preprocess/interp_time.py ${rtofs_rwps} ${nbm_rwps} ${nbm_rwps_ti} ${varnames} True
export err=$?; err_chk                 # error checking
###############################################################################

# (D) and (E) can be executed in parallel but must both compleate before (F)

###############################################################################
# (F)
#uniform variance of 100.
python ${USHrwps}/preprocess/add_err_var_to_file.py ${rtofs_rwps_ti} ${rtofs_dists} 100.
export err=$?; err_chk                 # error checking

#interior variance of 4., boundary variance fof 400., transition lengthscale 9. km
python ${USHrwps}/preprocess/add_err_var_to_file.py ${nbm_rwps_ti} ${nbm_ak_dists} 4.:400.:9.
export err=$?; err_chk                 # error checking

python ${USHrwps}/preprocess/bayes_forecast_update.py ${rtofs_rwps_ti} ${nbm_rwps_ti} ${rwps_ice} ${varnames}
export err=$?; err_chk                 # error checking
###############################################################################
