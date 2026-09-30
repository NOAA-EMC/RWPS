#!/bin/bash

# --------------------------------------------------------------------------- #
# Launch scripts to compute interpolation weights for an RWPS mesh. To run:   #
#                                                                             #
# $sh ./compute_interpolation_weights.sh oc_500m_10km                         #
#                                                                             #
# to generate interpolation weights for unstructured mesh                     #
# rwps.oc_500m_10km.msh.                                                      #
#                                                                             #
# Last Changed : 09-09-2026                                                   #
# --------------------------------------------------------------------------- #

echo 'setting paths...'

export meshID=$1

export HOMErwps=$(cd "$(dirname "$(readlink -f -n "${BASH_SOURCE[0]}")")" && git rev-parse --show-toplevel)

usrtmp="/lfs/h2/emc/ptmp/${USER}"

export ushIW=${HOMErwps}/dev/compute_interpolation_weights/ush

mkdir -p ${usrtmp}
export DATA="${usrtmp}/RWPS.interpolation_weights.${meshID}.tmpdir"
mkdir -p ${DATA}
export out="${usrtmp}/RWPS.interpolation_weights.${meshID}"
mkdir -p ${out}

# link mesh corresponding to meshID to local fix directory
${HOMErwps}/sorc/link_workflow.sh
export mesh="${HOMErwps}/fix/${meshID}/rwps.${meshID}.msh"
meshname="${mesh##*/}"
export meshname="${meshname: 0: -4}"

cd ${DATA}

#Construct interpolation weights and distance to boundary for meshID and forcing grids
qsub -V ${HOMErwps}/dev/compute_interpolation_weights/ecf/compute_interpolation_weights.ecf

