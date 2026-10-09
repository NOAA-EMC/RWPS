import numpy as np
import netCDF4 as nc
import sys
import os

######################################################################
# Compute and add error variance field to existing forecast. The error
# variance is based on proximity to the forecast domains boundary and 
# bathymetric depth. 
#
# Command line arguments:
# (1) Forecast filename to add error variance to
# (2) Filename with precomputed distance to forecast boundary and 
#     bathymetric depth
# (3) Parameters for specifying error variance from distance and depth.
#     Parameter values are seperated by ":" character
#
# For example:
# $ python add_err_var_to_file.py rwps.oc_1500m_30km.20260824.00.wind10m.nbm.oc.nc DistToBndy.rwps.oc_1500m_30km.nbm.oc.nc 100.
# to specify spatially constant 100 m**2 / s**2 error variance
# or:
# $ python add_err_var_to_file.py rwps.oc_1500m_30km.20260824.00.wind10m.rrfs.ak.nc DistToBndy.rwps.oc_1500m_30km.rrfs.ak.nc 9.:90.:500.
# to specify an interior error variance of 9 m**2 / s**2, boundary variance of 90 m**2 / s**2 and 500 km linear transition.
######################################################################

######################################################################
# BEGIN: routines for prescribing error variance relative to distance 
# to boundary and depth 
######################################################################
def VarianceLinearDistanceToBndy(DistanceToBoundary, InteriorVariance, VarianceOnBoundary, LengthScale):
    InteriorNodeList=np.where(DistanceToBoundary**2 >= 0 )
    Variance=np.zeros(len(DistanceToBoundary))+np.inf
    SpatialFunction=DistanceToBoundary/LengthScale
    j=np.where(SpatialFunction>1.)
    SpatialFunction[j]=1.
    Variance[InteriorNodeList] = VarianceOnBoundary + ( InteriorVariance - VarianceOnBoundary ) * SpatialFunction[InteriorNodeList]
    return Variance
def VarianceInverseDistanceToBndy( DistanceToBoundary, InteriorVariance, LengthScale):
    InteriorNodeList=np.where(DistanceToBoundary**2 >= 0 )
    Variance=np.zeros(len(DistanceToBoundary))+np.inf
    SpatialFunction=LengthScale / DistanceToBoundary
    j=np.where(SpatialFunction>1.)
    SpatialFunction[j]=1.
    Variance[InteriorNodeList] = InteriorVariance  * SpatialFunction[InteriorNodeList]
    return Variance
def VarianceLinearDepth(zi,VarianceShallow,VarianceDeep,Zshallow,Zdeep):        
    Variance = VarianceShallow + (VarianceDeep-VarianceShallow)*(zi-Zshallow)/(Zdeep-Zshallow)
    js=np.where(zi<Zshallow)
    jd=np.where(zi>Zdeep)
    Variance[js]=VarianceShallow
    Variance[jd]=VarianceDeep
    return Variance
######################################################################
# END: routines for prescribing error variance relative to distance 
# to boundary and depth 
######################################################################

UseUnixTime=True
nargin = len(sys.argv) - 1

flin=sys.argv[1]
dist2bnd_file=sys.argv[2]

VarParam0=sys.argv[3]
VarParam=VarParam0.split(":")

data=nc.Dataset(dist2bnd_file,"r")
dist2bnd=np.array(data["dist2bnd"][:])
zi=np.array(data["depth"][:])
nn=len(dist2bnd)
data.close()

#remove path and file  
suffixp = flin.rfind(".")
dirp = flin.rfind("/")
filename=flin[dirp+1:suffixp]


VariableType="WaterLevel"
if "wind" in filename:
    VariableType="Wind"
elif "uv" in filename:
    VariableType="Current"
elif "vel" in filename:
    VariableType="Current"
elif "ice" in filename:
    VariableType="Ice"
if "water" in filename:
    VariableType="WaterLevel"
if "level" in filename:
    VariableType="WaterLevel"

