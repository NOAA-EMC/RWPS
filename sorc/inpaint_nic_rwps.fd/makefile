SHELL=/bin/sh
#
SRCS=  inpaint_nic_rwps.f90
OBJS=  inpaint_nic_rwps.o
MODS=  
LSTS=  inpaint_nic_rwps.lst
#
FC=	ftn
FFLAGS=		-O3 -list -auto 
CMD=	inpaint_nic_rwps
#
all:	$(CMD)

inpaint_nic_rwps.o:		inpaint_nic_rwps.f90
	$(FC) -c $(FFLAGS) inpaint_nic_rwps.f90

$(CMD):	$(OBJS)
	$(FC) $(FFLAGS) -o $(CMD) $(OBJS)

clean:
	rm -f $(OBJS) $(MODS) $(LSTS)
