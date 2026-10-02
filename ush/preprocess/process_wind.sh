#!/bin/bash

# This script processes wind forecasts and prepare them for use with WW3 as pre-interpolated
# forcing (AI- already interpolated).Currently configured to combine a backgrounbd forecast 
# from the nbm oc domain with higher resolution wind forecasts from the rrfs hi, pr, ak, na
# and conus domains in the forecast period when these are available.

cd ${DATA}

winddir="${DATA}/wind.${PDY}.${cyc}"
windvars="UGRD_10maboveground:VGRD_10maboveground"

# incorporate {meshname} date and cycle into output directory name to avoid
# applying winds to wrong mesh

outdir="${DATA}/rwps_wind.${meshname}.${PDY}.${cyc}"

rwps_wind="${frc}/${meshname}.${PDY}.${cyc}.wind.nc"

echo "outputing files to: ${outdir}"

nbm_oc="${winddir}/nbm.${PDY}.${cyc}.wind10m.oc.nc"
nbm_oc_uv="${winddir}/nbm.${PDY}.${cyc}.wind10m.oc.uv.nc"

rrfs_pr="${winddir}/rrfs.${PDY}.${cyc}.wind10m.pr.nc"
rrfs_hi="${winddir}/rrfs.${PDY}.${cyc}.wind10m.hi.nc"
rrfs_na="${winddir}/rrfs.${PDY}.${cyc}.wind10m.na.nc"
rrfs_ak="${winddir}/rrfs.${PDY}.${cyc}.wind10m.ak.nc"
rrfs_conus="${winddir}/rrfs.${PDY}.${cyc}.wind10m.conus.nc"

rwps_oc="${outdir}/${meshname}.${PDY}.${cyc}.wind10m.nbm.oc.nc"
rwps_oc_ti="${outdir}/${meshname}.${PDY}.${cyc}.wind10m.nbm.oc.ti.nc"
rwps_pr="${outdir}/${meshname}.${PDY}.${cyc}.wind10m.rrfs.pr.nc"
rwps_hi="${outdir}/${meshname}.${PDY}.${cyc}.wind10m.rrfs.hi.nc"
rwps_na="${outdir}/${meshname}.${PDY}.${cyc}.wind10m.rrfs.na.nc"
rwps_ak="${outdir}/${meshname}.${PDY}.${cyc}.wind10m.rrfs.ak.nc"
rwps_conus="${outdir}/${meshname}.${PDY}.${cyc}.wind10m.rrfs.conus.nc"


mkdir -p ${outdir}

##LocalFS  = [ rwps_pr, rwps_hi, rwps_ak, rwps_conus, rwps_na] # file names
##VarFS    = [ 4.     , 4.    , 9.      , 16.       , 25.    ] # (m m /s /s)
##LambdaFS = [ 150.   , 200.  , 500.    , 1000.     , 1500.  ] # (km)
nbm_oc_wghts="${interpwghtsdir}/InterpolationWeights.${meshname}.nbm.oc.nc"
rrfs_hi_wghts="${interpwghtsdir}/InterpolationWeights.${meshname}.rrfs.hi.nc"
rrfs_pr_wghts="${interpwghtsdir}/InterpolationWeights.${meshname}.rrfs.pr.nc"
rrfs_ak_wghts="${interpwghtsdir}/InterpolationWeights.${meshname}.rrfs.ak.nc"
rrfs_na_wghts="${interpwghtsdir}/InterpolationWeights.${meshname}.rrfs.na.nc"
rrfs_conus_wghts="${interpwghtsdir}/InterpolationWeights.${meshname}.rrfs.conus.nc"

nbm_oc_dist="${interpwghtsdir}/DistToBndy.${meshname}.nbm.oc.nc"
rrfs_hi_dist="${interpwghtsdir}/DistToBndy.${meshname}.rrfs.hi.nc"
rrfs_pr_dist="${interpwghtsdir}/DistToBndy.${meshname}.rrfs.pr.nc"
rrfs_ak_dist="${interpwghtsdir}/DistToBndy.${meshname}.rrfs.ak.nc"
rrfs_na_dist="${interpwghtsdir}/DistToBndy.${meshname}.rrfs.na.nc"
rrfs_conus_dist="${interpwghtsdir}/DistToBndy.${meshname}.rrfs.conus.nc"


