#!/bin/bash
# --------------------------------------------------------------------------- #
#                                                                             #
# Copy external fix files that are too large to store in repository           #
#                                                                             #
# Last Changed : 08-15-2025                                        Aug 2025   #
# --------------------------------------------------------------------------- #

echo 'Fetching externals...'


# copy mesh to local fix directory
cp -p $RWPSfix/fix/$meshname/20260722/rwps.$meshname.msh ../fix/
# copy Interpoplation weights for nbm, rrfs, rtofs and stofs to local fix directory
cp -p $RWPSfix/fix/$meshname/20260722/InterpolationWeights*$meshname*.nc ../fix/
# copy distance to boundary for nbm, rrfs, rtofs and stofs to local fix directory
cp -p $RWPSfix/fix/$meshname/20260722/DistToBndy*$meshname*.nc ../fix/


#cp -p /lfs/h2/emc/couple/noscrub/keston.smith/meshes/RWPS.v0.msh ../fix/

cp -p /lfs/h2/emc/couple/noscrub/saeideh.banihashemi/git/fv3gfs/fix/fix_glwu/mesh.glwu ../fix/mesh.rwps
cp -p /lfs/h2/emc/couple/noscrub/saeideh.banihashemi/git/fv3gfs/fix/fix_glwu/grint_weights.grlc_2p5km ../fix/
cp -p /lfs/h2/emc/couple/noscrub/saeideh.banihashemi/git/fv3gfs/fix/fix_glwu/grint_weights.grlr ../fix/
cp -p /lfs/h2/emc/couple/noscrub/saeideh.banihashemi/git/fv3gfs/fix/fix_glwu/grint_weights.grlr_500m ../fix/
