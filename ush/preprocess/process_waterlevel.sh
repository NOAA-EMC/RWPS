#!/bin/bash

# This script processes water level forecast from stofs prepares it for use with WW3 as 
# pre-interpolated forcing (AI- already interpolated).  

cd ${DATA}

stofslev="${DATA}/stofs.${PDY}.${cyc}/stofs_2d_glo.t${cyc}z.fields.cwl.nc"
stofs_wghts="${interpwghtsdir}/InterpolationWeights.${meshname}.stofs.nc"
stofs_dists="${interpwghtsdir}/DistToBndy.${meshname}.stofs.nc"
stofs_rwps="${frc}/${meshname}.${PDY}.${cyc}.cwl.waterlevel.nc"

rwps_waterlevel="${frc}/${meshname}.${PDY}.${cyc}.waterlevel.nc"

varnames="zeta"

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

python ${HOMErwps}/ush/preprocess/interpolate_with_weights.py ${stofslev} ${stofs_wghts} ${rwps_waterlevel} ${varnames} 0
python ${HOMErwps}/ush/preprocess/add_mesh_geom_to_file.py ${rwps_waterlevel} ${mesh}
python ${HOMErwps}/ush/preprocess/add_err_var_to_file.py ${rwps_waterlevel} ${stofs_dists} 1.
