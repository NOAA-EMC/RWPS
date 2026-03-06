#!/bin/bash
# --------------------------------------------------------------------------- #
#                                                                             #
# Copy external fix files that are too large to store in repository           #
#                                                                             #
# Last Changed : 08-15-2025                                        Aug 2025   #
# --------------------------------------------------------------------------- #

echo 'Fetching externals...'
cp -p /lfs/h2/emc/couple/noscrub/keston.smith/meshes/RWPS.v0.msh ../fix/
cp -p /lfs/h2/emc/couple/noscrub/saeideh.banihashemi/git/fv3gfs/fix/fix_glwu/mesh.glwu ../fix/mesh.rwps
cp -p /lfs/h2/emc/couple/noscrub/saeideh.banihashemi/git/fv3gfs/fix/fix_glwu/grint_weights.grlc_2p5km ../fix/
cp -p /lfs/h2/emc/couple/noscrub/saeideh.banihashemi/git/fv3gfs/fix/fix_glwu/grint_weights.grlr ../fix/
cp -p /lfs/h2/emc/couple/noscrub/saeideh.banihashemi/git/fv3gfs/fix/fix_glwu/grint_weights.grlr_500m ../fix/