(
    #Convert NBM speed and direction to u,v
    python ${USHrwps}/preprocess/spd_dir_to_uv_nbm.py ${nbm_oc} ${nbm_oc_uv}
    python ${USHrwps}/preprocess/interpolate_with_weights.py ${nbm_oc_uv} ${nbm_oc_wghts} ${rwps_oc} ${windvars} 3
    python ${USHrwps}/preprocess/add_mesh_geom_to_file.py ${rwps_oc} ${mesh}
)&

(
    python ${USHrwps}/preprocess/interpolate_with_weights.py ${rrfs_hi} ${rrfs_hi_wghts} ${rwps_hi} ${windvars} -1
    #add mesh geometry into interpolated file
    python ${USHrwps}/preprocess/add_mesh_geom_to_file.py ${rwps_hi} ${mesh}
    # Add error covariance field to files with interpolated fields for bayesian update
    # Based on distance to boundary of input field and commant line parameters InternalVariance:BoundaryVariance:LengthScale(km) 
    python ${USHrwps}/preprocess/add_err_var_to_file.py ${rwps_hi} ${rrfs_hi_dist} 4.:40.:200.
)&

(
    python ${USHrwps}/preprocess/interpolate_with_weights.py ${rrfs_pr} ${rrfs_pr_wghts} ${rwps_pr} ${windvars} -1
    python ${USHrwps}/preprocess/add_mesh_geom_to_file.py ${rwps_pr} ${mesh}
    python ${USHrwps}/preprocess/add_err_var_to_file.py ${rwps_pr} ${rrfs_pr_dist} 4.:40.:150.
)&

(
    python ${USHrwps}/preprocess/interpolate_with_weights.py ${rrfs_ak} ${rrfs_ak_wghts} ${rwps_ak} ${windvars} -1
    python ${USHrwps}/preprocess/add_mesh_geom_to_file.py ${rwps_ak} ${mesh}
    python ${USHrwps}/preprocess/add_err_var_to_file.py ${rwps_ak} ${rrfs_ak_dist} 9.:90.:500.
)&

(
    python ${USHrwps}/preprocess/interpolate_with_weights.py ${rrfs_conus} ${rrfs_conus_wghts} ${rwps_conus} ${windvars} -1
    python ${USHrwps}/preprocess/add_mesh_geom_to_file.py ${rwps_conus} ${mesh}
    python ${USHrwps}/preprocess/add_err_var_to_file.py ${rwps_conus} ${rrfs_conus_dist} 16.:160.:1000.
)&

(
    python ${USHrwps}/preprocess/interpolate_with_weights.py ${rrfs_na} ${rrfs_na_wghts} ${rwps_na} ${windvars} -1
    python ${USHrwps}/preprocess/add_mesh_geom_to_file.py ${rwps_na} ${mesh}
    python ${USHrwps}/preprocess/add_err_var_to_file.py ${rwps_na} ${rrfs_na_dist} 50.:500.:1500.
)&

wait;

#Interpolate NBM in time to times within the NBM forecast covered by the RRFS forecast
python ${USHrwps}/preprocess/interp_time.py ${rwps_oc} ${rwps_pr} ${rwps_oc_ti} ${windvars}
#add mesh geometry into file
python ${USHrwps}/preprocess/add_mesh_geom_to_file.py ${rwps_oc_ti} ${mesh}
#add prescribed error covariance for nbm oc domain (assumed constant 100. (m/s)^2 )
python ${USHrwps}/preprocess/add_err_var_to_file.py ${rwps_oc_ti} ${nbm_oc_dist} 100.

cp $rwps_oc_ti ${rwps_wind}
[ ! -f "${rwps_hi}" ] && python ${USHrwps}/preprocess/bayes_forecast_update.py ${rwps_wind} ${rwps_hi} ${rwps_wind} ${windvars}
[ ! -f "${rwps_pr}" ] && python ${USHrwps}/preprocess/bayes_forecast_update.py ${rwps_wind} ${rwps_pr} ${rwps_wind} ${windvars}
[ ! -f "${rwps_ak}" ] && python ${USHrwps}/preprocess/bayes_forecast_update.py ${rwps_wind} ${rwps_ak} ${rwps_wind} ${windvars}
[ ! -f "${rwps_conus}" ] && python ${USHrwps}/preprocess/bayes_forecast_update.py ${rwps_wind} ${rwps_conus} ${rwps_wind} ${windvars}
[ ! -f "${rwps_na}" ] && python ${USHrwps}/preprocess/bayes_forecast_update.py ${rwps_wind} ${rwps_na} ${rwps_wind} ${windvars}
