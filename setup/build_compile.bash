#!/bin/bash

# Build GMP
function build_gmp() {
  gmp_version=6.1.0
  gmp_tar=gmp-$gmp_version.tar.bz2
  gmp_url=https://gmplib.org/download/gmp/$gmp_tar

  cd $build_dir
  mkdir -p gmp/bld
  cd gmp
  if [ ! -f $tar_dir/$gmp_tar ]; then
    wget $gmp_url -P $tar_dir
  fi
  tar -xjvf $tar_dir/$gmp_tar
  ln -s gmp-$gmp_version src
  cd bld
  config_string=
  config_string+=" "--prefix=$compile_dir/gmp
  ../src/configure $config_string
  make -j $jobs
  make install
  export LD_LIBRARY_PATH=$compile_dir/gmp/lib:$LD_LIBRARY_PATH
  cd $base_dir
}

# Build MPFR
function build_mpfr() {
  mpfr_version=3.1.3
  mpfr_tar=mpfr-$mpfr_version.tar.gz
  mpfr_url=http://www.mpfr.org/mpfr-current/$mpfr_tar

  cd $build_dir
  mkdir -p mpfr/bld
  cd mpfr
  if [ ! -f $tar_dir/$mpfr_tar ]; then
    wget $mpfr_url -P $tar_dir
  fi
  tar -xzvf $tar_dir/$mpfr_tar
  ln -s mpfr-$mpfr_version src
  cd bld
  config_string=
  config_string+=" "--with-gmp=$compile_dir/gmp
  config_string+=" "--prefix=$compile_dir/mpfr
  ../src/configure $config_string
  make -j $jobs
  make install
  export LD_LIBRARY_PATH=$compile_dir/mpfr/lib:$LD_LIBRARY_PATH
  cd $base_dir
}

# Build MPC
function build_mpc() {
  mpc_version=1.0.3
  mpc_tar=mpc-$mpc_version.tar.gz
  mpc_url=ftp://ftp.gnu.org/gnu/mpc/$mpc_tar

  cd $build_dir
  mkdir -p mpc/bld
  cd mpc
  if [ ! -f $tar_dir/$mpc_tar ]; then
    wget $mpc_url -P $tar_dir
  fi
  tar -xzvf $tar_dir/$mpc_tar
  ln -s mpc-$mpc_version src
  cd bld
  config_string=
  config_string+=" "--with-gmp=$compile_dir/gmp
  config_string+=" "--with-mpfr=$compile_dir/mpfr
  config_string+=" "--prefix=$compile_dir/mpc
  ../src/configure $config_string
  make -j $jobs
  make install
  export LD_LIBRARY_PATH=$compile_dir/mpc/lib:$LD_LIBRARY_PATH
  cd $base_dir
}

# Build GCC
function build_gcc() {
  gcc_version=4.9.3
  gcc_tar=gcc-$gcc_version.tar.gz
  gcc_url=http://www.netgull.com/gcc/releases/gcc-$gcc_version/$gcc_tar

  cd $build_dir
  mkdir -p gcc/bld
  cd gcc
  if [ ! -f $tar_dir/$gcc_tar ]; then
    wget $gcc_url -P $tar_dir
  fi
  tar -xzvf $tar_dir/$gcc_tar
  ln -s gcc-$gcc_version src
  cd bld
  config_string=
  config_string+=" "--with-gmp=$compile_dir/gmp
  config_string+=" "--with-mpfr=$compile_dir/mpfr
  config_string+=" "--with-mpc=$compile_dir/mpc
  config_string+=" "--prefix=$compile_dir/gcc
  ../src/configure $config_string
  make -j $jobs
  make install
  export PATH=$compile_dir/gcc/bin:$PATH
  export LD_LIBRARY_PATH=$compile_dir/gcc/lib:$LD_LIBRARY_PATH
  export LD_LIBRARY_PATH=$compile_dir/gcc/lib64:$LD_LIBRARY_PATH
  cd $base_dir
}

# Build OpenMPI
function build_openmpi() {
  openmpi_version=1.10.1
  openmpi_tar=openmpi-$openmpi_version.tar.gz
  openmpi_url=http://www.open-mpi.org/software/ompi/v1.10/downloads/$openmpi_tar

  cd $build_dir
  mkdir -p openmpi/bld
  cd openmpi
  if [ ! -f $tar_dir/$openmpi_tar ]; then
    wget $openmpi_url -P $tar_dir
  fi
  tar -xzvf $tar_dir/$openmpi_tar
  ln -s openmpi-$openmpi_version src
  cd bld
  config_string=
  config_string+=" "--prefix=$compile_dir/openmpi
  ../src/configure $config_string
  make -j $jobs
  make install
  export PATH=$compile_dir/openmpi/bin:$PATH
  export LD_LIBRARY_PATH=$compile_dir/openmpi/lib:$LD_LIBRARY_PATH
  cd $base_dir
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
export build_dir=$copy_dir/build
mkdir -p $tar_dir $compile_dir $build_dir

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
