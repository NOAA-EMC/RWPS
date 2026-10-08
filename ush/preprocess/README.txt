Scripts for preprocessing RWPS forcing for a forecast cycle. This will:

1) retrieve relevant forecasts
2) interpolate spatially to RWPS mesh
3) find commmon time points in disparate forecasts
4) update forcing with local high resolution forcing in a bayesian manner

Forcing utilizes:

ice: 
    background forecasts : rtofs glo domain
    local forecast : nbm ak

current: 
    background forecasts : stofs global domain
    local forecast : rtofs global

water level:
    background forecasts : stofs global domain

wind:
    background forecast : nbm oc domain
    local forecast : rrfs conus domain
    local forecast : rrfs na domain
    local forecast : rrfs ak domain
    local forecast : rrfs hi domain
    local forecast : rrfs pr domain

Interpolation weights for these domains should be present in directory RWPS/interpolation_weights

To run:

$ cd RWPS/ush
$ ./prepare_forcing.sh 20260825 00 oc_1500m_30km

to prepare forcing for the RWPS forecast utilizing mesh rwps.oc_1500m_30km.msh for forecast starting 20260825 cycle 00. Currently setup to work on wcoss2. 
