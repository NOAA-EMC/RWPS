#!/bin/bash

# Program Name: proccess_winds.sh
# Author(s)/Contact(s): Keston Smith (keston.smith@noaa.gov)
#
# Abstract: 
# This script processes wind forecasts and prepare them for use with WW3 as pre-interpolated
# forcing (AI- already interpolated).Currently configured to combine a backgrounbd forecast 
# from the nbm oc domain with higher resolution wind forecasts from the rrfs hi, pr, ak, na
# and conus domains in the forecast period when these are available.
# History Log:
#
# Usage:
#  Parameters: 
#    
#  Input Files: (as variable names, see script for expected location)
#    nbm_oc        nbm forecast winds for oceanic (oc) domain
#    nbm_wghts     interpolation weights to interpolate from nbm oc grid to RWPS unstructured mesh
#    nbm_dists     distance to boundary of nbm oc interpolation envelope for RWPS mesh
#    (for XX="hi,"pr","ak","conus", "na")
#    rrfs_XX       rrfs forecast winds for domain XX 
#    rrfs_XX_wghts interpolation weights to interpolate from rrfs XX grid to RWPS unstructured mesh
#    rrfs_XX_dists distance to boundary of rrfs XX interpolation envelope for RWPS mesh
#
#  Output File:
#    rwps_wind     RWPS wind forcing
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
#    1 missing nbm oc forecast file
#    2 missing nbm oc interpolation weights file for RWPS mesh
#
# User controllable options:
#    Error variance parameter specification for each forecast domain, defined by [interior error variance(m/s)]:[boundary error variance(m/s)]:[transition lengscale(km)] 

set -x

winddir="${DATA}/wind.${PDY}.${cyc}"
windvars="UGRD_10maboveground:VGRD_10maboveground"

# incorporate {meshname} date and cycle into output directory name to avoid
# applying winds to wrong mesh

outdir="${DATA}/rwps_wind.${meshname}.${PDY}.${cyc}"

rwps_wind="${DATA}/${meshname}.${PDY}.${cyc}.wind.nc"

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

# Tested paramater values for bayesian update
# LocalFS  = [ rwps_pr, rwps_hi, rwps_ak, rwps_conus, rwps_na, nbm_oc] # file names
# VarFS    = [ 4.     , 4.    , 9.      , 16.       , 25.    , 100.  ] # (m m /s /s)
# LambdaFS = [ 150.   , 200.  , 500.    , 1000.     , 1500.  , inf   ] # (km)

nbm_oc_wghts="${FIXrwps}/${meshID}/InterpolationWeights.${meshname}.nbm.oc.nc"
rrfs_hi_wghts="${FIXrwps}/${meshID}/InterpolationWeights.${meshname}.rrfs.hi.nc"
rrfs_pr_wghts="${FIXrwps}/${meshID}/InterpolationWeights.${meshname}.rrfs.pr.nc"
rrfs_ak_wghts="${FIXrwps}/${meshID}/InterpolationWeights.${meshname}.rrfs.ak.nc"
rrfs_na_wghts="${FIXrwps}/${meshID}/InterpolationWeights.${meshname}.rrfs.na.nc"
rrfs_conus_wghts="${FIXrwps}/${meshID}/InterpolationWeights.${meshname}.rrfs.conus.nc"

nbm_oc_dist="${FIXrwps}/${meshID}/DistToBndy.${meshname}.nbm.oc.nc"
rrfs_hi_dist="${FIXrwps}/${meshID}/DistToBndy.${meshname}.rrfs.hi.nc"
rrfs_pr_dist="${FIXrwps}/${meshID}/DistToBndy.${meshname}.rrfs.pr.nc"
rrfs_ak_dist="${FIXrwps}/${meshID}/DistToBndy.${meshname}.rrfs.ak.nc"
rrfs_na_dist="${FIXrwps}/${meshID}/DistToBndy.${meshname}.rrfs.na.nc"
rrfs_conus_dist="${FIXrwps}/${meshID}/DistToBndy.${meshname}.rrfs.conus.nc"

