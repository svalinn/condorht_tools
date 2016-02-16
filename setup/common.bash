#!/bin/bash

# Set directories
function set_dirs() {
  export    orig_dir=$PWD
  export    test_dir=$orig_dir                       # Location to perform DAGMC tests
  export   build_dir=/tmp/$USER/build                # Location to perform the build
  export install_dir=/tmp/$USER/opt                  # Location to install binaries, libraries, etc.
  export    dist_dir=/mnt/gluster/$USER/dist         # Location where tarballs can be found
  export    copy_dir=/mnt/gluster/$USER/tar_install  # Location to place output tarballs
  export    DATAPATH=/mnt/gluster/$USER/mcnp_data    # Location of MCNP data
  export results_dir=/mnt/gluster/$USER/results      # Location to place DAGMC test result tarballs
}

# Set package versions
function set_versions() {
  export        gmp_version=6.1.0
  export       mpfr_version=3.1.3
  export        mpc_version=1.0.3
  export        gcc_version=5.3.0

  export    openmpi_version=1.10.2
  export      cmake_version=3.4.3
  export     python_version=2.7.10
  export       hdf5_version=1.8.13

  export setuptools_version=20.0
  export     cython_version=0.23.4
  export      numpy_version=1.10.4
  export      scipy_version=0.16.1
  export   pytables_version=3.2.0
  export       nose_version=1.3.7

  export      cubit_version=12.2
  export        cgm_version=$cubit_version
  export       moab_version=4.9.0
  export     pytaps_version=master

  export     geant4_version=10.00.p02
  export      fluka_version=2011.2c

  export      dagmc_version=dev
  export       pyne_version=dev
}

# Set environment variables
function set_env() {
  export PATH=$install_dir/gcc/bin:$PATH
  export PATH=$install_dir/openmpi/bin:$PATH
  export PATH=$install_dir/cmake/bin:$PATH
  export PATH=$install_dir/python/bin:$PATH
  export PATH=$install_dir/hdf5/bin:$PATH
  export PATH=$install_dir/setuptools/bin:$PATH
  export PATH=$install_dir/cython/bin:$PATH
  export PATH=$install_dir/numpy/bin:$PATH
  export PATH=$install_dir/scipy/bin:$PATH
  export PATH=$install_dir/pytables/bin:$PATH
  export PATH=$install_dir/nose/bin:$PATH
  export PATH=$install_dir/cubit/bin:$PATH
  export PATH=$install_dir/moab/bin:$PATH
  export PATH=$install_dir/pytaps/bin:$PATH
  export PATH=$install_dir/geant4/bin:$PATH
  export PATH=$install_dir/fluka/bin:$PATH
  export PATH=$install_dir/dagmc/bin:$PATH
  export PATH=$install_dir/pyne/bin:$PATH

  export LD_LIBRARY_PATH=$install_dir/gmp/lib:$LD_LIBRARY_PATH
  export LD_LIBRARY_PATH=$install_dir/mpfr/lib:$LD_LIBRARY_PATH
  export LD_LIBRARY_PATH=$install_dir/mpc/lib:$LD_LIBRARY_PATH
  export LD_LIBRARY_PATH=$install_dir/gcc/lib:$LD_LIBRARY_PATH
  export LD_LIBRARY_PATH=$install_dir/gcc/lib64:$LD_LIBRARY_PATH
  export LD_LIBRARY_PATH=$install_dir/openmpi/lib:$LD_LIBRARY_PATH
  export LD_LIBRARY_PATH=$install_dir/cmake/lib:$LD_LIBRARY_PATH
  export LD_LIBRARY_PATH=$install_dir/python/lib:$LD_LIBRARY_PATH
  export LD_LIBRARY_PATH=$install_dir/hdf5/lib:$LD_LIBRARY_PATH
  export LD_LIBRARY_PATH=$install_dir/cubit/bin:$LD_LIBRARY_PATH
  export LD_LIBRARY_PATH=$install_dir/cgm/lib:$LD_LIBRARY_PATH
  export LD_LIBRARY_PATH=$install_dir/moab/lib:$LD_LIBRARY_PATH
  export LD_LIBRARY_PATH=$install_dir/geant4/lib:$LD_LIBRARY_PATH
  export LD_LIBRARY_PATH=$install_dir/geant4/lib64:$LD_LIBRARY_PATH
  export LD_LIBRARY_PATH=$install_dir/dagmc/lib:$LD_LIBRARY_PATH

  export PYTHONPATH=$install_dir/setuptools/lib/python2.7/site-packages:$PYTHONPATH
  export PYTHONPATH=$install_dir/cython/lib/python2.7/site-packages:$PYTHONPATH
  export PYTHONPATH=$install_dir/numpy/lib/python2.7/site-packages:$PYTHONPATH
  export PYTHONPATH=$install_dir/scipy/lib/python2.7/site-packages:$PYTHONPATH
  export PYTHONPATH=$install_dir/pytables/lib/python2.7/site-packages:$PYTHONPATH
  export PYTHONPATH=$install_dir/nose/lib/python2.7/site-packages:$PYTHONPATH
  export PYTHONPATH=$install_dir/pytaps/lib/python2.7/site-packages:$PYTHONPATH
  export PYTHONPATH=$install_dir/pyne/lib/python2.7/site-packages:$PYTHONPATH

  export FLUFOR=gfortran
  export FLUPRO=$install_dir/fluka/bin
  export FLUDAG=$install_dir/dagmc/bin
}
