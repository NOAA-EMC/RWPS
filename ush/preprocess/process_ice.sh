#!/bin/bash

# This script processes ice forecasts and prepares them for use with WW3 as pre-interpolated
# forcing (AI- already interpolated). Currently this script is configured to combine a 
# background forecast from rtofs global domain with the higher resolution nbm ak domain ice 
# forecast.

cd ${DATA}


inpdir=${DATA}/ice.${PDY}.${cyc}

nbmice=$inpdir/nbm.${PDY}.${cyc}.ice.ak.nc
rtofsice=$inpdir/rtofs.ice.${PDY}.nc

rtofs_wghts="${interpwghtsdir}/InterpolationWeights.${meshname}.rtofs.ice.nc"
rtofs_dists="${interpwghtsdir}/DistToBndy.${meshname}.rtofs.ice.nc"
nbm_ak_wghts="${interpwghtsdir}/InterpolationWeights.${meshname}.nbm.ak.nc"
nbm_ak_dists="${interpwghtsdir}/DistToBndy.${meshname}.nbm.ak.nc"

rtofs_rwps="${DATA}/${meshname}.${PDY}.ice.rtofs.nc"
rtofs_rwps_ti="${DATA}/${meshname}.${PDY}.${cyc}.ice.rtofs.ti.nc"

nbm_rwps="${DATA}/${meshname}.${PDY}.${cyc}.ice.nbm.ak.nc"
nbm_rwps_ti="${DATA}/${meshname}.${PDY}.${cyc}.ice.nbm.ak.ti.nc"

varnames="ICEC_surface"

rwps_ice="${frc}/${meshname}.${PDY}.${cyc}.ice.nc"

if [ ! -f "${nbm_ak_wghts}" ]; then
    echo "missing nbm ak interpolation weights file: ${nbm_ak_wghts}"
    echo "compute with script compute_unstr_to_rwps_interp_weights.sh"
    exit 1
fi

if [ ! -f "${nbm_ak_dists}" ]; then
    echo "missing nbm ak  distance to boundary file: ${nbm_ak_dists}"
    echo "compute with script compute_unstr_to_rwps_interp_weights.sh"
    exit 1
fi

# no extrapolation of ice beyond ak grid coverage
python ${USHrwps}/preprocess/interpolate_with_weights.py ${nbmice} ${nbm_ak_wghts} ${nbm_rwps} ${varnames} -1 &

if [ ! -f "${rtofs_wghts}" ]; then
    echo "missing rtofs interpolation weights file: ${rtofs_wghts}"
    echo "compute with script ComputeGridToRWPSInterpWeights.py"
    exit 2
fi
if [ ! -f "${rtofs_dists}" ]; then
    echo "missing stofs distance to boundary file: ${rtofs_dists}"
    echo "compute with script compute_unstr_to_rwps_interp_weights.py"
    exit 2
fi

# extrapolate with 0 as fill
python ${USHrwps}/preprocess/interpolate_with_weights.py ${rtofsice} ${rtofs_wghts} ${rtofs_rwps} ${varnames} 0 &

wait;


python ${USHrwps}/preprocess/add_mesh_geom_to_file.py ${rtofs_rwps} ${mesh}
python ${USHrwps}/preprocess/add_mesh_geom_to_file.py ${nbm_rwps} ${mesh}

# interpolate from stofs to common stofs and rtofs times within range of stofs time
python ${USHrwps}/preprocess/interp_time.py ${rtofs_rwps} ${nbm_rwps} ${rtofs_rwps_ti} ${varnames} False &

# interpolate from rtofs to common stofs and rtofs times within range of stofs time
# values out of range are extrapolated to assuming persistance
python ${USHrwps}/preprocess/interp_time.py ${rtofs_rwps} ${nbm_rwps} ${nbm_rwps_ti} ${varnames} True &

wait

#uniform variance of 100.
python ${USHrwps}/preprocess/add_err_var_to_file.py ${rtofs_rwps_ti} ${rtofs_dists} 100.

#interior variance of 4., boundary variance fof 400., transition lengthscale 9. km
python ${USHrwps}/preprocess/add_err_var_to_file.py ${nbm_rwps_ti} ${nbm_ak_dists} 4.:400.:9.

python ${USHrwps}/preprocess/bayes_forecast_update.py ${rtofs_rwps_ti} ${nbm_rwps_ti} ${rwps_ice} ${varnames}
