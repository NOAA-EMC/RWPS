#!/bin/bash

#script for retrieving stofs current and/or water level
#Comand line arguments are :
# arg 1 = YYYYMMDD
# arg 2 = cc, 2 digit cyle
# arg 3 = variable to retrieve, (current or waterlevel)
#
# Requires environmental variables:
# tmp = work directory to write output files to
# COMINstofs = directory path to stofs forecasts
#
# call as:
# $ sh get_rtofs_ice.sh

PDY=${1}
cyc=${2}

if [ "$#" -lt 3 ]; then
    echo "No arguments field argument."
    echo "Retrieving both stofs currents and stofs water level."
    fields="current, waterlevel"
else
    fields=${3}
fi

outdir=${DATA}/stofs.${PDY}.${cyc}

mkdir -p ${outdir}

if [[ "${fields}" == *"current"* ]]; then
    echo retrieving stofs current for ${PDY} cycle ${cyc}
    cp ${COMINstofs}/stofs_2d_glo.t"${cyc}"z.fields.cwl.vel.nc  ${outdir}/
fi

if [[ "${fields}" == *"level"* ]]; then
    echo retrieving stofs water level for ${PDY} cycle ${cyc}
    cp ${COMINstofs}/stofs_2d_glo.t"${cyc}"z.fields.cwl.nc  ${outdir}/
fi

