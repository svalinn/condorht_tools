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
  cd $install_dir
  ln -snf $folder $name
  cd $build_dir
}

# Pack the results tarball
function pack_results() {
  output_tarball=compile.tar.gz

  cd $install_dir
  tar -czvf $output_tarball `ls --color=never | grep '^gmp\|^mpfr\|^mpc\|^gcc\|^openmpi\|^cmake'`
  mv $output_tarball $copy_dir
}

# Delete unneeded stuff
function cleanup() {
  rm -rf $build_dir $install_dir
}

function main() {
  # Directory names
  export dist_dir=/mnt/gluster/$USER/dist  # Location where tarballs can be found
  export build_dir=/home/$USER/build       # Location to perform the build
  export install_dir=/home/$USER/opt       # Location to place binaries, libraries, etc.
  export copy_dir=/mnt/gluster/$USER       # Location to place output tarball
  mkdir -p $dist_dir $build_dir $install_dir $copy_dir

  source ./versions.bash
  source ./common.bash
  set_compile_env
  export jobs=12

  build_gmp
  build_mpfr
  build_mpc
  build_gcc
  if [[ "$args" == *" mpi "* ]]; then
    build_openmpi
  fi
  build_cmake

  pack_results
  cleanup
}

set -e
export args="$@"
export args=" "$args" "

main
