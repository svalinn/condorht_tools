This directory contains several examples of submit scripts for HTCondor as configured at the University of Wisconsin-Madison. There are examples for both serial and parallel execution of MCNP as well as for vanilla MCNP and DAG-MCNP

Running DAG-MCNP (and MCNP) on Condor requries that we first produce an initial runtpe file containing the problem space (cross sections, tallies etc) which will serve as our start point. To produce this you must use

     mcnp5 ix i=<input> r=<name_of_runtpe>

This will prepare a runtpe ready for running, if there are errors please correct them before submitting a full Condor calculation.

Once your runtpe file is ready and your anciliary files are prepared, then ensure you are transferring all the input data required. In this example we must transfer the seed runtpe file, geometry and mesh informatiion. For example, using sub_simp.cmd (DAG-MCNP) requires that the following files are in the working directory, 

   * MCNP Driver file divertor_sim_cont
   * geometry file divertor_simgeom.h5m 
   * Runtape File runtpe
   * Tetmesh divertor_simmesh.h5m

Modifiying (or removing files) as nessessary to fit your run, and then launch

     condor_submit sub_simp.cmd

And then after some time assuming all went ok, you should recieve your output data