print("flin = "+flin+ ", VariableType = "+ VariableType)
if VariableType=="Current":
    VarShallow=float(VarParam[0]) # variance (m/s)**2 for shallow regions
    VarDeep=float(VarParam[1])  # variance (m/s)**2 for deep regions
    BatShallow=float(VarParam[2]) # isobath (m) for shallow regions
    BatDeep=float(VarParam[3]) # isobath (m) for deep regions
    if "stofs" in flin:  # error variance low in shallows and high in deeper regions
        Variance = VarianceLinearDepth (zi, VarShallow, VarDeep, BatShallow, BatDeep)
    if "rtofs" in flin: # error variance high in shallows and near boundary of coverage
        VarianceDepth = VarianceLinearDepth(zi,VarShallow,VarDeep,BatShallow,BatDeep)
        VarLambda= float(VarParam[4])  # lengthscale (km) for linear transition from bounadry variance(==VarShallow) to interior variance(==VarDeep)
        VarianceBnd = VarianceLinearDistanceToBndy( dist2bnd, VarDeep,VarShallow, VarLambda)
        Variance = np.maximum(VarianceDepth, VarianceBnd)

if VariableType=="WaterLevel":
    if (("stofs" in flin) or (True)):
        VarInterior=float(VarParam[0]) # variance (m)**2 for stofs water level
        Variance = VarInterior+0.*zi

if VariableType=="Wind":
    ##LocalFS  = [ rwps_pr, rwps_hi, rwps_ak, rwps_conus, rwps_na] # file names
    ##VarFS    = [ 4.     , 4.    , 9.      , 16.       , 25.    ] # (m m /s /s)
    ##LambdaFS = [ 150.   , 200.  , 500.    , 1000.     , 1500.  ] # (km)
    VarInterior=float(VarParam[0]) # variance (m/s)**2 for interior of forecast
    if "nbm" in flin:
        Variance = VarInterior + np.zeros(nn)
    if "rrfs" in flin:
        VarBoundary = float(VarParam[1]) # variance (m/s)**2 for boundary of forecast
        VarLambda   = float(VarParam[2]) # lengthscale (km) for linear transition from bounadry variance to interior variance
        Variance = VarianceLinearDistanceToBndy( dist2bnd, VarInterior, VarBoundary,VarLambda )


if VariableType=="Ice":
    VarInterior=float(VarParam[0]) # variance for interior of forecast
    if "rtofs" in flin:
        Variance = VarInterior + np.zeros(nn)
    if "nbm" in flin:
        VarBoundary = float(VarParam[1]) # variance for boundary of forecast
        VarLambda   = float(VarParam[2]) # lengthscale (km) for linear transition from bounadry variance to interior variance
        Variance = VarianceLinearDistanceToBndy( dist2bnd, VarInterior, VarBoundary,VarLambda )

fltmp=flin+".tmp.nc"
try:
    os.remove(fltmp)
except:
    print("creating "+fltmp+" temporarily")

data0 = nc.Dataset(flin,"r")

with  nc.Dataset(fltmp, "w", format="NETCDF4") as ncout:
    # 1. Copy Global Attributes
    ncout.setncatts({attr: data0.getncattr(attr) for attr in data0.ncattrs()})
    # 2. Copy Dimensions
    for name, dimension in data0.dimensions.items():
        # If the dimension is unlimited, pass None to createDimension
        dim_len = len(dimension) if not dimension.isunlimited() else None
        ncout.createDimension(name, dim_len)
    for name, src_var in data0.variables.items():
        dst_var = ncout.createVariable(name, src_var.datatype, src_var.dimensions)
        dst_var.setncatts({attr: src_var.getncattr(attr) for attr in src_var.ncattrs()})
        dst_var[:] = src_var[:]

    time=np.asarray(data0["time"][:])
    nt=len(time)
    ErrorVariance=np.zeros((nt,nn))
    for k in range(nt):
        ErrorVariance[k,:]=Variance[:]

    if not 'node' in ncout.dimensions:
        ncadd.createDimension('node' , nn)
    if not 'time' in ncout.dimensions:
        ncadd.createDimension('time' , nt)
    if not 'ErrorVariance' in ncout.variables:
        ErrorVariance_var=ncout.createVariable('ErrorVariance', 'f4', ('time','node'))
        ErrorVariance_var.long_name     = 'forecast error variance'
        ErrorVariance_var.units         = "(field units)**2"
        ErrorVariance_var.standard_name = 'errror variance'
        ErrorVariance_var[:]=ErrorVariance

    ncout.close

os.rename(fltmp, flin)
