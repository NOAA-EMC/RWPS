#!/bin/sh
###############################################################################
# This script retrieves forecasts for wind for forecast date and cycle
# and processes the wind forecasts for a particular RWPS mesh.
###############################################################################
set -x

cd ${DATA}

# retrieve rrfs and nbm wind forecasts and exports as netcdf files
echo "retrieving winds from rrfs and nbm for rwps wind"
    
###############################################################################
# (A)
${USHrwps}/preprocess/nbm/make_nbm_wind.sh ${PDY} ${cyc} oc
export err=$?; err_chk
echo "retrieved winds from nbm oc domain"
echo "Not retrieving other nbm domain winds"
###############################################################################

###############################################################################
# (B)
${USHrwps}/preprocess/rrfs/make_rrfs_wind.sh ${PDY} ${cyc} na
export err=$?; err_chk
echo "retrieved winds from rrfs na domain"
###############################################################################

###############################################################################
# (C)
${USHrwps}/preprocess/rrfs/make_rrfs_wind.sh ${PDY} ${cyc} ak
export err=$?; err_chk
echo "retrieved winds from rrfs ak domain"
###############################################################################

###############################################################################
# (D)
${USHrwps}/preprocess/rrfs/make_rrfs_wind.sh ${PDY} ${cyc} pr
export err=$?; err_chk
echo "retrieved winds from rrfs pr domain"
###############################################################################

###############################################################################
# (E)
${USHrwps}/preprocess/rrfs/make_rrfs_wind.sh ${PDY} ${cyc} hi
export err=$?; err_chk
echo "retrieved winds from rrfs hi domain"
###############################################################################

###############################################################################
# (F)
${USHrwps}/preprocess/rrfs/make_rrfs_wind.sh ${PDY} ${cyc} conus
export err=$?; err_chk
echo "retrieved winds from rrfs conus domain"
###############################################################################

# Sections (A) through (F) can be executed in parallel but must all compleate 
# before running section (G)
    
###############################################################################
# (G)
echo "finished retrieving winds from rrfs and nbm for rwps wind"

${HOMErwps}/ush/preprocess/process_wind.sh
export err=$?; err_chk
###############################################################################

msg="JOB $job HAS COMPLETED NORMALLY."
postmsg "$msg"

#move forcing files from $DATA to COM
mkdir -p ${COMROOT}
cp ${DATA}/${NET}.${meshID}.${PDY}.${cyc}.wind.nc $COMROOT/${NET}.t${cyc}z.${meshID}.wind.nc
