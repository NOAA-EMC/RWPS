#!/bin/bash

# This script takes rrfs grib2 forecast files, extracts 10m u and v wind
# components and outputs to netcdf. Comand line arguments are

WSPD_FILE="$COMINnbm/blend.t$2z.wspd.$3.grib2" 
WDIR_FILE="$COMINnbm/blend.t$2z.wdir.$3.grib2"

OUTPUT_DIR="wind.$1.$2"
OUTPUT_DIR="$COMINlocal/wind.$1.$2"
OUTPUT_FILE="$OUTPUT_DIR/nbm.$1.$2.wind10m.$3.nc"

mkdir -p "$OUTPUT_DIR"

# Remove existing output file to avoid mixing old data
rm -f "$OUTPUT_FILE"

echo "writing 10m wind from $INPUT_DIR to $OUTPUT_FILE"

wgrib2 "$WSPD_FILE"  -match ":WIND:10 m" -netcdf "$OUTPUT_FILE"
wgrib2 "$WDIR_FILE"  -match ":WDIR:10 m" -append -netcdf "$OUTPUT_FILE"

echo "nbm processing complete for forecast date $1, cycle $2, domain $3"
echo "output written to: $OUTPUT_FILE"