###############################################################################
# (A)
if [ -f "${nbm_oc}" ] && [ -f "${nbm_oc_wghts}" ] ; then
    #Convert nbm speed and direction to u,v
    python ${USHrwps}/preprocess/spd_dir_to_uv_nbm.py ${nbm_oc} ${nbm_oc_uv}
    export err=$?; err_chk                 # error checking
    #interpolate nbm oc domain winds to rwps mesh
    python ${USHrwps}/preprocess/interpolate_with_weights.py ${nbm_oc_uv} ${nbm_oc_wghts} ${rwps_oc} ${windvars} 3
    export err=$?; err_chk                 # error checking
    #add mesh geometry into interpolated file
    python ${USHrwps}/preprocess/add_mesh_geom_to_file.py ${rwps_oc} ${mesh}
    export err=$?; err_chk                 # error checking
else
    if [ ! -f "${nbm_oc}" ];then
       msg = "FATAL ERROR: missing nbm oc domain forecast file ${nbm_oc}"
       echo "$msg"
       postmsg "$msg"      
       err=1;export err;err_chk
       exit $err
    fi
    if [ ! -f "${nbm_oc_wghts}" ];then
        msg = "FATAL ERROR: missing nbm oc interpolation weights file ${nbm_oc_wghts}"
        echo "$msg"
        postmsg "$msg"      
        err=2;export err;err_chk
        exit $err
    fi
fi
###############################################################################

###############################################################################
# (B)
#interpolate rrfs hi domain winds to rwps mesh
python ${USHrwps}/preprocess/interpolate_with_weights.py ${rrfs_hi} ${rrfs_hi_wghts} ${rwps_hi} ${windvars} -1
#add mesh geometry into interpolated file
python ${USHrwps}/preprocess/add_mesh_geom_to_file.py ${rwps_hi} ${mesh}
# Add error covariance field to files with interpolated fields for bayesian update
# Based on distance to boundary of input field and commant line parameters InternalVariance:BoundaryVariance:LengthScale(km) 
python ${USHrwps}/preprocess/add_err_var_to_file.py ${rwps_hi} ${rrfs_hi_dist} 4.:40.:200.
err=$?                 # if err not =0  then script failed to process rrfs hi domain
if [$err != 0 ]; then
    msg="WARNING: Failed to process rrfs forecast for domain hi, proceeding with nbm wind for this region" 
    echo "$msg"
    postmsg "$msg"      
fi
###############################################################################

###############################################################################
# (C)
python ${USHrwps}/preprocess/interpolate_with_weights.py ${rrfs_pr} ${rrfs_pr_wghts} ${rwps_pr} ${windvars} -1
python ${USHrwps}/preprocess/add_mesh_geom_to_file.py ${rwps_pr} ${mesh}
python ${USHrwps}/preprocess/add_err_var_to_file.py ${rwps_pr} ${rrfs_pr_dist} 4.:40.:150.
err=$?                 # Failed to process rrfs hi domain
if [$err != 0 ]; then
    msg="WARNING: Failed to process rrfs forecast for domain pr, proceeding with nbm wind for this region" 
    echo "$msg"
    postmsg "$msg"      
fi
###############################################################################

###############################################################################
# (D)
python ${USHrwps}/preprocess/interpolate_with_weights.py ${rrfs_ak} ${rrfs_ak_wghts} ${rwps_ak} ${windvars} -1
python ${USHrwps}/preprocess/add_mesh_geom_to_file.py ${rwps_ak} ${mesh}
python ${USHrwps}/preprocess/add_err_var_to_file.py ${rwps_ak} ${rrfs_ak_dist} 9.:90.:500.
err=$?                 
if [$err != 0 ]; then
    msg="WARNING: Failed to process rrfs forecast for domain ak, proceeding with nbm wind for this region" 
    echo "$msg"
    postmsg "$msg"      
fi
###############################################################################

###############################################################################
# (E)
python ${USHrwps}/preprocess/interpolate_with_weights.py ${rrfs_conus} ${rrfs_conus_wghts} ${rwps_conus} ${windvars} -1
python ${USHrwps}/preprocess/add_mesh_geom_to_file.py ${rwps_conus} ${mesh}
python ${USHrwps}/preprocess/add_err_var_to_file.py ${rwps_conus} ${rrfs_conus_dist} 16.:160.:1000.
err=$?
if [$err != 0 ]; then
    msg="WARNING: Failed to process rrfs forecast for domain conus, proceeding with nbm wind for this region" 
    echo "$msg"
    postmsg "$msg"      
