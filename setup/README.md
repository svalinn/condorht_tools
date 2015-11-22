Setup Instructions
========================================
Introduction
----------------------------------------
The Center for High Throughput Computing (CHTC) offers an on-demand compute service called HTCondor. When you submit a job to the Condor job queue on the submit mode, your job will be queued as resources become available. When the job is launched, you in essence are given a full linux terminal with bare-bones tools on an execute node. When your job is done, whatever files are remaining on the execute node are copied back to the submit node.

You must take care to build your own tools as the bare-bones tools are generally not sufficient. In our case, we need to build our own GCC toolchain as well as DAGMC and its dependencies. The scripts in this folder accomplish these tasks by compiling the requisite packages and returning them as a tarball.

HTCondor uses the SQUID web proxy to handle the transfer of large files to the execute nodes. If you need to copy large files such as tarballs to the execute node, you should first copy them to your squid directory (/squid/$USER on the submit node).

Build the compilers
----------------------------------------
The submit file `build_compile.sub` launches a job which copies the build script `build_compile.sh` to an execute node. The build script contains instructions for compiling the following packages:

1. GMP
2. MPFR
3. MPC
4. GCC
5. OpenMPI

The submit file should be submitted with the `-i` flag to declare it as an interactive job:

`$ condor_submit -i build_compile.sub`

After waiting a short while (generally a few minutes), you will be given a terminal on the execute node. Then run

`$ bash build_compile.sh`

to run the script which compiles the compilers and makes the compile tarball. This should take about 20-25 minutes. When it finishes, type

`$ exit`

to return to the submit node, where the newly-created tarball `compile.tar.gz` will be waiting. The last step is to copy the tarball to your SQUID directory by running

`$ cp compile.tar.gz /squid/$USER`.

build_dagmc.sub / build_dagmc.sh
----------------------------------------
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
----------------------------------------
When this is done you are ready to launch your first CHTC Fluka or Geant4 job!
