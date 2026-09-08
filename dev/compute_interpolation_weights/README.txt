Scripts to create interpolation weights and distance to boundary files for interpolating forcing to RWPS mesh.
To run:

$ cd RWPS/dev/compute_interpolation_weights/sorc
$ sh compute_interpolation_weights.sh oc_1500m_30km

to generate interpolation files for mesh rwps.oc_1500m_30km.msh.  Files will be writen to directory:
RWPS/fix/

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
