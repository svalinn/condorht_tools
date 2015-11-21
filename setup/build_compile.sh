#!/bin/bash

function build_gmp() {
  cd $build_dir
  mkdir gmp
  cd gmp
  gmp_tar=gmp-"$gmp_version".tar.bz2
  wget --spider http://proxy.chtc.wisc.edu/SQUID/"$username"/"$gmp_tar"
  if [ $? == 0 ]; then
    wget http://proxy.chtc.wisc.edu/SQUID/"$username"/"$gmp_tar"
  else
    wget https://gmplib.org/download/gmp/"$gmp_tar"
  fi
  tar -xjvf gmp-"$gmp_version".tar.bz2
  ln -s gmp-"$gmp_version" src
  mkdir bld
  cd bld
  ../src/configure --prefix="$compile_dir"/gmp
  make -j $jobs  # 29168 kB mem
  make install
  export LD_LIBRARY_PATH="$compile_dir"/gmp/lib:"$LD_LIBRARY_PATH"
  cd $base_dir
}

function build_mpfr() {
  cd $build_dir
  mkdir mpfr
  cd mpfr
  mpfr_tar=mpfr-"$mpfr_version".tar.gz
  wget --spider http://proxy.chtc.wisc.edu/SQUID/"$username"/"$mpfr_tar"
  if [ $? == 0 ]; then
    wget http://proxy.chtc.wisc.edu/SQUID/"$username"/"$mpfr_tar"
  else
    wget http://www.mpfr.org/mpfr-current/"$mpfr_tar"
  fi
  tar -xzvf mpfr-"$mpfr_version".tar.gz
  ln -s mpfr-"$mpfr_version" src
  mkdir bld
  cd bld
  ../src/configure --with-gmp="$compile_dir"/gmp \
                   --prefix="$compile_dir"/mpfr
  make -j $jobs  # 23744 kB mem
  make install
  export LD_LIBRARY_PATH="$compile_dir"/mpfr/lib:"$LD_LIBRARY_PATH"
  cd $base_dir
}

function build_mpc() {
  cd $build_dir
  mkdir mpc
  cd mpc
  mpc_tar=mpc-"$mpc_version".tar.gz
  wget --spider http://proxy.chtc.wisc.edu/SQUID/"$username"/"$mpc_tar"
  if [ $? == 0 ]; then
    wget http://proxy.chtc.wisc.edu/SQUID/"$username"/"$mpc_tar"
  else
    wget ftp://ftp.gnu.org/gnu/mpc/"$mpc_tar"
  fi
  tar -xzvf mpc-"$mpc_version".tar.gz
  ln -s mpc-"$mpc_version" src
  mkdir bld
  cd bld
  ../src/configure --with-gmp="$compile_dir"/gmp \
                   --with-mpfr="$compile_dir"/mpfr \
                   --prefix="$compile_dir"/mpc
  make -j $jobs  # 16340 kB mem
  make install
  export LD_LIBRARY_PATH="$compile_dir"/mpc/lib:"$LD_LIBRARY_PATH"
  cd $base_dir
}

function build_gcc() {
  cd $build_dir
  mkdir gcc
  cd gcc
  gcc_tar=gcc-"$gcc_version".tar.gz
  wget --spider http://proxy.chtc.wisc.edu/SQUID/"$username"/"$gcc_tar"
  if [ $? == 0 ]; then
    wget http://proxy.chtc.wisc.edu/SQUID/"$username"/"$gcc_tar"
  else
    wget http://www.netgull.com/gcc/releases/gcc-"$gcc_version"/"$gcc_tar"
  fi
  tar -xzvf gcc-"$gcc_version".tar.gz
  ln -s gcc-"$gcc_version" src
  mkdir bld
  cd bld
  ../src/configure --disable-multilib \
                   --with-gmp="$compile_dir"/gmp \
                   --with-mpfr="$compile_dir"/mpfr \
                   --with-mpc="$compile_dir"/mpc \
                   --prefix="$compile_dir"/gcc
  make -j $jobs  # 766268 kB mem, 4973.13 on /tmp, 4982.38 on $HOME
  make install
  export LD_LIBRARY_PATH="$compile_dir"/gcc/lib:"$LD_LIBRARY_PATH"
  export LD_LIBRARY_PATH="$compile_dir"/gcc/lib64:"$LD_LIBRARY_PATH"
  cd $base_dir
}

function pack_compile() {
  cd $base_dir
  tar -pczvf $compile_tar compile
  mv $compile_tar $copy_dir
}

function cleanup() {
  rm -rf $build_dir
  rm -rf $compile_dir
  cd $copy_dir
  ls | grep -v $compile_tar | xargs rm -rf
}

# Compiler versions
export gmp_version=6.1.0
export mpfr_version=3.1.3
export mpc_version=1.0.3
export gcc_version=4.9.3

# Parallel jobs
export jobs=8

# Username where tarballs are found (/squid/$username)
export username=ljjacobson

# Output tarball
export compile_tar=compile.tar.gz

# Directory names
export copy_dir=$PWD
export base_dir=$HOME
export compile_dir="$base_dir"/compile
export build_dir="$base_dir"/build
mkdir -p $compile_dir
mkdir -p $build_dir

# Build the compilers
build_gmp
build_mpfr
build_mpc
build_gcc

# Make the output tarball
pack_compile

# Delete unneeded stuff
cleanup
