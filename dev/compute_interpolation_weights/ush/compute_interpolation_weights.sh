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

export RWPSroot=$(cd "$(dirname "$(readlink -f -n "${BASH_SOURCE[0]}")")" && git rev-parse --show-toplevel)

export mesh="$RWPSroot/fix/rwps.$meshID.msh"


export fix="$RWPSroot/fix"
export prep="$RWPSroot/PrepInputs"
export tmp="$prep/tmpfiles"
export frc="$prep/forcing"
export outdir=$prep

mkdir -p $prep
mkdir -p $tmp
mkdir -p $frc


#machine dependend path to rtofs, nbm, rrfs, and stofs forecast files
export COMINrtofs="/lfs/h1/ops/prod/com/rtofs/v2.5/rtofs.$PDY/"
export COMINnbm="/lfs/h3/mdl/ptmp/mdl.nbm/blend/v5.2/blend.$PDY/$cyc/grib2"
export COMINrrfs="/lfs/h1/ops/prod/com/rrfs/v1.0/rrfs.$PDY/$cyc"
export COMINstofs="/lfs/h1/ops/prod/com/stofs/v3.1/stofs_2d_glo.$PDY"

export COMINlocal=$tmp

#machine dependend path to RWPS fix files
export RWPSfix=/lfs/h2/emc/couple/noscrub/keston.smith/RWPS

# copy mesh to local fix directory
cp -p $RWPSfix/fix/$meshID/20260722/rwps.$meshID.msh $RWPSroot/fix/

meshname="${mesh##*/}"
export meshname="${meshname: 0: -4}"

#Retrieve current and process for forecast cycle
qsub -V $RWPSroot/dev/compute_interpolation_weights/ecf/compute_interpolation_weights.ecf

