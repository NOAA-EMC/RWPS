#!/bin/bash

# Script to retrieve nbm ice forecast and convert to netcdf using wgrib2. 
# Script takes two command line arguments :
# arg 1 = YYYYMMDD
# arg 2 = 2 digit cyle
#
# Requires environmental variables:
# tmp = work directory to write output files to
#
# call as:
# $ sh get_nbm_ice.sh 20260829 00

ICE_FILE=${COMINnbm}/blend.t${2}z.icec.ak.grib2

OUTPUT_DIR=${DATA}/ice.${1}.${2}
OUTPUT_FILE=${OUTPUT_DIR}/nbm.${1}.${2}.ice.ak.nc

mkdir -p ${OUTPUT_DIR}
# Remove existing output file to avoid mixing old data
rm -f ${OUTPUT_FILE}

echo "writing ice from ${INPUT_DIR} to ${OUTPUT_FILE}"

wgrib2 "${ICE_FILE}"  -match ":ICEC:" -netcdf "${OUTPUT_FILE}"

echo "nbm ice processing complete for forecast date ${1}, cycle ${2}, domain ak"
echo "output written to: ${OUTPUT_FILE}"
