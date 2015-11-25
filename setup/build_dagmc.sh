#!/bin/bash

# Build HDF5
function build_hdf5() {
  cd $build_dir
  mkdir -p hdf5/bld
  cd hdf5
  hdf5_version=1.8.16
  hdf5_tar=hdf5-$hdf5_version.tar.gz
  get_tar $hdf5_tar squid https://www.hdfgroup.org/ftp/HDF5/releases/hdf5-$hdf5_version/src
  tar -xzvf $hdf5_tar
  ln -s hdf5-$hdf5_version src
  cd bld
  config_string=
  config_string+=" "--enable-shared
  config_string+=" "--disable-debug
  config_string+=" "--prefix=$dagmc_dir/hdf5
  ../src/configure $config_string
  make -j $jobs  # j=12: 1:02.21 wall time, 307884 kB mem
  make install
  export PATH=$dagmc_dir/hdf5/bin:$PATH
  export LD_LIBRARY_PATH=$dagmc_dir/hdf5/lib:$LD_LIBRARY_PATH
  cd $base_dir
}

# Build CUBIT
function build_cubit() {
  cd $dagmc_dir
  mkdir cubit
  cd cubit
  cubit_version=12.2
  cubit_tar=Cubit_LINUX64.$cubit_version.tar.gz
  get_tar $cubit_tar squid
  tar -xzvf $cubit_tar
  rm -f $cubit_tar
  export PATH=$dagmc_dir/cubit/bin:$PATH
  export LD_LIBRARY_PATH=$dagmc_dir/cubit/bin:$LD_LIBRARY_PATH
  cd $base_dir
}

# Build CGM
function build_cgm() {
  cd $build_dir
  mkdir -p cgm/bld
  cd cgm
  cgm_version=12.2
  git clone https://bitbucket.org/fathomteam/cgm -b cgm$cgm_version
  ln -s cgm src
  cd cgm
  autoreconf -fi
  cd ../bld
  config_string=
  config_string+=" "--enable-optimize
  config_string+=" "--enable-shared
  config_string+=" "--disable-debug
  config_string+=" "--with-cubit=$dagmc_dir/cubit
  config_string+=" "--prefix=$dagmc_dir/cgm
  ../src/configure $config_string
  make -j $jobs  # j=12: 0:09.20 wall time, 124360 kB mem
  make install
  export LD_LIBRARY_PATH=$dagmc_dir/cgm/lib/:$LD_LIBRARY_PATH
  cd $base_dir
}

# Build MOAB
function build_moab() {
  cd $build_dir
  mkdir -p moab/bld
  cd moab
  moab_version=4.9.0
  git clone https://bitbucket.org/fathomteam/moab -b Version$moab_version
  ln -s moab src
  cd moab
  autoreconf -fi
  cd ../bld
  config_string=
  config_string+=" "--enable-dagmc
  config_string+=" "--enable-optimize
  config_string+=" "--enable-shared
  config_string+=" "--disable-debug
  config_string+=" "--with-hdf5=$dagmc_dir/hdf5
  if [[ "$1" == "with_cubit" ]]; then
    config_string+=" "--with-cgm=$dagmc_dir/cgm
  fi
  config_string+=" "--prefix=$dagmc_dir/moab
  ../src/configure $config_string
  make -j $jobs  # j=12: 0:48.45 wall time, 159624 kB mem
  make install
  export PATH=$dagmc_dir/moab/bin:$PATH
  export LD_LIBRARY_PATH=$dagmc_dir/moab/lib/:$LD_LIBRARY_PATH
  cd $base_dir
}

# Build FLUKA (not working)
function build_fluka() {
  cd $build_dir
  mkdir -p fluka/bld
  cd fluka
  fluka_version=2011.2c
  fluka_tar=fluka$fluka_version-linux-gfor64bitAA.tar.gz
  get_tar $fluka_tar squid
  mkdir fluka
  ln -s fluka src
  tar -xzvf $fluka_tar -C src
  cd src
  export FLUFOR=gfortran
  export FLUPRO=$PWD
  make
  cd $base_dir
}

# Build Geant4
function build_geant4() {
  cd $build_dir
  mkdir -p geant4/bld
  cd geant4
  geant4_version=10.00.p02
  geant4_tar=geant4.$geant4_version.tar.gz
  get_tar $geant4_tar squid http://geant4.cern.ch/support/source
  tar -xzvf $geant4_tar
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
  cd $build_dir
  mkdir -p dagmc/bld
  cd dagmc
  git clone https://github.com/svalinn/DAGMC -b develop
  ln -s DAGMC src
  cmake_string=
  if [[ "$args" == *" mcnp5 "* ]]; then
    cd DAGMC/mcnp5
    mcnp5_tar=mcnp5_dist.tgz
    get_tar $mcnp5_tar squid
    tar -xzvf $mcnp5_tar Source
    cd Source
    patch -p2 < ../patch/dagmc.patch.5.1.60
    cd ../../../bld
    cmake_string+=" "-DBUILD_MCNP5=ON
    cmake_string+=" "-DMCNP5_DATAPATH=$build_dir/mcnp_data
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
  cmake_string+=" "-DCMAKE_FORTRAN_COMPILER=$compile_dir/gcc/bin/gfortran
  cmake_string+=" "-DCMAKE_INSTALL_PREFIX=$dagmc_dir/dagmc
  cmake_string+=" "$build_dir/dagmc/src
  cmake ../. $cmake_string
  make -j $jobs  # j=12: 0:22.98 wall time, 610716 kB mem (mcnp5 only)
  make install
  export PATH=$dagmc_dir/dagmc/bin:$PATH
  export LD_LIBRARY_PATH=$dagmc_dir/dagmc/lib:$LD_LIBRARY_PATH
}

# Pack dagmc tarball
function pack_dagmc() {
  cd $base_dir
  tar -pczvf $dagmc_tar dagmc
  mv $dagmc_tar $copy_dir
}

# Delete unneeded stuff
function cleanup() {
  rm -rf $compile_dir
  rm -rf $build_dir
  rm -rf $dagmc_dir
  rm -rf $base_dir/$compile_tar
  cd $copy_dir
  ls | grep -v $dagmc_tar | xargs rm -rf
}

set -e
export args="$@"
export args=" "$args" "

# Common functions
source ./common.sh

# Parallel jobs
export jobs=12

# Compiler tarball
export compile_tar=compile.tar.gz

# Output DAGMC tarball
export dagmc_tar=dagmc.tar.gz

# Username where tarballs are found (/squid/$username)
export username=$1

# Directory names
export copy_dir=$PWD
export base_dir=$HOME
export compile_dir=$base_dir/compile
export build_dir=$base_dir/build
export dagmc_dir=$base_dir/dagmc
mkdir -p $build_dir
mkdir -p $dagmc_dir

# Unpack the compiler tarball
get_compile

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

# Pack output DAGMC tarball
pack_dagmc

# Delete unneeded stuff
cleanup
