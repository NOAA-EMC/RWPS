#!/bin/bash

# This script retrieves rrfs and nbm winbds and exports as 
# netcdf files
# PDY=YYYYMMDD, 
# cyc=00,06... two digit cycle number

cd ${DATA}

echo "retrieving winds from rrfs and nbm for rwps wind"
(
    ${USHrwps}/preprocess/nbm/make_nbm_wind.sh ${PDY} ${cyc} oc
    echo "retrieved winds from nbm oc domain"
    echo "Not retrieving other nbm domain winds"
)&

(
    ${USHrwps}/preprocess/rrfs/make_rrfs_wind.sh ${PDY} ${cyc} na
    echo "retrieved winds from rrfs na domain"
)&

(
    ${USHrwps}/preprocess/rrfs/make_rrfs_wind.sh ${PDY} ${cyc} ak
    echo "retrieved winds from rrfs ak domain"
)&

(
    ${USHrwps}/preprocess/rrfs/make_rrfs_wind.sh ${PDY} ${cyc} pr
    echo "retrieved winds from rrfs pr domain"
)&

(
    ${USHrwps}/preprocess/rrfs/make_rrfs_wind.sh ${PDY} ${cyc} hi
    echo "retrieved winds from rrfs hi domain"
)&

(
    ${USHrwps}/preprocess/rrfs/make_rrfs_wind.sh ${PDY} ${cyc} conus
    echo "retrieved winds from rrfs conus domain"
)&
wait

echo "finished retrieving winds from rrfs and nbm for rwps wind"

