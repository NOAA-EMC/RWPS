import os
import argparse
import numpy as np
import netCDF4 as nc
import sys
import math
import interp_utilities as iutil
# Converts NBM direction and magnitude wind variables to U,V 
# Command line inputs:
#     argumnent 1 is the netcdf input file name with variables: WIND_10maboveground and WDIR_10maboveground
#     argumnent 2 is the netcdf output file name which will have vector wind variables:  UGRD_10maboveground and VGRD_10maboveground
# call as:
# python spd_dir_to_uv_nbm.py nbm.20260502.00.wind10m.oc.nc  nbm.20260502.00.wind10m.oc.uv.nc

flin=sys.argv[1] 
flout=sys.argv[2] 

fcst0 = nc.Dataset(flin,"r")

x=np.asarray(fcst0["longitude"][:])
y=np.asarray(fcst0["latitude"][:])
t=np.asarray(fcst0["time"][:])
spd=np.asarray(fcst0["WIND_10maboveground"][:,:,:])
theta=np.asarray(fcst0["WDIR_10maboveground"][:,:,:])

spdV=fcst0["WIND_10maboveground"]
fill_value0 = spdV._FillValue

u=-1*spd*np.sin(theta*np.pi/180.)
v=-1*spd*np.cos(theta*np.pi/180.)
u[np.where(spd==fill_value0)]=fill_value0
v[np.where(spd==fill_value0)]=fill_value0

nx=len(x)
ny=len(y)
nt=len(t)

with nc.Dataset(flout, 'w', format='NETCDF4') as ncout:
    # Create dimensions
    ncout.createDimension('lon' , nx)  # Unlimited dimension
    ncout.createDimension('lat' , ny)
    ncout.createDimension('time', nt)
    
    lon_var=ncout.createVariable('longitude', 'f8', ('lon',))
    lon_var.units         = 'degree_east'
    lon_var.long_name     = 'longitude'
    lon_var.standard_name = 'longitude'
    lon_var.axis          = 'lon'
    lon_var[:]=x[:]

    lat_var=ncout.createVariable('latitude', 'f8', ('lat',))
    lat_var.units         = 'degree_north'
    lat_var.long_name     = 'latitude'
    lat_var.standard_name = 'latitude'
    lat_var.axis          = 'lat'
    lat_var[:]=y[:]

    time_var=ncout.createVariable('time', 'f8', ('time',))
    time_varin=fcst0["time"]
    iutil.CopyAttributes(time_varin, time_var)
    time_var[:]=t[:]

    u_var=ncout.createVariable('UGRD_10maboveground', 'f4', ('time','lat','lon'),fill_value    = fill_value0)
    u_var.long_name     = 'U-Component of Wind'
    u_var.units         = 'm/s'
    u_var.standard_name = 'UGRD_10maboveground'
    u_var.level = '10 m above ground'
    u_var[:,:,:]=u[:,:,:]

    v_var=ncout.createVariable('VGRD_10maboveground', 'f4', ('time','lat','lon'),fill_value    = fill_value0)
    v_var.long_name     = 'V-Component of Wind'
    v_var.units         = 'm/s'
    v_var.standard_name = 'VGRD_10maboveground'
    v_var.level = '10 m above ground'
    v_var[:,:,:]=v[:,:,:]
    
    ncout.close
    
    
