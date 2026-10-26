#!/bin/bash

# Program Name: proccess_currents.sh
# Author(s)/Contact(s): Keston Smith (keston.smith@noaa.gov)
#
# Abstract: 
# This script processes marine current forecasts and prepare them for use with WW3 as 
# pre-interpolated forcing (AI- already interpolated).  Currently configured to 
# combine a background forecast from stofs with surface current forecasts from rtofs 
# global domain in deep water. If rtofs forecast is not available then only stofs forecast will be used.
# If variable max_current_speed is defined, output current forecast will be truncated at max_current_speed.  

# History Log:
#
# Usage:
#  Parameters: 
#    
#  Input Files: (see script for expected location)
#    stofscur      global stofs depth averaged current forecast file
#    rtofscur      global rtofs surface current forecast file
#    stofs_wghts   interpolation weights to interpolate from stofs unstructured mesh to RWPS unstructured mesh
#    stofs_dists   distance to boundary stofs interpolation envelope for RWPS mesh as well as bathymetric depth.
#    rtofs_wghts   interpolation weights to interpolate from rtofs grid to RWPS unstructured mesh
#    rtofs_dists   distance to boundary of rtofs interpolation envelope for RWPS mesh as well as bathymetric depth.

#  Output File:
#    rwps_current  RWPS current forcing
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
#    1 missing stofs current forecast file
#    2 missing stofs current interpolation weights file
#    3 missing stofs distance to boundary file
#
# User controllable options: 
#    max_current_speed (localy defined in script): maximum current speed to impose on RWPS forcing

set -x

stofscur="${DATA}/stofs.${PDY}.${cyc}/stofs_2d_glo.t${cyc}z.fields.cwl.vel.nc"
rtofscur="${DATA}/rtofs.${PDY}.nc"

# Imposed current speed limit in (m/s). Comment out variable definition or set to infinity
# to not impose limit.  Artificially high currents can appear in STOFS forecast related to
# regions of wetting and drying.

max_current_speed=3.0
varnames="u-vel:v-vel"

#name of blended wind
rwps_current=${DATA}/${meshname}.${PDY}.${cyc}.current.nc
rwps_current_nolimit=${DATA}/${meshname}.${PDY}.${cyc}.current.nolimit.nc

## STOFS interpolation
stofs_wghts="${FIXrwps}/${meshID}/InterpolationWeights.${meshname}.stofs.nc"
stofs_dists="${FIXrwps}/${meshID}/DistToBndy.${meshname}.stofs.nc"
stofs_rwps="${DATA}/${meshname}.${PDY}.${cyc}.vel.cwl.stofs.nc"
stofs_rwps_ti="${DATA}/${meshname}.${PDY}.${cyc}.vel.cwl.stofs.ti.nc"

## RTOFS interpolation
rtofs_wghts="${FIXrwps}/${meshID}/InterpolationWeights.${meshname}.rtofs.current.nc"
rtofs_dists="${FIXrwps}/${meshID}/DistToBndy.${meshname}.rtofs.current.nc"
rtofs_rwps="${DATA}/${meshname}.${PDY}.vel.rtofs.nc"
rtofs_rwps_ti="${DATA}/${meshname}.${PDY}.${cyc}.vel.cwl.rtofs.ti.nc"

if [ ! -f "${stofscur}" ]; then
    echo "FATAL ERROR: missing stofs current forecast file: ${stofscur}"
    exit 1
fi

if [ ! -f "${stofs_wghts}" ]; then
    echo "FATAL ERROR: missing stofs interpolation weights file: ${stofs_wghts}"
    echo "compute with script compute_unstr_to_rwps_interp_weights.sh"
    exit 2
fi
if [ ! -f "${stofs_dists}" ]; then
    echo "FATAL ERROR: missing stofs distance to boundary file: ${stofs_dists}"
    echo "compute with script compute_unstr_to_rwps_interp_weights.sh"
    exit 3
fi

