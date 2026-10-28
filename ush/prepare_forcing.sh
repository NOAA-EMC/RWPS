#!/bin/bash

# --------------------------------------------------------------------------- #
#                                                                             #
# Launches scripts to retrieve and process wind, currents, ice, and           #
# waterlevel for an rwps forecast. Command line inputs are date cyc and       # 
# meshID. For example, run:                                                   #
#                                                                             #
# $sh prepare_forcing 20260904 00 oc_500m_10km                                #
#                                                                             #  
# to generate forcing for mesh rwps.oc_500m_10km.msh                          #
#                                                                             #
# Last Changed : 09-04-2026                                        Sep 2026   #
# --------------------------------------------------------------------------- #


echo ' Start of prepare_forcing.sh at: '
date

set -x
# Use LOUD variable to turn on/off trace.  Defaults to YES (on).
export LOUD=${LOUD:-YES}; [[ $LOUD = yes ]] && export LOUD=YES
[[ "$LOUD" != YES ]] && set +x

export PDY=${1}
export cyc=${2}
export meshID=${3}

export KEEPDATA="NO"

# presently defined here for ecf job submit
readonly HOMErwps=$(cd "$(dirname "$(readlink -f -n "${BASH_SOURCE[0]}")")" && git rev-parse --show-toplevel)
export HOMErwps

source ${HOMErwps}/ush/detect_machine.sh
source ${HOMErwps}/versions/run.${MACHINE_ID}.ver

##################################
export mesh="${HOMErwps}/fix/${meshID}/rwps.${meshID}.msh"
meshname="${mesh##*/}"
export meshname="${meshname: 0: -4}"
##################################

# TODO: OPSROOT=/lfs/$FS/ops/$envir
export OPSROOT=/lfs/h2/emc/ptmp/${USER}/rwps/${rwps_ver}/JRWPS_PREP

# set DATA and create path for ecf output files
export COMROOT=${OPSROOT}/com/rwps/${rwps_ver}/rwps.${PDY}/${cyc}/prep

export DATAROOT=${OPSROOT}/tmp
export DATA=${DATAROOT}/${jobid}
mkdir -p ${DATA}
mkdir -p ${COMROOT}


#Retrieve current and process for forecast cycle
qsub -V -o ${COMROOT}/prep_current.${PDY}.${cyc}.${meshID}.out ${HOMErwps}/ecf/jrwps_prep_current.ecf
qsub -V -o ${COMROOT}/prep_ice.${PDY}.${cyc}.${meshID}.out ${HOMErwps}/ecf/jrwps_prep_ice.ecf
qsub -V -o ${COMROOT}/prep_waterlevel.${PDY}.${cyc}.${meshID}.out ${HOMErwps}/ecf/jrwps_prep_waterlevel.ecf
qsub -V -o ${COMROOT}/prep_wind.${PDY}.${cyc}.${meshID}.out ${HOMErwps}/ecf/jrwps_prep_wind.ecf

set +x
echo ' '
echo 'End of prepare_forcing.sh at'
date
