#!/bin/bash

#script for retrieving stofs current and/or water level

if [ "$#" -lt 3 ]; then
    echo "No arguments field argument."
    echo "Retrieving both stofs currents and stofs water level."
    fields="current, waterlevel"
else
    fields=$3
fi

outdir=$tmp/stofs.$PDY.$cyc

mkdir -p $outdir

if [[ "$fields" == *"current"* ]]; then
    echo retrieving stofs current for $PDY cycle $cyc
    cp $COMINstofs/stofs_2d_glo.t"$cyc"z.fields.cwl.vel.nc  $outdir/
fi

if [[ "$fields" == *"level"* ]]; then
    echo retrieving stofs water level for $PDY cycle $cyc
    cp $COMINstofs/stofs_2d_glo.t"$cyc"z.fields.cwl.nc  $outdir/
fi

