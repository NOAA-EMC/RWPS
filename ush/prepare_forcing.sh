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


export PDY=$1
export cyc=$2
export meshID=$3

readonly HOMErwps=$(cd "$(dirname "$(readlink -f -n "${BASH_SOURCE[0]}")")" && git rev-parse --show-toplevel)
cd "${HOMErwps}/ush" || exit 1

source "${HOMErwps}/ush/detect_machine.sh"
source "${HOMErwps}/ush/module-setup.sh"
#source "${HOMErwps}/versions/build.ver"


export MACHINE_ID
export HOMErwps

if [[ -z "${MACHINE_ID}" ]]; then
    echo "FATAL: Unable to determine target machine"
    exit 1
fi

# link mesh corresponding to meshID to local fix directory
${HOMErwps}/sorc/link_workflow.sh
export mesh="${HOMErwps}/fix/${meshID}/rwps.${meshID}.msh"

#This should be defined somewhere else
usrtmp="/lfs/h2/emc/ptmp/$USER/"
mkdir -p ${usrtmp}

export fix="${HOMErwps}/fix"
export DATA="${usrtmp}/RWPSdata.${PDY}.${cyc}.${meshID}"
export tmp="${DATA}/tmpfiles"
export frc="${DATA}/forcing"
export interpwghtsdir="${HOMErwps}/interpolation_weights"


export outdir=${DATA}

mkdir -p ${DATA}
mkdir -p ${tmp}
mkdir -p ${frc}

#machine dependend path to rtofs, nbm, rrfs, and stofs forecast files
export COMINrtofs="/lfs/h1/ops/prod/com/rtofs/v2.5/rtofs.${PDY}/"
export COMINnbm="/lfs/h3/mdl/ptmp/mdl.nbm/blend/v5.2/blend.${PDY}/${cyc}/grib2"
export COMINrrfs="/lfs/h1/ops/prod/com/rrfs/v1.0/rrfs.${PDY}/${cyc}"
export COMINstofs="/lfs/h1/ops/prod/com/stofs/v3.1/stofs_2d_glo.${PDY}"

#machine dependend path to RWPS fix files
export RWPSfix=/lfs/h2/emc/couple/noscrub/keston.smith/RWPS

cd ${DATA}

mkdir -p ${interpwghtsdir}
# copy mesh to local fix directory
cp -p ${RWPSfix}/fix/${meshID}/20260722/rwps.${meshID}.msh ${interpwghtsdir}
# copy Interpoplation weights for nbm, rrfs, rtofs and stofs to local directory
cp -p ${RWPSfix}/fix/${meshID}/20260722/InterpolationWeights*${meshID}*.nc ${interpwghtsdir}
# copy distance to boundary for nbm, rrfs, rtofs and stofs to local  directory
cp -p ${RWPSfix}/fix/${meshID}/20260722/DistToBndy*${meshID}*.nc ${interpwghtsdir}

meshname="${mesh##*/}"
export meshname="${meshname: 0: -4}"

#Retrieve current and process for forecast cycle
qsub -V -o ${tmp}/prep_current.out ${HOMErwps}/ecf/jrwps_prep_current.ecf 
qsub -V -o ${tmp}/prep_ice.out ${HOMErwps}/ecf/jrwps_prep_ice.ecf
qsub -V -o ${tmp}/prep_waterlevel.out ${HOMErwps}/ecf/jrwps_prep_waterlevel.ecf
qsub -V -o ${tmp}/prep_wind.out ${HOMErwps}/ecf/jrwps_prep_wind.ecf
