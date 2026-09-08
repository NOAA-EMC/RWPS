# This is a a set of routines that interpolate wind forecasts to an unstructured 
# mesh from regular or curvilinear grids (using ESMPY). In addition to interpolation 
# field the out file contains a spatially variable error variance estimate based on the 
# distance to the forecast boundary. This error variance is used later to update 
# dispirate forecasts in a bayesian manner to yield a spatially smooth estimate 
# incorporating all forecasts. The understanding is that the more local forecast 
# products are of higher accuracy than the coarser broader scale forecasts

import numpy as np
import os

import datetime
import netCDF4 as nc
import sys
import re

import xarray as xr
import esmpy
import scipy.sparse as sp

sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '../../../ush/preprocess')))

import interp_utilities as iutil

# Main program
AddExtrapolationSupport=True

nargin = len(sys.argv) - 1

flin=sys.argv[1]
mshfl=sys.argv[2]
weights_file=sys.argv[3]
dist2bnd_file=sys.argv[4]
# Don't use nearest neighbor interpolation unless 6th positive integer argument present.
# This may be needed on boundary of RWPS mesh if node alignment is outside NBM OC domain
Extrapolate=False
if nargin > 4:
    if int(sys.argv[5])>0:
        print("using nearest neighbor to extrapolate wind field beyond geometric coverage")
        Extrapolate=True

xi, yi, ei, zi = iutil.loadWW3Mesh(mshfl)
nn=len(xi)
#shift coords to[129,370]
data = nc.Dataset(flin,"r")

#read spaital dimensions and determine if input mesh is curvilinear or regular
x1=np.asarray(data["longitude"][:])
y1=np.asarray(data["latitude"][:])

#   rwps        :[-231, 11]
#   nbm         :[129, 370]
#   rrfs,pr     :[ -75.5000  -62.5087]
#   rrfs,hi     :[ -161.5250 -153.8690]
#   rrfs,ak     :[150.2012  266.2886]
#   rrfs,na     :[67.5721  427.0000]
#   rrfs,conus  :[ 225.9045  299.0828]
#   rtofs,glo   :[74.1552,434.0146]
#   stofs, glo  :[-180,180]

#Shift longitude coordinates to RWPS specs for various files
if "hi" in flin:
    x1=x1+360.
if "pr" in flin:
    x1=x1+360.

if "rtofs" in flin: #remove bad geometry edges
    x1=x1[1:-1,1:-1]
    y1=y1[1:-1,1:-1]
    x1=x1-360.

if (len(x1.shape)==2 and len(y1.shape)==2):
    IsCrvLn=True
elif (len(x1.shape)==1 and len(y1.shape)==1):
    #represent regular grid as curvilinear grid
    IsCrvLn=False
    nx=len(x1)
    ny=len(y1)
    x1 = np.tile(x1,(ny,1))
    y1 = np.tile(y1,(nx,1)).T
    IsCrvLn=True
else:
    print("input file spatial dimension is not recognized. ending program")
    sys.exit()
    
#######################################
# === Create weights  ===#
#######################################
meshslash=mshfl.rfind('/')+1
dom=flin.split(".")
dom=dom[len(dom)-2]

print("interpolation weights will be written to file = "+ weights_file)

nx=x1.shape[0]
ny=x1.shape[1]
n1=nx*ny

print("Computing weights and saving to file: "+ weights_file)

#Use esmpy to construct bilinear interpolation weights
iutil.CurvilinearGridCreateInterpWeights(xi, yi, x1, y1, weights_file)

#######################################
# === read weights and  ===#
#######################################
with xr.open_dataset(weights_file) as ds_s:
   # Standard sparse storage uses 'row', 'col', and 'S'==weights variables
   row = ds_s['row'].values
   col = ds_s['col'].values
   weights = ds_s['S'].values
   Nrows=ds_s.attrs.get('Nrows')
   Ncols=ds_s.attrs.get('Ncols')
print("nn = "+str(nn)+": Nrows = "+str(Nrows))
print("n1 = "+str(n1)+": Ncols = "+str(Ncols))
if not ((nn==Nrows) and (n1==Ncols)):
    print("Wrong matrix weights: number of rows from "+ mshfl +" = "+str(nn)+
    " but number of rows in "+ weights_file +" = "+str(Nrows)+ 
    ", number of spatial points in "+ flin +" = "+str(n1)+ 
    " but number of columns in "+ weights_file +" = "+str(Ncols)  )
    print("  You probably need to remove file "+ weights_file +" and rerun to generate appropriate weights")
