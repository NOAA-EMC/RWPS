from datetime import datetime
import numpy as np
import netCDF4 as nc
#Common utilities used for processing RWPS forcing


def ConvertTimeToUnixTime(flin,TimeVarName = None):
    if TimeVarName == None:
        TimeVarName="time"
    data = nc.Dataset(flin,"r")
    #print("TimeVarName = "+TimeVarName)
    timevar=data[TimeVarName]
    time=np.asarray(data[TimeVarName][:])
    epoch_1970 = datetime(1970, 1, 1, 0, 0, 0)
    TimeUnitsString=timevar.units
    TimeUnitsStrings=TimeUnitsString.split(" ")
    tunits=TimeUnitsStrings[0]
    dstr=TimeUnitsStrings[2]
    dstr=dstr.split("-")
    tstr=TimeUnitsStrings[3]
    tstr=tstr.split(":")
    print(dstr)
    print(tstr)
    secstr=tstr[2].rsplit(".", 1)[0]
    base_date = datetime(int(dstr[0]),int(dstr[1]),int(dstr[2]),int(tstr[0]),int(tstr[1]),int(secstr))
    base_offset = int((base_date - epoch_1970).total_seconds())
    if tunits=="seconds":
        unix_time = time + base_offset
    if tunits=="days":
        unix_time = time*24*60*60 + base_offset
    if tunits=="hours":
        unix_time = time*60*60 + base_offset
    return unix_time

def FileNameToUnixTime(flin,FcastPDY,FcastCYC):
    year0=int(FcastPDY[0:4])
    month0=int(FcastPDY[4:6])
    day0=int(FcastPDY[6:8])
    hr0=int(FcastCYC)
    #remove path and file  
    suffixp = flin.rfind(".")
    dirp = flin.rfind("/")
    flin=flin[dirp+1:suffixp]
    
    IsForecast=True
    ntimep=flin.find(".f")
    ntimeu=flin.find("_f")
    ntime=max(ntimep,ntimeu)
    print("ntime: "+str(ntime))
    if ntime<1:
        IsForecast=False
        ntimep=flin.find(".n")
        ntimeu=flin.find("_n")
        ntime=max(ntimep,ntimeu)
    
    print("ntime: "+str(ntime))
    ctime=flin[ntime+2:ntime+5]
    print(ctime)
    ctime=ctime.replace(".", "") #remove trailing "." in some file names
    
    print("FileNameToUnixTime A:")
    print(flin)
    print(ctime)
    hrf=int(ctime)
    epoch_1970 = datetime(1970, 1, 1, 0, 0, 0)
    FileTime =   datetime(year0,month0,day0, hr0, 0, 0)
    base_offset = int((FileTime - epoch_1970).total_seconds())
    if IsForecast:
        unix_time = base_offset + abs(hrf)*3600
    else:
        unix_time = base_offset - abs(hrf)*3600
        
    print("FileNameToUnixTime:")
    print(str(year0)+" "+str(month0)+ " " +str(day0)   + " " +str(hr0))
    print(flin)
    print(ctime)
    print(base_offset)
    print(hrf)
    return unix_time

def loadWW3Mesh(fl):
    print("mesh file="+fl)
    f=open(fl, 'r')
    header = f.readline() 
    header = f.readline() 
    header = f.readline() 
    header = f.readline() 
    header = f.readline() # number of nodes
    nn=int(header)
    print("nn = "+str(nn))
    xi=np.zeros(nn)
    yi=np.zeros(nn)
    zi=np.zeros(nn)
    k=0
    for i in range(nn):
        A = f.readline()
        B=A.lstrip()
        values = B.split(" ")
#        print(values)
        if len(values)>5:
            xi[k]=values[2]
            yi[k]=values[4]
            zi[k]=values[6]
        else:
            xi[k]=values[1]
            yi[k]=values[2]
            zi[k]=values[3]
        k=k+1
    print("number of nodes read: "+str(k))
    header = f.readline() 
    header = f.readline() 
    header = f.readline() # number of elements
    ne=int(header)#includes boundary nodes and actual elements
    print("ne="+str(ne)+" -includes boundary nodes")
    nbnd=0
    bnd=[]
    eix=np.zeros((ne,3), dtype=int)
    k=0
    for i in range(ne):
        A = f.readline()
        #print(A)
        values = A.split(" ")
        #print(values)
        if len(values) == 6:
            if int(values[2])==2:
                bnd.append(int(values[5]))
                nbnd=nbnd+1
        if len(values)>15:
            eix[k,0]=int(values[12])
            eix[k,1]=int(values[14])
            eix[k,2]=int(values[16])
            k=k+1
        elif len(values)>7:
            eix[k,0]=int(values[6])
            eix[k,1]=int(values[7])
            eix[k,2]=int(values[8])
            k=k+1
    ei=eix[range(k),:]
    print("number of open boundary nodes read: "+str(nbnd))
    print("number of elements read: "+str(k))
    return xi, yi, ei, zi

def CopyAttributes(VarOld, VarNew):
    #Copy attributes from old NetCDF file variable to new NetCDF file variable
    att_names = VarOld.ncattrs()
    for jatt in range(len(att_names)):
        att_name=att_names[jatt]
        if (not (att_name=="_FillValue")):
            att_value = VarOld.getncattr(att_name)
            VarNew.setncattr(att_name, att_value)
    return
