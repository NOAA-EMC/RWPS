#!/bin/sh
###############################################################################
# This script retrieves forecasts for water level for forecast date and cycle
# and processes the waterlevel forecasts for a particular RWPS mesh.
###############################################################################

cd ${DATA}
sh ${HOMErwps}/ush/preprocess/get_waterlevel.sh
sh ${HOMErwps}/ush/preprocess/process_waterlevel.sh
