Scripts to create interpolation weights and distance to boundary files for interpolating forcing to RWPS mesh.
To run:

$ cd RWPS/dev/compute_interpolation_weights/ush
$ ./compute_interpolation_weights.sh oc_1500m_30km

to generate interpolation files for mesh rwps.oc_1500m_30km.msh.  Files will be writen to directory:
RWPS/interpolation_weights

Interpolation weights are created for:

nbm oc domain
rrfs hi domain (used for wind)
rrfs pr domain (used for wind)
rrfs ak domain (used for wind)
rrfs na domain (used for wind)
rrfs conus domain (used for wind)
nbm ak domain (used for ice concentration)
rtofs glo domain (used for current without extrapolation)
rtofs glo domain (used for ice with extrapolation)
stofs domain (used for waterlevel and current)

Currently only setup to work on wcoss2.

Interpolation weight files to be used for creating forcing are output to directory:
/lfs/h2/emc/ptmp/username/RWPS.interpolation_weights.oc_1500m_30km

Temporary files are created in a workspace directory:
/lfs/h2/emc/ptmp/username/RWPS.interpolation_weights.oc_1500m_30km.tmpdir
which can be removed after the interpolation weights are generated.

