#!/bin/bash

# Build HDF5
function build_hdf5() {
  name=hdf5
  version=1.8.16
  folder=$name-$version
  tarball=$name-$version.tar.gz
  tar_f=$name-$version.tar.gz
  url=https://www.hdfgroup.org/ftp/HDF5/releases/hdf5-$version/src/$tarball

  cd $build_dir
  mkdir -p $folder/bld
  cd $folder
  if [ ! -f $dist_dir/$tarball ]; then
    wget $url -P $dist_dir
  fi
  tar -xzvf $dist_dir/$tarball
  ln -s $tar_f src
  cd bld
  config_string=
  config_string+=" "--enable-shared
  config_string+=" "--disable-debug
  config_string+=" "--prefix=$install_dir/$folder
  ../src/configure $config_string
  make -j $jobs
  make install
  cd $install_dir
  ln -s $folder $name
  cd $base_dir
}

# Build CUBIT
function build_cubit() {
  name=cubit
  version=$cubit_version
  folder=$name-$version
  tarball=Cubit_LINUX64.$version.tar.gz

  cd $install_dir
  mkdir $folder
  cd $folder
  tar -xzvf $dist_dir/$tarball
  cd $install_dir
  ln -s $folder $name
  cd $base_dir
}

# Build CGM
function build_cgm() {
  name=cgm
  version=$cubit_version
  folder=$name-$version
  repo=https://bitbucket.org/fathomteam/$name
  branch=$name$version

  cd $build_dir
  mkdir -p $folder/bld
  cd $folder
  git clone $repo -b $branch
  ln -s $name src
  cd $name
  autoreconf -fi
  cd ../bld
  config_string=
  config_string+=" "--enable-optimize
  config_string+=" "--enable-shared
  config_string+=" "--disable-debug
  config_string+=" "--with-cubit=$install_dir/cubit
  config_string+=" "--prefix=$install_dir/$folder
  ../src/configure $config_string
  make -j $jobs
  make install
  cd $install_dir
  ln -s $name-$version $name
  cd $base_dir
}

# Build MOAB
function build_moab() {
  name=moab
  version=$moab_version
  folder=$name-$version-cub-$cubit_version
  repo=https://bitbucket.org/fathomteam/$name
  branch=Version$version

  cd $build_dir
  mkdir -p $folder/bld
  cd $folder
  git clone $repo -b $branch
  ln -s $name src
  cd $name
  autoreconf -fi
  cd ../bld
  config_string=
  config_string+=" "--enable-dagmc
  config_string+=" "--enable-optimize
  config_string+=" "--enable-shared
  config_string+=" "--disable-debug
  config_string+=" "--with-hdf5=$install_dir/hdf5
  if [[ "$args" == *" cubit "* ]]; then
    config_string+=" "--with-cgm=$install_dir/cgm
  fi
  config_string+=" "--prefix=$install_dir/$folder
  ../src/configure $config_string
  make -j $jobs
  make install
  cd $install_dir
  ln -s $folder $name
  cd $base_dir
}

# Build Geant4
function build_geant4() {
  name=geant4
  version=10.00.p02
  folder=$name-$version
  tarball=$name.$version.tar.gz
  tar_f=$name.$version
  url=http://geant4.cern.ch/support/source/$tarball

  cd $build_dir
  mkdir -p $folder/bld
  cd $folder
  if [ ! -f $dist_dir/$tarball ]; then
    wget $url -P $dist_dir
  fi
  tar -xzvf $dist_dir/$tarball
  ln -s $tar_f src
  cd bld
  cmake_string=
  cmake_string+=" "-DGEANT4_USE_SYSTEM_EXPAT=OFF
  cmake_string+=" "-DCMAKE_C_COMPILER=$install_dir/gcc/bin/gcc
  cmake_string+=" "-DCMAKE_CXX_COMPILER=$install_dir/gcc/bin/g++
  cmake_string+=" "-DCMAKE_INSTALL_PREFIX=$install_dir/$folder
  cmake ../src $cmake_string
  make -j $jobs
  make install
  cd $install_dir
  ln -s $folder $name
  cd $base_dir
}

