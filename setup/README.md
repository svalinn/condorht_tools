Setup Instructions
========================================

Introduction
----------------------------------------
The Center for High Throughput Computing (CHTC) offers an on-demand compute service called HTCondor. When you submit a job to the Condor job queue on the submit node, your job will be queued as resources become available. When the job is launched, you in essence are given a full linux terminal with bare-bones tools on an execute node. When your job is done, whatever files are remaining on the execute node are copied back to the submit node.

You must take care to build your own tools as the bare-bones tools are generally not sufficient. In our case, we need to build our own GCC toolchain as well as DAGMC and its dependencies. The scripts in this folder accomplish these tasks by compiling the requisite packages and returning them as a tarball.

HTCondor has three options for transferring files to and from the submit nodes: standard HTCondor file transfer, SQUID web proxy, and Gluster file share. The standard file transfer is not appropriate for these build jobs because the file sizes are too large. SQUID is also not appropriate because the files transferred through it are world-readable and MCNP is export controlled. Thus, Gluster file share is used. You must have access to the Gluster filespace to use these scripts; see <a href="http://chtc.cs.wisc.edu/file-avail-gluster.shtml" target="_blank">here</a> for instructions on how to request access.

1. Build script
----------------------------------------
The submit file `build.sub` launches a job which copies the build script `build.bash` as well as `build_funcs.bash` and `common.bash` to an execute node. The script is smart in that knows which packages depend on which other packages, and it will account for the dependencies during the build.

The `arguments =` line in `build.bash` should be edited to indicate which packages should be installed. For example, if you only want to build PyNE, you should use `arguments = pyne` and PyNE and all its dependencies will be built.

The presence of some of the arguments will affect the build of others. For example, if `openmpi`, `mcnp5`, and `dagmc` are selected, then OpenMPI and an MPI version of DAG-MCNP5 will be built. If `cgm` and `moab` are selected, then MOAB will be built against CGM. The default arguments (`openmpi cubit cgm mcnp5 geant4 fluka dagmc pyne`) will result in building the entire stack.

If you are installing CUBIT, FLUKA, or MCNP5, you are required to place their tarballs in your Gluster space (`/mnt/gluster/$USER/dist`) before installation. The scripts will also look for the tarballs for the other software in your Gluster space, but if they can't be found, the scripts will download them from the internet and place them in your Gluster space.

The script `common.bash` contains the directory structure for the build as well as the the version numbers for all the packages. You may edit these variables if you so choose.

The build script contains instructions for compiling the following packages. The default versions are listed.

1. GMP 6.1.0
2. MPFR 3.1.3
3. MPC 1.0.3
4. GCC 5.3.0
5. OpenMPI 1.10.2
6. CMake 3.4.3
7. Python 2.7.10
8. HDF5 1.8.13
9. Setuptools 20.0
10. Cython 0.23.4
11. NumPy 1.10.4
12. SciPy 0.16.1
13. PyTables 3.2.0
14. Nose 1.3.7
15. CUBIT 12.2
  * must have `Cubit_LINUX64.12.2.tar.gz` or variant in Gluster
16. CGM 12.2
  * specify `cubit` to build with CUBIT
17. MOAB 4.9.0
  * specify `cgm` to build with CGM
18. PyTAPS master
19. MCNP5 1.60
  * must have `mcnp5_dist.tgz` in Gluster
20. Geant4 10.00.p02
21. FLUKA 2011.2c
  * must have `fluka2011.2c-linux-gfor64bitAA.tar.gz` or variant in Gluster
22. DAGMC dev
  * specify `mcnp5` to build DAG-MCNP5
  * specify `mcnp5` and `openmpi` to build an MPI version of DAG-MCNP5
  * specify `geant4` to build DAG-Geant4
  * specify `fluka` to build FluDAG
23. PyNE dev

Submit the submit file with `$ condor_submit build.sub`. This will build the packages and place tarballs containing the output binaries, libraries, headers, and other files for each package in `/mnt/gluster/$USER/tar_install`.

2. Run the DAGMC tests
----------------------------------------
The submit file `dagmc_tests.sub` launches a job which copies the script `dagmc_tests.bash` to an execute node. The script runs the DAG-MCNP5 and FluDAG tests in the <a href="https://github.com/ljacobson64/DAGMC-tests" target="_blank">DAGMC test suite</a>. The script will look for GMP, MPFR, MPC, GCC, OpenMPI, CMake, and HDF5 as they would have been built by `build.bash`, and if they cannot be found, the will be built. MOAB, DAG-MCNP5, and FluDAG will be re-built every time the tests are run.

You must have the MCNP data tarball `mcnp_data.tar.gz` in your Gluster space in order to be able to run the tests.

When the tests have finished, a tarball containing the results will be created and placed in `/mnt/gluster/$USER/results`. The tarball filename will contain the date and time the tests were completed.
