#!/bin/bash

# This script retrieves rrfs and nbm winbds and exports as 
# netcdf files

cd $HOMErwps/ush/preprocess

echo "retrieving winds from rrfs and nbm for rwps wind"
(
    echo "sh nbm/make_nbm_wind.sh $PDY $cyc oc > $tmp/nbm.oc.out"
    nbm/make_nbm_wind.sh $PDY $cyc oc > $tmp/nbm.oc.out
    echo "retrieved winds from nbm oc domain"
    echo "Not retrieving other nbm domain winds"
)&

(
    echo "sh rrfs/make_rrfs_wind.sh $PDY $cyc na > $tmp/rrfs.na.out"
    rrfs/make_rrfs_wind.sh $PDY $cyc na > $tmp/rrfs.na.out
    echo "retrieved winds from rrfs na domain"
)&

(
    echo "sh rrfs/make_rrfs_wind.sh $PDY $cyc ak > $tmp/rrfs.ak.out"
    rrfs/make_rrfs_wind.sh $PDY $cyc ak > $tmp/rrfs.ak.out
    echo "retrieved winds from rrfs ak domain"
)&

(
    echo "sh rrfs/make_rrfs_wind.sh $PDY $cyc pr > rrfs.pr.out"
    rrfs/make_rrfs_wind.sh $PDY $cyc pr > $tmp/rrfs.pr.out
    echo "retrieved winds from rrfs pr domain"
)&

(
    echo "sh rrfs/make_rrfs_wind.sh $PDY $cyc hi > rrfs.hi.out"
    rrfs/make_rrfs_wind.sh $PDY $cyc hi > $tmp/rrfs.hi.out
    echo "retrieved winds from rrfs hi domain"
)&

(
    echo "sh rrfs/make_rrfs_wind.sh $PDY $cyc conus > rrfs.conus.out"
    rrfs/make_rrfs_wind.sh $PDY $cyc conus > $tmp/rrfs.conus.out
    echo "retrieved winds from rrfs conus domain"
)&
wait

echo "finished retrieving winds from rrfs and nbm for rwps wind"