fi
###############################################################################

###############################################################################
# (F)
python ${USHrwps}/preprocess/interpolate_with_weights.py ${rrfs_na} ${rrfs_na_wghts} ${rwps_na} ${windvars} -1
python ${USHrwps}/preprocess/add_mesh_geom_to_file.py ${rwps_na} ${mesh}
python ${USHrwps}/preprocess/add_err_var_to_file.py ${rwps_na} ${rrfs_na_dist} 50.:500.:1500.
err=$?
if [$err != 0 ]; then
    msg="WARNING: Failed to process rrfs forecast for domain na, proceeding with nbm wind for this region" 
    echo "$msg"
    postmsg "$msg"      
fi
###############################################################################

# Sections (A) through (F) can be executed in parallel but must both compleate 
# before running section (G)

###############################################################################
# (G)
if [ -f ${rwps_na} ]; then # this should be any of the rwps_(rrfs_domain) files that exist
    #Interpolate NBM in time to times within the NBM forecast covered by the RRFS forecast
    python ${USHrwps}/preprocess/interp_time.py ${rwps_oc} ${rwps_na} ${rwps_oc_ti} ${windvars}
    export err=$?; err_chk                 # error checking
else
    # if rrfs forecast is missing just use nbm times and proceed
    cp ${rwps_oc} ${rwps_oc_ti}
fi
#add mesh geometry into file
python ${USHrwps}/preprocess/add_mesh_geom_to_file.py ${rwps_oc_ti} ${mesh}
export err=$?; err_chk                 # error checking
#add prescribed error covariance for nbm oc domain (assumed constant 100. (m/s)^2 )
python ${USHrwps}/preprocess/add_err_var_to_file.py ${rwps_oc_ti} ${nbm_oc_dist} 100.
export err=$?; err_chk                 # error checking

cp $rwps_oc_ti ${rwps_wind}
# apply bayesian update to nbm oc winds based on available rrfs wind forecasts for domains 
# hi, pr, ak, conus, and na
if [ -f ${rwps_hi} ]; then
    echo "incorporating hi winds"
    python ${USHrwps}/preprocess/bayes_forecast_update.py ${rwps_wind} ${rwps_hi} tmp_wind.nc ${windvars}
    export err=$?; err_chk                 # error checking
    mv tmp_wind.nc ${rwps_wind}
else
    echo "WARNING: no local rrfs forecast available for hi domain. missing ${rwps_hi}"
fi

if [ -f ${rwps_pr} ]; then
    echo "incorporating pr winds"
    python ${USHrwps}/preprocess/bayes_forecast_update.py ${rwps_wind} ${rwps_pr} tmp_wind.nc ${windvars}
    export err=$?; err_chk                 # error checking
    mv tmp_wind.nc ${rwps_wind}
else
    echo "WARNING: no local rrfs forecast available for pr domain. missing ${rwps_pr}"
fi

if [ -f ${rwps_ak} ]; then
    echo "incorporating ak winds"
    python ${USHrwps}/preprocess/bayes_forecast_update.py ${rwps_wind} ${rwps_ak} tmp_wind.nc ${windvars}
    export err=$?; err_chk                 # error checking
    mv tmp_wind.nc ${rwps_wind}
else
    echo "WARNING: no local rrfs forecast available for ak domain. missing ${rwps_ak}"
fi

if [ -f ${rwps_conus} ]; then
    echo "incorporating conus winds"
    python ${USHrwps}/preprocess/bayes_forecast_update.py ${rwps_wind} ${rwps_conus} tmp_wind.nc ${windvars}
    export err=$?; err_chk                 # error checking
    mv tmp_wind.nc ${rwps_wind}
else
    echo "WARNING: no local rrfs forecast available for conus domain. missing ${rwps_conus}"
fi

if [ -f ${rwps_na} ]; then
    echo "incorporating na winds"
    python ${USHrwps}/preprocess/bayes_forecast_update.py ${rwps_wind} ${rwps_na} tmp_wind.nc ${windvars}
    export err=$?; err_chk                 # error checking
    mv tmp_wind.nc ${rwps_wind}
else
    echo "WARNING: no local rrfs forecast available for na domain. missing ${rwps_na}"
fi
###############################################################################

