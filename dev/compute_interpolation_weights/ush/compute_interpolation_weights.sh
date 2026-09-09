!/bin/bash

# --------------------------------------------------------------------------- #
# Launch scripts to compute interpolation weights for an RWPS mesh. To run:   #
#                                                                             #
# $sh ./compute_interpolation_weights.sh oc_500m_10km                         #
#                                                                             #
# to generate interpolation weights for unstructured mesh                     #
# rwps.oc_500m_10km.msh.                                                      #
#                                                                             #
# Last Changed : 09-04-2026                                                   #
# --------------------------------------------------------------------------- #

echo 'setting paths...'

export meshID=$1

export HOMErwps=$(cd "$(dirname "$(readlink -f -n "${BASH_SOURCE[0]}")")" && git rev-parse --show-toplevel)

export mesh="$HOMErwps/fix/rwps.$meshID.msh"
export fix="$HOMErwps/fix"

export out=$HOMErwps/interpolation_weights

mkdir -p $out

#machine dependend path to RWPS fix files
export RWPSfix=/lfs/h2/emc/couple/noscrub/keston.smith/RWPS

# copy mesh to local fix directory
#cp -p $RWPSfix/fix/$meshID/20260722/rwps.$meshID.msh $HOMErwps/fix/
#sh $HOMErwps/get_externals.sh

$HOMErwps/sorc/link_workflow.sh

meshname="${mesh##*/}"
export meshname="${meshname: 0: -4}"

#Retrieve current and process for forecast cycle
qsub -V $HOMErwps/dev/compute_interpolation_weights/ecf/compute_interpolation_weights.ecf

