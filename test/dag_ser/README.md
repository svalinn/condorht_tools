Test problem for DAG serial MCNP calculation. In order to run copy these files to CHTC and run

    mcnp5 ix i=divertor_sum g=divertor_simgeom.h5m

When this runs it will produce a runtpe file, then we can submit
   
    condor_submit sub_simp.cmd

The above command, runs the actual problem containing the normal MCNP arguments, in this case contains

   mcnp5 c i=divertor_sim_cont g=divertor_simgeom.h5m o=ouptut r=runtpe

