#!/bin/sh
###############################################################################
# This script retrieves forecasts for current for a forecast date and cycle
# and processes the current forecasts for a particular RWPS mesh.
###############################################################################

cd ${DATA}
sh ${HOMErwps}/ush/preprocess/get_current.sh
sh ${HOMErwps}/ush/preprocess/process_current.sh
