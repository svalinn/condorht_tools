#!/bin/bash

# Build HDF5
function build_hdf5() {
  hdf5_version=1.8.16
  hdf5_tar=hdf5-$hdf5_version.tar.gz
  hdf5_url=https://www.hdfgroup.org/ftp/HDF5/releases/hdf5-$hdf5_version/src/$hdf5_tar

  cd $build_dir
  mkdir -p hdf5/bld
  cd hdf5
  if [ ! -f $tar_dir/$hdf5_tar ]; then
    wget $hdf5_url -P $tar_dir
  fi
  tar -xzvf $tar_dir/$hdf5_tar
  ln -s hdf5-$hdf5_version src
  cd bld
  config_string=
  config_string+=" "--enable-shared
  config_string+=" "--disable-debug
  config_string+=" "--prefix=$dagmc_dir/hdf5
  ../src/configure $config_string
  make -j $jobs
  make install
  export PATH=$dagmc_dir/hdf5/bin:$PATH
  export LD_LIBRARY_PATH=$dagmc_dir/hdf5/lib:$LD_LIBRARY_PATH
  cd $base_dir
}

# Build CUBIT
function build_cubit() {
  cubit_version=12.2
  cubit_tar=Cubit_LINUX64.$cubit_version.tar.gz

  cd $dagmc_dir
  mkdir cubit
  cd cubit
  tar -xzvf $tar_dir/$cubit_tar
  export PATH=$dagmc_dir/cubit/bin:$PATH
  export LD_LIBRARY_PATH=$dagmc_dir/cubit/bin:$LD_LIBRARY_PATH
  cd $base_dir
}

# Build CGM
function build_cgm() {
  cgm_version=12.2
  cgm_repo=https://bitbucket.org/fathomteam/CGM
  cgm_branch=cgm$cgm_version

  cd $build_dir
  mkdir -p cgm/bld
  cd cgm
  git clone $cgm_repo -b $cgm_branch
  ln -s CGM src
  cd CGM
  autoreconf -fi
  cd ../bld
  config_string=
  config_string+=" "--enable-optimize
  config_string+=" "--enable-shared
  config_string+=" "--disable-debug
  config_string+=" "--with-cubit=$dagmc_dir/cubit
  config_string+=" "--prefix=$dagmc_dir/cgm
  ../src/configure $config_string
  make -j $jobs
  make install
  export LD_LIBRARY_PATH=$dagmc_dir/cgm/lib/:$LD_LIBRARY_PATH
  cd $base_dir
}

# Build MOAB
function build_moab() {
  moab_version=4.9.0
  moab_repo=https://bitbucket.org/fathomteam/MOAB
  moab_branch=Version$moab_version

  cd $build_dir
  mkdir -p moab/bld
  cd moab
  git clone $moab_repo -b $moab_branch
  ln -s MOAB src
  cd MOAB
  autoreconf -fi
  cd ../bld
  config_string=
  config_string+=" "--enable-dagmc
  config_string+=" "--enable-optimize
  config_string+=" "--enable-shared
  config_string+=" "--disable-debug
  config_string+=" "--with-hdf5=$dagmc_dir/hdf5
  if [[ "$args" == *" cubit "* ]]; then
    config_string+=" "--with-cgm=$dagmc_dir/cgm
  fi
  config_string+=" "--prefix=$dagmc_dir/moab
  ../src/configure $config_string
  make -j $jobs
  make install
  export PATH=$dagmc_dir/moab/bin:$PATH
  export LD_LIBRARY_PATH=$dagmc_dir/moab/lib/:$LD_LIBRARY_PATH
  cd $base_dir
}

# Build FLUKA (not working)
function build_fluka() {
  fluka_version=2011.2c
  fluka_tar=fluka$fluka_version-linux-gfor64bitAA.tar.gz

  cd $build_dir
  mkdir -p fluka/bld
  cd fluka
  mkdir fluka
  ln -s fluka src
  tar -xzvf $tar_dir/$fluka_tar -C src
  cd src
  export FLUFOR=gfortran
  export FLUPRO=$PWD
  make
  cd $base_dir
}

