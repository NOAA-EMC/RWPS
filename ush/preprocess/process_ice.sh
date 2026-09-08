#!/bin/bash

cd $HOMErwps/ush/preprocess

meshname="${mesh##*/}"
meshname="${meshname: 0: -4}"


inpdir=$tmp/ice.$PDY.$cyc

nbmice=$inpdir/nbm.$PDY.$cyc.ice.ak.nc
rtofsice=$inpdir/rtofs.ice.$PDY.nc


rtofs_wghts="$fix/InterpolationWeights.$meshname.rtofs.ice.nc"
rtofs_dists="$fix/DistToBndy.$meshname.rtofs.ice.nc"
nbm_ak_wghts="$fix/InterpolationWeights.$meshname.nbm.ak.nc"
nbm_ak_dists="$fix/DistToBndy.$meshname.nbm.ak.nc"

rtofs_rwps="$tmp/$meshname.$PDY.ice.rtofs.nc"
rtofs_rwps_ti="$tmp/$meshname.$PDY.$cyc.ice.rtofs.ti.nc"

nbm_rwps="$tmp/$meshname.$PDY.$cyc.ice.nbm.ak.nc"
nbm_rwps_ti="$tmp/$meshname.$PDY.$cyc.ice.nbm.ak.ti.nc"

varnames="ICEC_surface"

#rwps_ice="$frc/$meshname.$PDY.$cyc.ice.rtofsxnbm.nc"
rwps_ice="$frc/$meshname.$PDY.$cyc.ice.nc"

## NBM AK domain interpolation
## NOTE WE ARE USING THE RRFS ak WEIGHTS HERE NEED TO RELABEL AND RECOMPUTE FOR NBM AK DOMAIN
## DIFFERENCES ARE SMALL. posional distance ~200m on 3km grid roughly

#../../fix/DistToBndy.rwps.oc_1500m_30km.nbm.ak.nc


if [ ! -f "$nbm_ak_wghts" ]; then
    echo "missing nbm ak interpolation weights file: $nbm_ak_wghts"
    echo "compute with script compute_unstr_to_rwps_interp_weights.sh"
    exit 1
fi

if [ ! -f "$nbm_ak_dists" ]; then
    echo "missing nbm ak  distance to boundary file: $nbm_ak_dists"
    echo "compute with script compute_unstr_to_rwps_interp_weights.sh"
    exit 1
fi

# no extrapolation
python interpolate_with_weights.py $nbmice $nbm_ak_wghts $nbm_rwps $varnames -1 &

## RTOFS interpolation

if [ ! -f "$rtofs_wghts" ]; then
    echo "missing rtofs interpolation weights file: $rtofs_wghts"
    echo "compute with script ComputeGridToRWPSInterpWeights.py"
    exit 2
fi
if [ ! -f "$rtofs_dists" ]; then
    echo "missing stofs distance to boundary file: $rtofs_dists"
    echo "compute with script compute_unstr_to_rwps_interp_weights.py"
    exit 2
fi

# extrapolate with 0 as fill
echo "$rtofsice"
python interpolate_with_weights.py $rtofsice $rtofs_wghts $rtofs_rwps $varnames 0 &

wait;

python add_mesh_geom_to_file.py $rtofs_rwps $mesh
python add_mesh_geom_to_file.py $nbm_rwps $mesh

#python add_err_var_to_file.py $rtofs_rwps $rtofs_dists 100.:1.:50.:250.:50.
#python add_err_var_to_file.py $stofs_rwps $stofs_dists 1.:100.:50.:250.

#interpolate from stofs to common stofs and rtofs times within range of stofs time
python interp_time.py $rtofs_rwps $nbm_rwps $rtofs_rwps_ti $varnames False &

#interpolate from rtofs to common stofs and rtofs times within range of stofs time
#values out of range are extrapolated to assuming persistance
python interp_time.py $rtofs_rwps $nbm_rwps $nbm_rwps_ti $varnames True &

wait

#uniform variance of 100.
python add_err_var_to_file.py $rtofs_rwps_ti $rtofs_dists 100.

#interior variance of 4., boundary variance fof 400., transition lengthscale 9. km
python add_err_var_to_file.py $nbm_rwps_ti $nbm_ak_dists 4.:400.:9.

python bayes_forecast_update.py $rtofs_rwps_ti $nbm_rwps_ti $rwps_ice $varnames
