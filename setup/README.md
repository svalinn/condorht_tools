Setup Instructions
========================================

Introduction
----------------------------------------
The Center for High Throughput Computing (CHTC) offers an on-demand compute service called HTCondor. When you submit a job to the Condor job queue on the submit mode, your job will be queued as resources become available. When the job is launched, you in essence are given a full linux terminal with bare-bones tools on an execute node. When your job is done, whatever files are remaining on the execute node are copied back to the submit node.

You must take care to build your own tools as the bare-bones tools are generally not sufficient. In our case, we need to build our own GCC toolchain as well as DAGMC and its dependencies. The scripts in this folder accomplish these tasks by compiling the requisite packages and returning them as a tarball.

HTCondor has three options for transferring files to and from the submit nodes: standard HTCondor file transfer, SQUID web proxy, and Gluster file share. The standard file transfer is not appropriate for these build jobs because the file sizes are too large. SQUID is also not appropriate because the files transferred through it are world-readable and MCNP is export controlled. Thus, Gluster file share is used. You must have access to the Gluster filespace to use these scripts; see [here](http://chtc.cs.wisc.edu/file-avail-gluster.shtml) for instructions on how to request access.

If you are installing CUBIT, FLUKA, or MCNP5, you are required to place their tarballs in your Gluster space (`/mnt/gluster/$USER`) before running these scripts. The scripts will also look for the tarballs for the other software in your Gluster space, but if they can't be found, the scripts will download them and place them in your Gluster space.

1. Build the compilers
----------------------------------------
The submit file `build_compile.sub` launches a job which copies the build script `build_compile.bash` to an execute node. The build script contains instructions for compiling the following packages:

1. GMP
2. MPFR
3. MPC
4. GCC
5. OpenMPI (optional)

If you do not want to build OpenMPI, then you will need to modify the line `arguments = mpi` in `build_compile.sub` to be `arguments =`.

Submit the submit file with `$ condor_submit build_compile.sub`. This will build the compilers and place the output binaries, libraries, headers, and other files in `/mnt/gluster/$USER/compile`.

2. Build DAGMC
----------------------------------------
The submit file `build_dagmc.sub` launches a job which copies the build script `build_dagmc.bash` to an execute node. The build script contains instructions for compiling the following packages:

1. HDF5
2. CUBIT (optional)
3. CGM (optional)
4. MOAB
5. FLUKA (optional)
6. Geant4 (optional)
7. DAGMC with FLUKA/Geant4/MCNP5

You may want to modify the line starting with `arguments =` in `build_dagmc.sub`. If you wish to build MOAB with CUBIT/CGM support, add the `cubit` argument. If you wish to install DAG-MCNP5 in MPI mode, add the `mpi` argument. Finally, add any of `mcnp5`, `geant4`, or `fluka` to specify which physics packages you want to build. The arguments may be specified in any order. The unedited submit file will result in building CUBIT and DAG-MCNP5 with MPI.

Submit the submit file with `$ condor_submit build_dagmc.sub`. This will build DAGMC and its dependencies and place the output binaries, libraries, headers, and other files in `/mnt/gluster/$USER/dagmc`.

3. Run the DAG-MCNP tests
----------------------------------------
The submit file `dag_mcnp_tests.sub` launches a job which copies the script `dag_mcnp_tests.bash` to an execute node. The script runs all of the tests in the [DAGMC test suite](https://github.com/ljacobson64/DAGMC-tests). A tarball called `results.tar.gz` containing the test results will be created and placed in your Gluster space. The tarball will also be copied to your home directory on the submit node.