# Build FLUKA (not working)
function build_fluka() {
  name=fluka
  version=2011.2c
  tarball=fluka$version-linux-gfor64bitAA.tar.gz

  cd $build_dir
  mkdir -p fluka/bld
  cd fluka
  mkdir fluka
  ln -s fluka src
  tar -xzvf $dist_dir/$tarball -C src
  cd src
  export FLUFOR=gfortran
  export FLUPRO=$PWD
  make
  cd $base_dir
}

# Build DAGMC
function build_dagmc() {
  name=dagmc
  version=dev
  folder=$name-$version-cub-$cubit_version-moab-$moab_version
  repo=https://github.com/svalinn/$name
  branch=develop
  mcnp5_tarball=mcnp5_dist.tgz

  cd $build_dir
  mkdir -p $folder/bld
  cd $folder
  git clone $repo -b $branch
  ln -s $name src
  cmake_string=
  if [[ "$args" == *" mcnp5 "* ]]; then
    cd $name/mcnp5
    tar -xzvf $dist_dir/$mcnp5_tarball Source
    cd Source
    patch -p2 < ../patch/dagmc.patch.5.1.60
    cd ../../..
    cmake_string+=" "-DBUILD_MCNP5=ON
    cmake_string+=" "-DMCNP5_DATAPATH=$DATAPATH
    if [[ "$args" == *" mpi "* ]]; then
      cmake_string+=" "-DMPI_BUILD=ON
    fi
  fi
  if [[ "$args" == *" geant4 "* ]]; then
    cmake_string+=" "-DBUILD_GEANT4=ON
    cmake_string+=" "-DGEANT4_DIR=$install_dir/geant4
  fi
  if [[ "$args" == *" fluka "* ]]; then  # not working
    patch $install_dir/fluka/flutil/rfluka DAGMC/fluka/rfluka.patch
    cmake_string+=" "-DBUILD_FLUKA=ON
    cmake_string+=" "-DFLUKA_DIR=$FLUPRO
  fi
  cmake_string+=" "-DCMAKE_C_COMPILER=$install_dir/gcc/bin/gcc
  cmake_string+=" "-DCMAKE_CXX_COMPILER=$install_dir/gcc/bin/g++
  cmake_string+=" "-DCMAKE_Fortran_COMPILER=$install_dir/gcc/bin/gfortran
  cmake_string+=" "-DCMAKE_INSTALL_PREFIX=$install_dir/$folder
  cmake_string+=" "$build_dir/$folder/src
  cd bld
  cmake ../. $cmake_string
  make -j $jobs
  make install
  cd $install_dir
  ln -s $folder $name
  cd $base_dir
}

# Delete unneeded stuff
function cleanup() {
  rm -rf $build_dir
}

set -e
export args="$@"
export args=" "$args" "

export cubit_version=12.2
export moab_version=4.9.0

# Common functions
source ./common.bash

# Parallel jobs
#export jobs=12

export jobs=24

# Directory names
export copy_dir=$PWD
export base_dir=/mnt/gluster/$USER
export dist_dir=$base_dir/dist
export install_dir=$base_dir/opt
export build_dir=$copy_dir/build
export DATAPATH=$base_dir/mcnp_data

mkdir -p $base_dir $dist_dir $install_dir $build_dir

# Setup environment variables
setup_env

# Build DAGMC dependencies
build_hdf5
if [[ "$args" == *" cubit "* ]]; then
  build_cubit
  build_cgm
fi
build_moab

# Build physics packages
if [[ "$args" == *" geant4 "* ]]; then
  build_geant4
fi
if [[ "$args" == *" fluka "* ]]; then
  build_fluka
fi

# Build DAGMC
build_dagmc

# Delete unneeded stuff
cleanup