# Build Geant4
function build_geant4() {
  geant4_version=10.00.p02
  geant4_tar=geant4.$geant4_version.tar.gz
  geant4_url=http://geant4.cern.ch/support/source/$geant4_tar

  cd $build_dir
  mkdir -p geant4/bld
  cd geant4
  if [ ! -f $tar_dir/$geant4_tar ]; then
    wget $geant4_url -P $tar_dir
  fi
  tar -xzvf $tar_dir/$geant4_tar
  ln -s geant4.$geant4_version src
  cd bld
  cmake ../src -DGEANT4_USE_SYSTEM_EXPAT=OFF \
               -DCMAKE_INSTALL_PREFIX=$dagmc_dir/geant4
  make -j $jobs
  make install
  export PATH=$dagmc_dir/geant4/bin:$PATH
  export LD_LIBRARY_PATH=$dagmc_dir/geant4/lib64/:$LD_LIBRARY_PATH
  #export GEANT4DIR=$cwd/geant4
  #source $cwd/geant4/bld/geant4make.sh
  cd $base_dir
}

# Build DAGMC
function build_dagmc() {
  dagmc_repo=https://github.com/svalinn/DAGMC
  dagmc_branch=develop
  mcnp5_tar=mcnp5_dist.tgz

  cd $build_dir
  mkdir -p dagmc/bld
  cd dagmc
  git clone $dagmc_repo -b $dagmc_branch
  ln -s DAGMC src
  cmake_string=
  if [[ "$args" == *" mcnp5 "* ]]; then
    cd DAGMC/mcnp5
    tar -xzvf $tar_dir/$mcnp5_tar Source
    cd Source
    patch -p2 < ../patch/dagmc.patch.5.1.60
    cd ../../../bld
    cmake_string+=" "-DBUILD_MCNP5=ON
    cmake_string+=" "-DMCNP5_DATAPATH=$DATAPATH
    if [[ "$args" == *" mpi "* ]]; then
      cmake_string+=" "-DMPI_BUILD=ON
    fi
  fi
  if [[ "$args" == *" geant4 "* ]]; then  # not working
    cd bld
    cmake_string+=" "-DBUILD_GEANT4=ON
    cmake_string+=" "-DGEANT4_DIR=$dagmc_dir/geant4
  fi
  if [[ "$args" == *" fluka "* ]]; then  # not working
    patch $dagmc_dir/fluka/flutil/rfluka DAGMC/fluka/rfluka.patch
    cd bld
    cmake_string+=" "-DBUILD_FLUKA=ON
    cmake_string+=" "-DFLUKA_DIR=$FLUPRO
  fi
  cmake_string+=" "-DCMAKE_C_COMPILER=$compile_dir/gcc/bin/gcc
  cmake_string+=" "-DCMAKE_CXX_COMPILER=$compile_dir/gcc/bin/g++
  cmake_string+=" "-DCMAKE_Fortran_COMPILER=$compile_dir/gcc/bin/gfortran
  cmake_string+=" "-DCMAKE_INSTALL_PREFIX=$dagmc_dir/dagmc
  cmake_string+=" "$build_dir/dagmc/src
  cmake ../. $cmake_string
  make -j $jobs
  make install
  export PATH=$dagmc_dir/dagmc/bin:$PATH
  export LD_LIBRARY_PATH=$dagmc_dir/dagmc/lib:$LD_LIBRARY_PATH
}

# Delete unneeded stuff
function cleanup() {
  rm -rf $build_dir
}

set -e
export args="$@"
export args=" "$args" "

# Common functions
source ./common.bash

# Parallel jobs
export jobs=12

# Directory names
export copy_dir=$PWD
export base_dir=/mnt/gluster/$USER
export tar_dir=$base_dir
export compile_dir=$base_dir/compile
export dagmc_dir=$base_dir/dagmc
export build_dir=$copy_dir/build
export DATAPATH=$base_dir/mcnp_data
mkdir -p $tar_dir $dagmc_dir $build_dir

# Setup compiler environment variables
setup_compile_env

# Build DAGMC dependencies
build_hdf5
if [[ "$args" == *" cubit "* ]]; then
  build_cubit
  build_cgm
fi
build_moab

# Build physics packages
if [[ "$args" == *" fluka "* ]]; then
  build_fluka
fi
if [[ "$args" == *" geant4 "* ]]; then
  build_geant4
fi

# Build DAGMC
build_dagmc

# Delete unneeded stuff
cleanup
