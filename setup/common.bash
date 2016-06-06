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
  export       mpfr_version=3.1.4
  export        mpc_version=1.0.3
  export        gcc_version=5.3.0

  export    openmpi_version=1.10.2
  export      cmake_version=3.4.3
  export     python_version=2.7.11
  export       hdf5_version=1.8.13
  export     lapack_version=3.6.0

  export setuptools_version=20.2.2
  export     cython_version=0.23.4
  export      numpy_version=1.10.4
  export      scipy_version=0.16.1
  export    numexpr_version=2.5
  export   pytables_version=3.2.0
  export       nose_version=1.3.7

  export      cubit_version=12.2
  export        cgm_version=12.2
  export       moab_version=4.9.0
  export    meshkit_version=master
  export     pytaps_version=master

  export     geant4_version=10.02
  export      fluka_version=2011.2c

  export      dagmc_version=dev
  export       pyne_version=dev

  export      boost_version=1.61.0
  export     sigcpp_version=2.99.6
}

# Set environment variables
function set_env() {
  # GMP
  export LD_LIBRARY_PATH=$install_dir/gmp/lib:$LD_LIBRARY_PATH

  # MPFR
  export LD_LIBRARY_PATH=$install_dir/mpfr/lib:$LD_LIBRARY_PATH

  # MPC
  export LD_LIBRARY_PATH=$install_dir/mpc/lib:$LD_LIBRARY_PATH

  # GCC
  export PATH=$install_dir/gcc/bin:$PATH
  export LD_LIBRARY_PATH=$install_dir/gcc/lib:$LD_LIBRARY_PATH
  export LD_LIBRARY_PATH=$install_dir/gcc/lib64:$LD_LIBRARY_PATH

  # OpenMPI
  export PATH=$install_dir/openmpi/bin:$PATH
  export LD_LIBRARY_PATH=$install_dir/openmpi/lib:$LD_LIBRARY_PATH

  # CMake
  export PATH=$install_dir/cmake/bin:$PATH
  export LD_LIBRARY_PATH=$install_dir/cmake/lib:$LD_LIBRARY_PATH

  # Python
  export PATH=$install_dir/python/bin:$PATH
  export LD_LIBRARY_PATH=$install_dir/python/lib:$LD_LIBRARY_PATH

  # HDF5
  export PATH=$install_dir/hdf5/bin:$PATH
  export LD_LIBRARY_PATH=$install_dir/hdf5/lib:$LD_LIBRARY_PATH

  # LAPACK
  export LD_LIBRARY_PATH=$install_dir/lapack/lib:$LD_LIBRARY_PATH

  # Setuptools
  export PATH=$install_dir/setuptools/bin:$PATH
  export PYTHONPATH=$install_dir/setuptools/lib/python2.7/site-packages:$PYTHONPATH

  # Cython
  export PATH=$install_dir/cython/bin:$PATH
  export PYTHONPATH=$install_dir/cython/lib/python2.7/site-packages:$PYTHONPATH

  # NumPy
  export PATH=$install_dir/numpy/bin:$PATH
  export PYTHONPATH=$install_dir/numpy/lib/python2.7/site-packages:$PYTHONPATH

  # SciPy
  export PATH=$install_dir/pytables/bin:$PATH
  export PYTHONPATH=$install_dir/scipy/lib/python2.7/site-packages:$PYTHONPATH

  # NumExpr
  export PYTHONPATH=$install_dir/numexpr/lib/python2.7/site-packages:$PYTHONPATH

  # PyTables
  export PYTHONPATH=$install_dir/pytables/lib/python2.7/site-packages:$PYTHONPATH

  # Nose
  export PATH=$install_dir/nose/bin:$PATH
  export PYTHONPATH=$install_dir/nose/lib/python2.7/site-packages:$PYTHONPATH

  # CUBIT
  export PATH=$install_dir/cubit/bin:$PATH
  export LD_LIBRARY_PATH=$install_dir/cubit/bin:$LD_LIBRARY_PATH

  # CGM
  export LD_LIBRARY_PATH=$install_dir/cgm/lib:$LD_LIBRARY_PATH

  # MOAB
  export PATH=$install_dir/moab/bin:$PATH
  export LD_LIBRARY_PATH=$install_dir/moab/lib:$LD_LIBRARY_PATH

  # MeshKit
  export PATH=$install_dir/meshkit/bin:$PATH
  export LD_LIBRARY_PATH=$install_dir/meshkit/lib:$LD_LIBRARY_PATH

  # PyTAPS
  export PATH=$install_dir/pytaps/bin:$PATH
  export PYTHONPATH=$install_dir/pytaps/lib/python2.7/site-packages:$PYTHONPATH

  # Geant4
  export PATH=$install_dir/geant4/bin:$PATH
  export LD_LIBRARY_PATH=$install_dir/geant4/lib:$LD_LIBRARY_PATH
  export LD_LIBRARY_PATH=$install_dir/geant4/lib64:$LD_LIBRARY_PATH

  # FLUKA
  export PATH=$install_dir/fluka/bin:$PATH
  export FLUFOR=gfortran
  export FLUPRO=$install_dir/fluka/bin
  export FLUDAG=$install_dir/dagmc/bin

  # DAGMC
  export PATH=$install_dir/dagmc/bin:$PATH
  export LD_LIBRARY_PATH=$install_dir/dagmc/lib:$LD_LIBRARY_PATH

  # PyNE
  export PATH=$install_dir/pyne/bin:$PATH
  export PYTHONPATH=$install_dir/pyne/lib/python2.7/site-packages:$PYTHONPATH

  # BOOST
  export LD_LIBRARY_PATH=$install_dir/boost/lib:$LD_LIBRARY_PATH

  # SIGC++
  export LD_LIBRARY_PATH=$install_dir/sigc++/lib:$LD_LIBRARY_PATH
}
