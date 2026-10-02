#!/bin/bash

# This script processes marine current forecasts and prepare them for use with WW3 as 
# pre-interpolated forcing (AI- already interpolated).  Currently configured to 
# combine a background forecast from stofs with surface current forecasts from rtofs 
# global domain in deep water.

cd ${DATA}

stofscur="${DATA}/stofs.${PDY}.${cyc}/stofs_2d_glo.t${cyc}z.fields.cwl.vel.nc"
rtofscur="${DATA}/rtofs.${PDY}.nc"

varnames="u-vel:v-vel"

#name of blended wind
rwps_current=${frc}/${meshname}.${PDY}.${cyc}.current.nc
#rwps_current=${frc}/${meshname}.${PDY}.${cyc}.vel.stofsxrtofs.nc
echo "outputting combined stofs and rtofs currents to $rwps_current"

## STOFS interpolation
stofs_wghts="${interpwghtsdir}/InterpolationWeights.${meshname}.stofs.nc"
stofs_dists="${interpwghtsdir}/DistToBndy.${meshname}.stofs.nc"
stofs_rwps="${DATA}/${meshname}.${PDY}.${cyc}.vel.cwl.stofs.nc"
stofs_rwps_ti="${DATA}/${meshname}.${PDY}.${cyc}.vel.cwl.stofs.ti.nc"

## RTOFS interpolation
rtofs_wghts="${interpwghtsdir}/InterpolationWeights.${meshname}.rtofs.current.nc"
rtofs_dists="${interpwghtsdir}/DistToBndy.${meshname}.rtofs.current.nc"
rtofs_rwps="${DATA}/${meshname}.${PDY}.vel.rtofs.nc"
rtofs_rwps_ti="${DATA}/${meshname}.${PDY}.${cyc}.vel.cwl.rtofs.ti.nc"



if [ ! -f "${stofs_wghts}" ]; then
    echo "missing stofs interpolation weights file: ${stofs_wghts}"
    echo "compute with script compute_unstr_to_rwps_interp_weights.sh"
    exit 1
fi
if [ ! -f "${stofs_dists}" ]; then
    echo "missing stofs distance to boundary file: ${stofs_dists}"
    echo "compute with script compute_unstr_to_rwps_interp_weights.sh"
    exit 1
fi

# extrapolate with zero fill
python ${HOMErwps}/ush/preprocess/interpolate_with_weights.py ${stofscur} ${stofs_wghts} ${stofs_rwps} ${varnames} 0 &

if [ ! -f "${rtofs_wghts}" ]; then
    echo "missing rtofs interpolation weights file: ${stofs_wghts}"
    echo "compute with script ComputeGridToRWPSInterpWeights.py"
    exit 2
fi
if [ ! -f "${rtofs_dists}" ]; then
    echo "missing stofs distance to boundary file: ${rtofs_dists}"
    echo "compute with script compute_unstr_to_rwps_interp_weights.py"
    exit 2
fi

# no extrapolation
python ${HOMErwps}/ush/preprocess/interpolate_with_weights.py ${rtofscur} ${rtofs_wghts} ${rtofs_rwps} ${varnames} -1 &

wait;

python ${HOMErwps}/ush/preprocess/add_mesh_geom_to_file.py ${rtofs_rwps} ${mesh}
python ${HOMErwps}/ush/preprocess/add_mesh_geom_to_file.py ${stofs_rwps} ${mesh}

python ${HOMErwps}/ush/preprocess/interp_time.py ${stofs_rwps} ${rtofs_rwps} ${stofs_rwps_ti} ${varnames} False &

#interpolate from rtofs to common stofs and rtofs times within range of stofs time
#values out of range are extrapolated to assuming persistance
python ${HOMErwps}/ush/preprocess/interp_time.py ${stofs_rwps} ${rtofs_rwps} ${rtofs_rwps_ti} ${varnames} True &

wait

python ${HOMErwps}/ush/preprocess/add_err_var_to_file.py ${rtofs_rwps_ti} ${rtofs_dists} 100.:1.:50.:250.:50.
python ${HOMErwps}/ush/preprocess/add_err_var_to_file.py ${stofs_rwps_ti} ${stofs_dists} 1.:100.:50.:250.

python ${HOMErwps}/ush/preprocess/bayes_forecast_update.py ${stofs_rwps_ti} ${rtofs_rwps_ti} ${rwps_current} ${varnames}

