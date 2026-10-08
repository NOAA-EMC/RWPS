#!/bin/sh
###############################################################################
# This script retrieves forecasts for wind for forecast date and cycle
# and processes the wind forecasts for a particular RWPS mesh.
###############################################################################

cd ${DATA}
${HOMErwps}/ush/preprocess/get_wind.sh
${HOMErwps}/ush/preprocess/process_wind.sh
