#!/bin/bash

cd $HOMErwps/ush/preprocess

meshname="${mesh##*/}"
meshname="${meshname: 0: -4}"

stofscur="$tmp/stofs.$PDY.$cyc/stofs_2d_glo.t${cyc}z.fields.cwl.vel.nc"
rtofscur="$tmp/rtofs.$PDY.nc"

varnames="u-vel:v-vel"

#name of blended wind
rwps_current=$frc/$meshname.$PDY.$cyc.current.nc
#rwps_current=$frc/$meshname.$PDY.$cyc.vel.stofsxrtofs.nc
echo "outputting combined stofs and rtofs currents to $rwps_current"

## STOFS interpolation
stofs_wghts="$fix/InterpolationWeights.$meshname.stofs.nc"
stofs_dists="$fix/DistToBndy.$meshname.stofs.nc"
stofs_rwps="$tmp/$meshname.$PDY.$cyc.vel.cwl.stofs.nc"
stofs_rwps_ti="$tmp/$meshname.$PDY.$cyc.vel.cwl.stofs.ti.nc"



## RTOFS interpolation
rtofs_wghts="$fix/InterpolationWeights.$meshname.rtofs.current.nc"
rtofs_dists="$fix/DistToBndy.$meshname.rtofs.current.nc"
rtofs_rwps="$tmp/$meshname.$PDY.vel.rtofs.nc"
rtofs_rwps_ti="$tmp/$meshname.$PDY.$cyc.vel.cwl.rtofs.ti.nc"



if [ ! -f "$stofs_wghts" ]; then
    echo "missing stofs interpolation weights file: $stofs_wghts"
    echo "compute with script compute_unstr_to_rwps_interp_weights.sh"
    exit 1
fi
if [ ! -f "$stofs_dists" ]; then
    echo "missing stofs distance to boundary file: $stofs_dists"
    echo "compute with script compute_unstr_to_rwps_interp_weights.sh"
    exit 1
fi

# extrapolate with zero fill
python interpolate_with_weights.py $stofscur $stofs_wghts $stofs_rwps $varnames 0 &

if [ ! -f "$rtofs_wghts" ]; then
    echo "missing rtofs interpolation weights file: $stofs_wghts"
    echo "compute with script ComputeGridToRWPSInterpWeights.py"
    exit 2
fi
if [ ! -f "$rtofs_dists" ]; then
    echo "missing stofs distance to boundary file: $rtofs_dists"
    echo "compute with script compute_unstr_to_rwps_interp_weights.py"
    exit 2
fi

# no extrapolation
python interpolate_with_weights.py $rtofscur $rtofs_wghts $rtofs_rwps $varnames -1 &

wait;

python add_mesh_geom_to_file.py $rtofs_rwps $mesh
python add_mesh_geom_to_file.py $stofs_rwps $mesh

python interp_time.py $stofs_rwps $rtofs_rwps $stofs_rwps_ti $varnames False &

#interpolate from rtofs to common stofs and rtofs times within range of stofs time
#values out of range are extrapolated to assuming persistance
python interp_time.py $stofs_rwps $rtofs_rwps $rtofs_rwps_ti $varnames True &

wait

python add_err_var_to_file.py $rtofs_rwps_ti $rtofs_dists 100.:1.:50.:250.:50.
python add_err_var_to_file.py $stofs_rwps_ti $stofs_dists 1.:100.:50.:250.

python bayes_forecast_update.py $stofs_rwps_ti $rtofs_rwps_ti $rwps_current $varnames

