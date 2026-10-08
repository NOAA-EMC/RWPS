#!/bin/sh
###############################################################################
# This script retrieves forecasts for ice for a particular forecast date and 
# cycle and processes the ice forecasts for a particular RWPS mesh.
###############################################################################

cd ${DATA}
${HOMErwps}/ush/preprocess/get_ice.sh
${HOMErwps}/ush/preprocess/process_ice.sh
