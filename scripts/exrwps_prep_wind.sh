#!/bin/sh
###############################################################################
# This script retrieves forecasts for wind for forecast date and cycle
# and processes the wind forecasts for a particular RWPS mesh.
###############################################################################
set -x

cd ${DATA}

# retrieve rrfs and nbm wind forecasts and exports as netcdf files
echo "retrieving winds from rrfs and nbm for rwps wind"
(
    ${USHrwps}/preprocess/nbm/make_nbm_wind.sh ${PDY} ${cyc} oc
    export err=$?; err_chk
    echo "retrieved winds from nbm oc domain"
    echo "Not retrieving other nbm domain winds"
)&

(
    ${USHrwps}/preprocess/rrfs/make_rrfs_wind.sh ${PDY} ${cyc} na
    export err=$?; err_chk
    echo "retrieved winds from rrfs na domain"
)&

(
    ${USHrwps}/preprocess/rrfs/make_rrfs_wind.sh ${PDY} ${cyc} ak
    export err=$?; err_chk
    echo "retrieved winds from rrfs ak domain"
)&

(
    ${USHrwps}/preprocess/rrfs/make_rrfs_wind.sh ${PDY} ${cyc} pr
    export err=$?; err_chk
    echo "retrieved winds from rrfs pr domain"
)&

(
    ${USHrwps}/preprocess/rrfs/make_rrfs_wind.sh ${PDY} ${cyc} hi
    export err=$?; err_chk
    echo "retrieved winds from rrfs hi domain"
)&

(
    ${USHrwps}/preprocess/rrfs/make_rrfs_wind.sh ${PDY} ${cyc} conus
    export err=$?; err_chk
    echo "retrieved winds from rrfs conus domain"
)&

wait;

echo "finished retrieving winds from rrfs and nbm for rwps wind"

${HOMErwps}/ush/preprocess/process_wind.sh
export err=$?; err_chk
