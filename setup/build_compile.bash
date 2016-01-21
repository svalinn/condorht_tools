#!/bin/bash

# Build GMP
function build_gmp() {
  name=gmp
  version=$gmp_version
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
  export LD_LIBRARY_PATH=$install_dir/gmp/lib:$LD_LIBRARY_PATH
  cd $install_dir
  ln -snf $folder $name
  cd $build_dir
}

# Build MPFR
function build_mpfr() {
  name=mpfr
  version=$mpfr_version
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
  export LD_LIBRARY_PATH=$install_dir/mpfr/lib:$LD_LIBRARY_PATH
  cd $install_dir
  ln -snf $folder $name
  cd $build_dir
}

# Build MPC
function build_mpc() {
  name=mpc
  version=$mpc_version
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
  export LD_LIBRARY_PATH=$install_dir/mpc/lib:$LD_LIBRARY_PATH
  cd $install_dir
  ln -snf $folder $name
  cd $build_dir
}

# Build GCC
function build_gcc() {
  name=gcc
  version=$gcc_version
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
  export PATH=$install_dir/gcc/bin:$PATH
  export LD_LIBRARY_PATH=$install_dir/gcc/lib:$LD_LIBRARY_PATH
  export LD_LIBRARY_PATH=$install_dir/gcc/lib64:$LD_LIBRARY_PATH
  cd $install_dir
  ln -snf $folder $name
  cd $build_dir
}

# Build OpenMPI
function build_openmpi() {
  name=openmpi
  version=$openmpi_version
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
  export PATH=$install_dir/openmpi/bin:$PATH
  export LD_LIBRARY_PATH=$install_dir/openmpi/lib:$LD_LIBRARY_PATH
  cd $install_dir
  ln -snf $folder $name
  cd $build_dir
}

# Build CMake
function build_cmake() {
  name=cmake
  version=$cmake_version
  folder=$name-$version
  tarball=$name-$version.tar.gz
  tar_f=$name-$version
  url=http://www.cmake.org/files/v3.4/$tarball

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
  export PATH=$install_dir/cmake/bin:$PATH
  export LD_LIBRARY_PATH=$install_dir/cmake/lib:$LD_LIBRARY_PATH
  cd $install_dir
  ln -snf $folder $name
  cd $build_dir
}

# Delete unneeded stuff
function cleanup() {
  rm -rf $build_dir
}

function main() {
  # Directory names
  export copy_dir=$PWD                  # Location of tarball to be copied back to submit node
  export base_dir=/mnt/gluster/$USER
  export dist_dir=$base_dir/dist        # Location where software tarballs are found
  export install_dir=$base_dir/opt      # Location to place binaries, libraries, etc.
  export build_dir=$copy_dir/build      # Location to perform builds
  export log_dir=$base_dir/log          # Location to place build logs
  mkdir -p $dist_dir $install_dir $build_dir $log_dir

  source ./versions.bash                # Get software versions
  source ./common.bash                  # Common functions
  export jobs=12                        # Parallel jobs

  build_gmp 1>| $log_dir/gmp.out 2>| $log_dir/gmp.err
  build_mpfr 1>| $log_dir/mpfr.out 2>| $log_dir/mpfr.err
  build_mpc 1>| $log_dir/mpc.out 2>| $log_dir/mpc.err
  build_gcc 1>| $log_dir/gcc.out 2>| $log_dir/gcc.err
  if [[ "$args" == *" mpi "* ]]; then
    build_openmpi 1>| $log_dir/openmpi.out 2>| $log_dir/openmpi.err
  fi
  build_cmake 1>| $log_dir/cmake.out 2>| $log_dir/cmake.err

  cleanup                               # Delete unneeded stuff
}

set -e
export args="$@"
export args=" "$args" "

main #1> $copy_dir/_condor_stdout 2> $copy_dir/_condor_stderr
