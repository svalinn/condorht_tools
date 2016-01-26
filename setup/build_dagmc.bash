#!/bin/bash

# Build HDF5
function build_hdf5() {
  name=hdf5
  version=$hdf5_version
  folder=$name-$version
  tarball=$name-$version.tar.gz
  tar_f=$name-$version
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
  ln -snf $folder $name
  cd $build_dir
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
  ln -snf $folder $name
  cd $build_dir
}

# Build CGM
function build_cgm() {
  name=cgm
  version=$cgm_version
  folder=$name-$version-cub-$cubit_version
  repo=https://bitbucket.org/fathomteam/$name
  branch=cgm$version

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
  ln -snf $folder $name
  cd $build_dir
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
  ln -snf $folder $name
  cd $build_dir
}

# Build Geant4
function build_geant4() {
  name=geant4
  version=$geant4_version
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
  ln -snf $folder $name
  cd $build_dir
}

# Build FLUKA
function build_fluka() {
  name=fluka
  version=$fluka_version
  folder=$name-$version
  tarball=fluka$version-linux-gfor64bitAA.tar.gz

  cd $install_dir
  mkdir -p $folder/bin
  cd $folder/bin
  tar -xzvf $dist_dir/$tarball
  export FLUPRO=$PWD
  export FLUFOR=gfortran
  make
  bash flutil/ldpmqmd
  cd $install_dir
  ln -snf $folder $name
  cd $build_dir
}

# Build DAGMC
function build_dagmc() {
  name=dagmc
  version=$dagmc_version
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
    cmake_string+=" "-DGEANT4_CMAKE_CONFIG:PATH=$install_dir/geant4/lib64/Geant4-10.0.2
  fi
  if [[ "$args" == *" fluka "* ]]; then
    if [ ! -x $install_dir/fluka/bin/flutil/rfluka.orig ]; then
      patch -N $install_dir/fluka/bin/flutil/rfluka $name/fluka/rfluka.patch
    fi
    cmake_string+=" "-DBUILD_FLUKA=ON
    cmake_string+=" "-DFLUKA_DIR=$install_dir/fluka/bin
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
  ln -snf $folder $name
  cd $build_dir
}

# Pack the results tarball
function pack_results() {
  output_tarball=dagmc.tar.gz

  cd $install_dir
  tar -czvf $output_tarball `ls --color=never | grep '^hdf5\|^cubit\|^cgm\|^moab\|^geant4\|^fluka\|^dagmc'`
  mv $output_tarball $copy_dir
}

# Delete unneeded stuff
function cleanup() {
  rm -rf $build_dir $install_dir
}

function main() {
  # Directory names
  export dist_dir=/mnt/gluster/$USER/dist       # Location where tarballs can be found
  export build_dir=/home/$USER/build            # Location to perform the build
  export install_dir=/home/$USER/opt            # Location to place binaries, libraries, etc.
  export copy_dir=/mnt/gluster/$USER            # Location to place output tarball
  export DATAPATH=/mnt/gluster/$USER/mcnp_data  # Location of MCNP data
  rm -rf $build_dir $install_dir
  mkdir -p $dist_dir $build_dir $install_dir $copy_dir $DATAPATH

  source ./versions.bash
  source ./common.bash
  set_compile_env
  set_dagmc_env
  get_compile
  export jobs=12

  build_hdf5
  if [[ "$args" == *" cubit "* ]]; then
    build_cubit
    build_cgm
  fi
  build_moab
  if [[ "$args" == *" geant4 "* ]]; then
    build_geant4
  fi
  if [[ "$args" == *" fluka "* ]]; then
    build_fluka
  fi
  build_dagmc

  pack_results
  cleanup
}

set -e
export args="$@"
export args=" "$args" "

main
