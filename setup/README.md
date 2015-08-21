Setup Instructions
=====================================================
Introduction
-----------------------------------------------------
CHTC works by offering an on demand compute service. You request a job to run which is
submitted to the Condor job queue. When this job is complete, the results are returned to 
you. When the job is launched, you have in essence a full linux terminal with bear-bones
tools at the other end. You must take care to build the tools you need, for our case we need
to build our own GCC toolchain for compilation and we then need DAGMC and its dependent tools. 
The scripts present here build the GCC toolchain and DAGMC (& its dependencies). These scripts
present to you a successful build of GCC as tar.gz and a set of MOAB,HDF5 etc as another. These files
should live in your squid directory (a fast massively high bandwith storage system).

build_stack.sh/cmd
-----------------------------------------------------
On CHTC you can run the following command

$> condor_submit build_stack.cmd

When the job returns to you compiler.tar.gz you should run

$> cp compiler.tar.gz /squid/$USER/.


build_runtime.sh/cmd
-----------------------------------------------------
You need to modifiy this script in order to build the correct toolchain, right now
we only support building Geant4 and Fluka. Edit the line in build_runtime.cmd 

In order to build you should modify the build_stack.cmd file with either

  arguments = username fluka

  arguments = username geant4

  arguments = username fluka geant4

In order to build you should run the following command from CHTC.

  $> condor_submit build_runtime.cmd 

When the job returns to you compiler.tar.gz you should run

  $> cp runtime.tar.gz /squid/$USER/.

Complete
----------------------------------------------------
When this is done you are ready to launch your first CHTC Fluka or Geant4 job!
