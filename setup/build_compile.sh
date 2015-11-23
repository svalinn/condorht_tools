#!/bin/bash

# Build GMP
function build_gmp() {
  cd $build_dir
  mkdir -p gmp/bld
  cd gmp
  gmp_tar=gmp-$gmp_version.tar.bz2
  wget --spider http://proxy.chtc.wisc.edu/SQUID/$username/$gmp_tar
  if [ $? == 0 ]; then
    wget http://proxy.chtc.wisc.edu/SQUID/$username/$gmp_tar
  else
    wget https://gmplib.org/download/gmp/$gmp_tar
  fi
  tar -xjvf $gmp_tar
  ln -s gmp-$gmp_version src
  cd bld
  config_string=
  config_string+=" "--prefix=$compile_dir/gmp
  ../src/configure $config_string
  make -j $jobs  # j=12: 0:17.26 wall time, 29168 kB mem
  make install
  export LD_LIBRARY_PATH=$compile_dir/gmp/lib:$LD_LIBRARY_PATH
  cd $base_dir
}

# Build MPFR
function build_mpfr() {
  cd $build_dir
  mkdir -p mpfr/bld
  cd mpfr
  mpfr_tar=mpfr-$mpfr_version.tar.gz
  wget --spider http://proxy.chtc.wisc.edu/SQUID/$username/$mpfr_tar
  if [ $? == 0 ]; then
    wget http://proxy.chtc.wisc.edu/SQUID/$username/$mpfr_tar
  else
    wget http://www.mpfr.org/mpfr-current/$mpfr_tar
  fi
  tar -xzvf $mpfr_tar
  ln -s mpfr-$mpfr_version src
  cd bld
  config_string=
  config_string+=" "--with-gmp=$compile_dir/gmp
  config_string+=" "--prefix=$compile_dir/mpfr
  ../src/configure $config_string
  make -j $jobs  # j=12: 0:07.28 wall time, 23744 kB mem
  make install
  export LD_LIBRARY_PATH=$compile_dir/mpfr/lib:$LD_LIBRARY_PATH
  cd $base_dir
}

# Build MPC
function build_mpc() {
  cd $build_dir
  mkdir -p mpc/bld
  cd mpc
  mpc_tar=mpc-$mpc_version.tar.gz
  wget --spider http://proxy.chtc.wisc.edu/SQUID/$username/$mpc_tar
  if [ $? == 0 ]; then
    wget http://proxy.chtc.wisc.edu/SQUID/$username/$mpc_tar
  else
    wget ftp://ftp.gnu.org/gnu/mpc/$mpc_tar
  fi
  tar -xzvf $mpc_tar
  ln -s mpc-$mpc_version src
  cd bld
  config_string=
  config_string+=" "--with-gmp=$compile_dir/gmp
  config_string+=" "--with-mpfr=$compile_dir/mpfr
  config_string+=" "--prefix=$compile_dir/mpc
  ../src/configure $config_string
  make -j $jobs  # j=12: 0:02.81 wall time, 16340 kB mem
  make install
  export LD_LIBRARY_PATH=$compile_dir/mpc/lib:$LD_LIBRARY_PATH
  cd $base_dir
}

# Build GCC
function build_gcc() {
  cd $build_dir
  mkdir -p gcc/bld
  cd gcc
  gcc_tar=gcc-$gcc_version.tar.gz
  wget --spider http://proxy.chtc.wisc.edu/SQUID/$username/$gcc_tar
  if [ $? == 0 ]; then
    wget http://proxy.chtc.wisc.edu/SQUID/$username/$gcc_tar
  else
    wget http://www.netgull.com/gcc/releases/gcc-$gcc_version/$gcc_tar
  fi
  tar -xzvf $gcc_tar
  ln -s gcc-$gcc_version src
  cd bld
  config_string=
  config_string+=" "--with-gmp=$compile_dir/gmp
  config_string+=" "--with-mpfr=$compile_dir/mpfr
  config_string+=" "--with-mpc=$compile_dir/mpc
  config_string+=" "--prefix=$compile_dir/gcc
  ../src/configure $config_string
  make -j $jobs  # j=12: 18:35.61 wall time, 766024 kB mem
  make install
  export LD_LIBRARY_PATH=$compile_dir/gcc/lib:$LD_LIBRARY_PATH
  export LD_LIBRARY_PATH=$compile_dir/gcc/lib64:$LD_LIBRARY_PATH
  cd $base_dir
}

# Build OpenMPI
function build_openmpi() {
  cd $build_dir
  mkdir -p openmpi/bld
  cd openmpi
  openmpi_tar=openmpi-$openmpi_version.tar.gz
  wget --spider http://proxy.chtc.wisc.edu/SQUID/$username/$openmpi_tar
  if [ $? == 0 ]; then
    wget http://proxy.chtc.wisc.edu/SQUID/$username/$openmpi_tar
  else
    wget http://www.open-mpi.org/software/ompi/v1.10/downloads/$openmpi_tar
  fi
  tar -xzvf $openmpi_tar
  ln -s openmpi-$openmpi_version src
  cd bld
  config_string=
  config_string+=" "--prefix=$compile_dir/openmpi
  ../src/configure $config_string
  make -j $jobs  # j=12: 3:26.41 wall time, 311132 kB mem
  make install
  export PATH=$compile_dir/openmpi/bin:$PATH
  export LD_LIBRARY_PATH=$compile_dir/openmpi/lib:$LD_LIBRARY_PATH
  cd $base_dir
}

# Pack compiler tarball
function pack_compile() {
  cd $base_dir
  tar -pczvf $compile_tar compile
  mv $compile_tar $copy_dir
}

# Delete unneeded stuff
function cleanup() {
  rm -rf $compile_dir
  rm -rf $build_dir
  cd $copy_dir
  ls | grep -v $compile_tar | xargs rm -rf
}

set -e
export args="$@"
export args=" "$args" "

# Compiler versions
export gmp_version=6.1.0
export mpfr_version=3.1.3
export mpc_version=1.0.3
export gcc_version=4.9.3
export openmpi_version=1.10.1

# Parallel jobs
export jobs=12

# Username where tarballs are found (/squid/$username)
export username=$1

# Output compiler tarball
export compile_tar=compile.tar.gz

# Directory names
export copy_dir=$PWD
export base_dir=$HOME
export compile_dir=$base_dir/compile
export build_dir=$base_dir/build
mkdir -p $compile_dir
mkdir -p $build_dir

# Build compilers
build_gmp
build_mpfr
build_mpc
build_gcc
if [[ "$args" == *" mpi "* ]]; then
  build_openmpi
fi

# Pack output compiler tarball
pack_compile

# Delete unneeded stuff
cleanup
