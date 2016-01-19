#!/bin/bash

# Build GMP
function build_gmp() {
  name=gmp
  version=6.1.0
  folder=$name-$version
  tarball=$name-$version.tar.bz2
  tar_f=$name-$version
  url=https://gmplib.org/download/gmp/$tarball

  cd $build_dir
  mkdir -p $folder/bld
  cd $folder
  if [ ! -f $dist_dir/$tarball ]; then
    wget $url -P $dist_dir
  fi
  tar -xjvf $dist_dir/$tarball
  ln -s $tar_f src
  cd bld
  config_string=
  config_string+=" "--prefix=$install_dir/$folder
  ../src/configure $config_string
  make -j $jobs
  make install
  cd $install_dir
  ln -s $folder $name
  cd $build_dir
}

# Build MPFR
function build_mpfr() {
  name=mpfr
  version=3.1.3
  folder=$name-$version
  tarball=$name-$version.tar.gz
  tar_f=$name-$version
  url=http://www.mpfr.org/mpfr-current/$tarball

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
  config_string+=" "--with-gmp=$install_dir/gmp
  config_string+=" "--prefix=$install_dir/$folder
  ../src/configure $config_string
  make -j $jobs
  make install
  cd $install_dir
  ln -s $folder $name
  cd $build_dir
}

# Build MPC
function build_mpc() {
  name=mpc
  version=1.0.3
  folder=$name-$version
  tarball=$name-$version.tar.gz
  tar_f=$name-$version
  url=ftp://ftp.gnu.org/gnu/mpc/$tarball

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
  config_string+=" "--with-gmp=$install_dir/gmp
  config_string+=" "--with-mpfr=$install_dir/mpfr
  config_string+=" "--prefix=$install_dir/$folder
  ../src/configure $config_string
  make -j $jobs
  make install
  cd $install_dir
  ln -s $folder $name
  cd $build_dir
}

# Build GCC
function build_gcc() {
  name=gcc
  version=5.3.0
  folder=$name-$version
  tarball=$name-$version.tar.gz
  tar_f=$name-$version
  url=http://www.netgull.com/gcc/releases/gcc-$version/$tarball

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
  config_string+=" "--with-gmp=$install_dir/gmp
  config_string+=" "--with-mpfr=$install_dir/mpfr
  config_string+=" "--with-mpc=$install_dir/mpc
  config_string+=" "--prefix=$install_dir/$folder
  ../src/configure $config_string
  make -j $jobs
  make install
  cd $install_dir
  ln -s $folder $name
  cd $build_dir
}

# Build OpenMPI
function build_openmpi() {
  name=openmpi
  version=1.10.1
  folder=$name-$version
  tarball=$name-$version.tar.gz
  tar_f=$name-$version
  url=http://www.open-mpi.org/software/ompi/v1.10/downloads/$tarball

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
  config_string+=" "--prefix=$install_dir/$folder
  ../src/configure $config_string
  make -j $jobs
  make install
  cd $install_dir
  ln -s $folder $name
  cd $build_dir
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
export dist_dir=$base_dir/dist
export install_dir=$base_dir/opt
export build_dir=$copy_dir/build

mkdir -p $base_dir $dist_dir $install_dir $build_dir

# Setup environment variables
setup_env

# Build compilers
build_gmp
build_mpfr
build_mpc
build_gcc
if [[ "$args" == *" mpi "* ]]; then
  build_openmpi
fi

# Delete unneeded stuff
cleanup
