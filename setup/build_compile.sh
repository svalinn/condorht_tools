#!/bin/bash

function build_gmp() {
  cd $build_dir
  mkdir gmp
  cd gmp
  wget https://gmplib.org/download/gmp/gmp-"$gmp_version".tar.bz2
  tar -xjvf gmp-"$gmp_version".tar.bz2
  ln -s gmp-"$gmp_version" src
  mkdir bld
  cd bld
  ../src/configure --prefix="$compile_dir"/gmp
  make -j $jobs  # 29168 kB
  make install
  export LD_LIBRARY_PATH="$compile_dir"/gmp/lib:"$LD_LIBRARY_PATH"
  cd $base_dir
}

function build_mpfr() {
  cd $build_dir
  mkdir mpfr
  cd mpfr
  wget http://www.mpfr.org/mpfr-current/mpfr-"$mpfr_version".tar.gz
  tar -xzvf mpfr-"$mpfr_version".tar.gz
  ln -s mpfr-"$mpfr_version" src
  mkdir bld
  cd bld
  ../src/configure --with-gmp="$compile_dir"/gmp \
                   --prefix="$compile_dir"/mpfr
  make -j $jobs  # 23744 kB
  make install
  export LD_LIBRARY_PATH="$compile_dir"/mpfr/lib:"$LD_LIBRARY_PATH"
  cd $base_dir
}

function build_mpc() {
  cd $build_dir
  mkdir mpc
  cd mpc
  wget ftp://ftp.gnu.org/gnu/mpc/mpc-"$mpc_version".tar.gz
  tar -xzvf mpc-"$mpc_version".tar.gz
  ln -s mpc-"$mpc_version" src
  mkdir bld
  cd bld
  ../src/configure --with-gmp="$compile_dir"/gmp \
                   --with-mpfr="$compile_dir"/mpfr \
                   --prefix="$compile_dir"/mpc
  make -j $jobs  # 16340 kB
  make install
  export LD_LIBRARY_PATH="$compile_dir"/mpc/lib:"$LD_LIBRARY_PATH"
  cd $base_dir
}

function build_gcc() {
  cd $build_dir
  mkdir gcc
  cd gcc
  wget http://www.netgull.com/gcc/releases/gcc-"$gcc_version"/gcc-"$gcc_version".tar.gz
  tar -xzvf gcc-"$gcc_version".tar.gz
  ln -s gcc-"$gcc_version" src
  mkdir bld
  cd bld
  ../src/configure --disable-multilib \
                   --with-gmp="$compile_dir"/gmp \
                   --with-mpfr="$compile_dir"/mpfr \
                   --with-mpc="$compile_dir"/mpc \
                   --prefix="$compile_dir"/gcc
  make -j $jobs  # 766268 kB
  make install
  export LD_LIBRARY_PATH="$compile_dir"/gcc/lib:"$LD_LIBRARY_PATH"
  export LD_LIBRARY_PATH="$compile_dir"/gcc/lib64:"$LD_LIBRARY_PATH"
  cd $base_dir
}

function pack_compilers() {
  cd $base_dir
  tar -pczvf $compilers_tar $compile_dir
}

function cleanup() {
  cd $base_dir
  ls | grep -v $compilers_tar | xargs rm -rf
}

# Compiler versions
gmp_version=6.1.0
mpfr_version=3.1.3
mpc_version=1.0.3
gcc_version=4.9.3

# Parallel jobs
jobs=8

# Tarball names
compile_tar=compile.tar.gz

# Directory names
base_dir="$PWD"
compile_dir="$base_dir"/compile
build_dir="$base_dir"/build
mkdir -p $compile_dir
mkdir -p $build_dir

# Build the compilers
build_gmp
build_mpfr
build_mpc
build_gcc

pack_compilers
cleanup
