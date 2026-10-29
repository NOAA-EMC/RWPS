import numpy as np
import netCDF4 as nc
import os
import sys
HOMErwps = os.environ['HOMErwps']
USHrwps=HOMErwps+'/ush'
PREPROCESSrwps=USHrwps+'/preprocess'
sys.path.append(PREPROCESSrwps)
import interp_utilities as iutil

####################################################################################################
# This script imposes a maximum current speed for an ocean current forecast.  It is added to RWPS 
# preprocessing to suppress artifacts related to wetting and drying from STOFS current forecasts.
# Call as: 
#
# $python limit_max_current_speed.py input_forecast.nc output_forecast.nc maximum_current_speed
#
# where:
#    input_forecast.nc is the input current forecast, potentially with high current artifacts
#    output_forecast.nc is the output file with imposed current speed limit
#    maximum_current_speed is maximum imposed current speed in (m/s)
#
# Alternativly currents in regions violating the speed limit can be replaced with a constant value,
# 0. or nan in practice. For this usage call as:
#
# $python limit_max_current_speed.py input_forecast.nc output_forecast.nc maximum_current_speed 0.
#
# or
#
# $python limit_max_current_speed.py input_forecast.nc output_forecast.nc maximum_current_speed nan
#
# A variable, "spd-orig", is added to file output_forecast.nc to maintain a record of current speed
# suppression.
#
####################################################################################################
# October 2026
####################################################################################################

nargin = len(sys.argv) - 1

flin=sys.argv[1]
flout=sys.argv[2]
maxspd=float(sys.argv[3])

replace_vals_with_constant=False
if nargin > 3:
    imposed_value=float(sys.argv[4])
    replace_vals_with_constant=True

data = nc.Dataset(flin,"r")
u=np.array(data['u-vel'][:,:])
v=np.array(data['v-vel'][:,:])
spd=np.sqrt(u**2+v**2)
j=np.where(spd>maxspd)

if replace_vals_with_constant:
    print("replacing all currents faster than "+str(maxspd)+ " (m/s) with value "+str(imposed_value))
    u[j]=imposed_value
    v[j]=imposed_value
else:
    print("limiting all currents to maximum speed "+str(maxspd)+ " (m/s)")
    u[j]=maxspd*u[j]/spd[j]
    v[j]=maxspd*v[j]/spd[j]

if "_FillValue" in data['u-vel'].ncattrs():
    fill_value0=data['u-vel']._FillValue
else:
    fill_value0=-99999

with  nc.Dataset(flout, "w", format="NETCDF4") as ncout:
    # 1. Copy Global Attributes
    ncout.setncatts({attr: data.getncattr(attr) for attr in data.ncattrs()})
    # 2. Copy Dimensions
    for name, dimension in data.dimensions.items():
        # If the dimension is unlimited, pass None to createDimension
        dim_len = len(dimension) if not dimension.isunlimited() else None
        ncout.createDimension(name, dim_len)
    for name, src_var in data.variables.items():
        if not ("vel" in name):
            dst_var = ncout.createVariable(name, src_var.datatype, src_var.dimensions)
            dst_var.setncatts({attr: src_var.getncattr(attr) for attr in src_var.ncattrs()})
            dst_var[:] = src_var[:]

    u_var=ncout.createVariable('u-vel', 'f4', ('time','node'), fill_value = fill_value0)
    iutil.CopyAttributes(data['u-vel'], u_var)
    u_var[:,:]=u[:,:]

    v_var=ncout.createVariable('v-vel', 'f4', ('time','node'), fill_value = fill_value0)
    iutil.CopyAttributes(data['v-vel'], v_var)
    v_var[:,:]=v[:,:]

    s_var=ncout.createVariable('spd-orig', 'f4', ('time','node'), fill_value = fill_value0)
    iutil.CopyAttributes(data['u-vel'], s_var)
    u_var.long_name     = 'current speed in origonal (unmodified) forecast'
    u_var.standard_name = 'origonal current speed'
    s_var[:,:]=spd[:,:]
    ncout.close
