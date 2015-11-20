#!/bin/bash

function build_gcc() {
  cd compile
  wget http://www.netgull.com/gcc/releases/gcc-4.9.3/gcc-4.9.3.tar.gz
  tar -zxf gcc-4.9.3.tar.gz
  mv gcc-4.9.3 gcc
  cd gcc
  root=$PWD
  mkdir bld
  cd bld
  ../configure --disable-multilib \
               --with-gmp=$compile_dir/gmp \
               --with-mpfr=$compile_dir/mpfr \
               --with-mpc=$compile_dir/mpc \
               --prefix=$root
  make
  make install
  export LD_LIBRARY_PATH=$root/lib:$LD_LIBRARY_PATH
  export LD_LIBRARY_PATH=$root/lib64:$LD_LIBRARY_PATH
  cd ../../..
}

function build_mpfr() {
  cd compile
  wget http://www.mpfr.org/mpfr-current/mpfr-3.1.3.tar.gz
  tar -zxf mpfr-3.1.3.tar.gz
  mv mpfr-3.1.3 mpfr
  cd mpfr
  root=$PWD
  mkdir bld
  cd bld
  ../configure --with-gmp=$compile_dir/gmp --prefix=$root
  make
  make install
  export LD_LIBRARY_PATH=$root/lib:$LD_LIBRARY_PATH
  cd ../../..
}

function build_mpc() {
  cd compile
  wget ftp://ftp.gnu.org/gnu/mpc/mpc-1.0.3.tar.gz
  tar -zxf mpc-1.0.3.tar.gz
  mv mpc-1.0.3 mpc
  cd mpc
  root=$PWD
  mkdir bld
  cd bld
  ../configure --with-gmp=$compile_dir/gmp --with-mpfr=$compile_dir/mpfr --prefix=$root
  make
  make install
  export LD_LIBRARY_PATH=$root/lib:$LD_LIBRARY_PATH
  cd ../../..
}

function build_gmp() {
  cd compile
  wget https://gmplib.org/download/gmp/gmp-6.0.0a.tar.bz2
  tar -jxf gmp-6.0.0a.tar.bz2
  mv gmp-6.0.0 gmp
  cd gmp
  root=$PWD
  mkdir bld
  cd bld
  ../configure --prefix=$root
  make
  make install
  export LD_LIBRARY_PATH=$root/lib:$LD_LIBRARY_PATH
  cd ../../..
}


function pack_libs() {
  tar -pczf compile.tar.gz compile/gcc/include \
                           compile/gcc/lib \
                           compile/gcc/include \
                           compile/gcc/lib64 \
                           compile/gcc/bin \
                           compile/gmp/include \
                           compile/gmp/lib \
                           compile/mpc/include \
                           compile/mpc/lib \
                           compile/mpfr/include \
                           compile/mpfr/lib
}

function cleanup() {
  ls | grep -v compile.tar.gz | xargs rm -rf
}

owd=$PWD
mkdir compile
compile_dir=$owd"/compile"

build_gmp
build_mpfr  # needs gmp
build_mpc   # needs gmp and mpfr
build_gcc

pack_libs
cleanup