matrix = sp.coo_matrix((weights, (row-1, col-1)), shape=(nn,n1)).tocsr()
print("sparse interpolation matrix")
print(matrix)

##################################################################################
# START: Extrapolate for nodes not covered by interpolator
##################################################################################
x1v=np.transpose(x1).reshape(n1) # vectorize src nodes, consistant with data to interpolate
y1v=np.transpose(y1).reshape(n1)

if Extrapolate:
    from scipy.interpolate import NearestNDInterpolator
    srcp = np.array((x1v,y1v)).T
    srcv = 1.+x1v**2 + y1v**2 #dummy input field
    #dstv = matrix @ srcv.T
    row_sum = matrix.sum(axis=1)
    j0=np.where( row_sum==0 ) # destination nodes with no coverage from interpolation matrix
    j0=np.array(j0[0]).tolist()
    dstp = np.array((xi[j0],yi[j0])).T
    interpolator = NearestNDInterpolator(srcp, srcv)
    distances, j0src = interpolator.tree.query(dstp)
    weightsExtrp=weights.tolist().append([1.0] * len(j0) )
    rowExtrp=np.concatenate( (row, np.array(j0)) )
    colExtrp=np.concatenate( (col, np.array(j0src+1)) )
    weightsExtrp=np.concatenate( (weights, np.array([1.0] * len(j0))) )
    os.replace(weights_file, weights_file[0:-3]+".NoExtrap.nc")
    iutil.WriteInterpolationWeightsToNetCDF(weights_file,rowExtrp,colExtrp,weightsExtrp,len(xi),len(x1v))
##################################################################################
# FINISHED: Extrapolate for nodes not covered by interpolator
##################################################################################

##################################################################################
# START: Extrapolation support for NaN occurances in source field
##################################################################################
if AddExtrapolationSupport:
    with nc.Dataset(weights_file, 'r+', format='NETCDF4') as ncadd:
        ncadd.createDimension('nn_src' , len(x1v))
        ncadd.createDimension('nn_dst' , len(xi))
        
        xsrc_var=ncadd.createVariable('x_src', 'f8', ('nn_src',))
        xsrc_var.long_name     = 'interpolation source node longitude'
        xsrc_var[:]=x1v[:]
        
        ysrc_var=ncadd.createVariable('y_src', 'f8', ('nn_src',))
        ysrc_var.long_name     = 'interpolation source node latitude'
        ysrc_var[:]=y1v[:]
        
        xdst_var=ncadd.createVariable('x_dst', 'f8', ('nn_dst',))
        xdst_var.long_name     = 'interpolation destination node longitude'
        xdst_var[:]=xi[:]
    
        ydst_var=ncadd.createVariable('y_dst', 'f8', ('nn_dst',))
        ydst_var.long_name     = 'interpolation destination node latitude'
        ydst_var[:]=yi[:]
        
##################################################################################
# FINISHED: Extrapolation support for NaN occurances in source field
##################################################################################
with nc.Dataset(weights_file, 'r+', format='NETCDF4') as ncadd:
    ncadd.setncattr("SrcFieldType", "gridded")
    ncadd.setncattr("InputFile", flin)
    ncadd.setncattr("MeshFile", mshfl)


##################################################################################
# START: Compute distance to boundary for each node in mesh:
##################################################################################
row_sum = matrix.sum(axis=1)
j0=np.where( row_sum==0 ) # destination nodes with no coverage from interpolation matrix
j0=np.array(j0[0]).tolist()
u0=np.ones(xi.shape)
nan=float("nan")
u0[j0]=nan

if not j0: #all points are interpolation envelope
    dist2bnd=0.*xi + np.inf
else:
    dist2bnd=iutil.CalculateDistanceToInterpEnvelope(xi,yi,u0, 1.)

if Extrapolate:
    dist2bnd=0.*dist2bnd + np.inf #all points are inside boundary- No boundary with this type of extrapolation
    print(np.mean(dist2bnd))


with nc.Dataset(dist2bnd_file, 'w', format='NETCDF4') as ncout:
    ncout.createDimension('node' , nn)
    d_var=ncout.createVariable('dist2bnd', 'f4', ('node',))
    d_var.long_name     = 'distance to boundary'
    d_var.units         = 'km'
    d_var.standard_name = 'distance to boundary'
    d_var[:]=dist2bnd[:]
    
    z_var=ncout.createVariable('depth', 'f4', ('node',))
    z_var.long_name     = 'mesh depth'
    z_var.units         = 'm'
    z_var.standard_name = 'depth'
    z_var[:]=zi[:]

