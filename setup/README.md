Setup Instructions
========================================
Introduction
----------------------------------------
The Center for High Throughput Computing (CHTC) offers an on-demand compute service called HTCondor. When you submit a job to the Condor job queue on the submit mode, your job will be queued as resources become available. When the job is launched, you in essence are given a full linux terminal with bare-bones tools on an execute node. When your job is done, whatever files are remaining on the execute node are copied back to the submit node.

You must take care to build your own tools as the bare-bones tools are generally not sufficient. In our case, we need to build our own GCC toolchain as well as DAGMC and its dependencies. The scripts in this folder accomplish these tasks by compiling the requisite packages and returning them as a tarball.

HTCondor uses the SQUID web proxy to handle the transfer of large files to the execute nodes. If you need to copy large files such as tarballs to the execute node, you should first copy them to your squid directory (`/squid/$USER` on the submit node).

Build the compilers
----------------------------------------
The submit file `build_compile.sub` launches a job which copies the build script `build_compile.sh` to an execute node. The build script contains instructions for compiling the following packages:

1. GMP
2. MPFR
3. MPC
4. GCC
5. OpenMPI

You may want to modify the line starting with `arguments =` in `build_compile.sub` if you have pre-downloaded the tarballs for any of the five compiler packages. For example, if your tarballs are located in `/squid/ljjacobson`, you should modify the line to be

`arguments = ljjacobson`.

This is not required, however. If the tarballs are not found, they will simply be downloded off the internet.

The submit file should be submitted with the `-i` flag to declare it as an interactive job:

`$ condor_submit -i build_compile.sub`

After waiting a short while (generally a few minutes), you will be given a terminal on the execute node. Then run

`$ bash build_compile.sh`

to run the script which compiles the compilers and makes the compile tarball. This should take about 20-25 minutes. When it finishes, type

`$ exit`

to return to the submit node, where the newly-created tarball `compile.tar.gz` will be waiting. The last step is to copy the tarball to your SQUID directory by running

`$ cp compile.tar.gz /squid/$USER`.

Build DAGMC
----------------------------------------
The submit file `build_dagmc.sub` launches a job which copies the build script `build_dagmc.sh` to an execute node. The build script contains instructions for compiling the following packages:

1. HDF5
2. CUBIT (optional)
3. CGM (optional)
4. MOAB
5. FLUKA (optional)
6. Geant4 (optional)
7. DAGMC with FLUKA/Geant4/MCNP5

You will need to modify the line starting with `arguments =` in `build_dagmc.sub` to get the compiler tarball from the right location and to build DAGMC with the correct physics packages. For example, if your tarballs are located in `/squid/ljjacobson` and you wish to install DAG-Geant4 and DAG-MCNP5 with CUBIT/CGM support, you should modify the line to be

`arguments = ljjacobson cubit geant4 mcnp5`.

If you wish to install only DAG-FLUKA without CUBIT/CGM support, you should use

`arguments = ljjacobson fluka`.

Note that if you are installing CUBIT, FLUKA, or MCNP5, you are required to provide your own tarballs as they are not freely available on the internet.

As before, run

```
$ condor_submit -i build_dagmc.sub
$ bash build_compile.sh
$ exit
$ cp dagmc.tar.gz /squid/$USER
```
