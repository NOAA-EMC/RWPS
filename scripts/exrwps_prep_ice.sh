#!/bin/sh
###############################################################################
# This script retrieves forecasts for ice for a particular forecast date and 
# cycle and processes the ice forecasts for a particular RWPS mesh.
###############################################################################

cd ${DATA}
sh ${HOMErwps}/ush/preprocess/get_ice.sh
sh ${HOMErwps}/ush/preprocess/process_ice.sh
