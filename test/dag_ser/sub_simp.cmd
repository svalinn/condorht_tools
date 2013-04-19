#############################################

## submit description file for a parallel program

#############################################

universe = vanilla
executable = /home/davisa/dagmc/mcnp5src/bin/mcnp5
arguments = c i=divertor_sim_cont g=divertor_simgeom.h5m r=runtpe o=divertor_sim.o 
output = std.out
error = std.err
log = std.log
copy_to_spool           = false
should_transfer_files   = yes
when_to_transfer_output = on_exit
transfer_input_files = runtpe,divertor_sim_cont,divertor_simgeom.h5m,divertor_simmesh.h5m
+AccountingGroup = "EngrPhysics_Wilson"

queue