(
    # Extrapolate stofs forecast with zero as fill value
    python ${USHrwps}/preprocess/interpolate_with_weights.py ${stofscur} ${stofs_wghts} ${stofs_rwps} ${varnames} 0
    python ${USHrwps}/preprocess/add_mesh_geom_to_file.py ${stofs_rwps} ${mesh}
)&

if [ -f "${rtofscur}" ] && [ -f "${rtofs_wghts}" ] && [ -f "${rtofs_dists}" ]; then
    echo "RTOFS current forecast IS available. Combining with STOFS current forecast"
    echo "outputting combined stofs and rtofs currents to ${rwps_current}"
    (
        # No extrapolation of rtofs into shallows
        python ${USHrwps}/preprocess/interpolate_with_weights.py ${rtofscur} ${rtofs_wghts} ${rtofs_rwps} ${varnames} -1
        python ${USHrwps}/preprocess/add_mesh_geom_to_file.py ${rtofs_rwps} ${mesh}
    )&
    wait; # wait for spatial interpolation to RWPS mesh from stofs and rtofs forecasts to compleate

    (
        # interpolate stofs forecast to common stofs and rtofs times within range of stofs time
        python ${USHrwps}/preprocess/interp_time.py ${stofs_rwps} ${rtofs_rwps} ${stofs_rwps_ti} ${varnames} False
        # Add parmaterized error variance to stofs forecast. Favors stofs in shallow regions
        python ${USHrwps}/preprocess/add_err_var_to_file.py ${stofs_rwps_ti} ${stofs_dists} 1.:100.:50.:250.
    )&
    (
        # interpolate rtofs forecast to common stofs and rtofs times within range of stofs time
        python ${USHrwps}/preprocess/interp_time.py ${stofs_rwps} ${rtofs_rwps} ${rtofs_rwps_ti} ${varnames} True
        # Add parmaterized error variance to rtofs forecast. Favors rtofs in deep water and stofs in shallow regions.
        python ${USHrwps}/preprocess/add_err_var_to_file.py ${rtofs_rwps_ti} ${rtofs_dists} 100.:1.:50.:250.:50.
    )&
    wait;

    # combine stofs and rtofs forecast
    python ${USHrwps}/preprocess/bayes_forecast_update.py ${stofs_rwps_ti} ${rtofs_rwps_ti} ${rwps_current} ${varnames}
else
    echo "outputting STOFS current forecast to ${rwps_current}, Not using RTOFS current forecast."
    wait;  # wait for spatial interpolation to RWPS mesh from stofs forecast to compleate
    python ${USHrwps}/preprocess/add_err_var_to_file.py ${stofs_rwps} ${stofs_dists} 1.:100.:50.:250.
    cp ${stofs_rwps} ${rwps_current}
    if [ ! -f "${rtofscur}" ]; then
        echo "WARNING: No RTOFS current forecast available, missing ${rtofscur}. Using STOFS current forecast only."
    fi
    if [ ! -f "${rtofs_wghts}" ]; then
        echo "WARNING: missing rtofs interpolation weights file: ${rtofs_wghts}"
        echo "compute with script compute_gridded_to_rwps_interp_weights.py"
    fi
    if [ ! -f "${rtofs_dists}" ]; then
        echo "WARNING: missing rtofs  distance to boundary file: ${rtofs_dists}"
        echo "compute with script compute_gridded_to_rwps_interp_weights.py"
    fi
fi

if [[ -v max_current_speed ]]; then
    mv ${rwps_current} ${rwps_current_nolimit}

    # to limit current speed to max_current_speed:
#    python ${USHrwps}/preprocess/limit_max_current_speed.py ${rwps_current_nolimit} ${rwps_current} ${max_current_speed}

    # to replace all current forecasts faster than max_current_speed(m/s) with u=0.0 (m/s), v=0.0 (m/s)
    python ${USHrwps}/preprocess/limit_max_current_speed.py ${rwps_current_nolimit} ${rwps_current} ${max_current_speed} 0.
    echo "limiting maximum current speed to ${rwps_current}, limited field output to ${rwps_current}."
    echo "unlimited current field recorded at ${rwps_current_nolimit}."
fi
