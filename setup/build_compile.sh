#!/bin/bash

# Get tarball
function get_tar() {
  tarball=$1
  shift

  while test ${#} -gt 0; do
    url=$1
    if [ "$url" == "squid" ]; then
      url=http://proxy.chtc.wisc.edu/SQUID/$username
    fi
    wget --spider $url/$tarball
    if [ $? == 0 ]; then
      wget $url/$tarball
      return
    fi
    shift
  done

  echo $tarball not found
}

function build_package() {
  name="$1"
  tarball="$2"
  tar_type="$3"
  tar_url="$4"
  folder="$5"
  config_str="$6"
  path_dirs="$7"
  ldlpath_dirs="$8"

  cd $build_dir
  mkdir -p $name/bld
  cd $name
  get_tar $tarball squid $tar_url
  tar -x"$tar_type"vf $tarball
  ln -s $folder src
  cd bld
  ../src/configure $config_str
  make -j $jobs
  make install
  cd $base_dir

  for path_dir in $path_dirs; do
    export PATH=$compile_dir/$name/$path_dir:$PATH
  done
  for ldlpath_dir in $ldlpath_dirs; do
    export LD_LIBRARY_PATH=$compile_dir/$name/$ldlpath_dir:$LD_LIBRARY_PATH
  done
}

# Build GMP
function build_gmp() {
  version=$1
  name=gmp
  tarball=$name-$version.tar.bz2
  tar_type=j
  tar_url=https://gmplib.org/download/gmp
  folder=$name-$version

  config_str=
  config_str+=" "--prefix=$compile_dir/$name

  path_dirs=
  ldlpath_dirs="lib"

  build_package "$name" "$tarball" "$tar_type" "$tar_url" "$folder" \
                "$config_str" "$path_dirs" "$ldlpath_dirs"
}

# Build MPFR
function build_mpfr() {
  version=$1
  name=mpfr
  tarball=$name-$version.tar.gz
  tar_type=z
  tar_url=http://www.mpfr.org/mpfr-current
  folder=$name-$version

  config_str=
  config_str+=" "--with-gmp=$compile_dir/gmp
  config_str+=" "--prefix=$compile_dir/$name

  path_dirs=
  ldlpath_dirs="lib"

  build_package "$name" "$tarball" "$tar_type" "$tar_url" "$folder" \
                "$config_str" "$path_dirs" "$ldlpath_dirs"
}

# Build MPC
function build_mpc() {
  version=$1
  name=mpc
  tarball=$name-$version.tar.gz
  tar_type=z
  tar_url=ftp://ftp.gnu.org/gnu/mpc
  folder=$name-$version

  config_str=
  config_str+=" "--with-gmp=$compile_dir/gmp
  config_str+=" "--with-mpfr=$compile_dir/mpfr
  config_str+=" "--prefix=$compile_dir/$name

  path_dirs=
  ldlpath_dirs="lib"

  build_package "$name" "$tarball" "$tar_type" "$tar_url" "$folder" \
                "$config_str" "$path_dirs" "$ldlpath_dirs"
}

# Build GCC
function build_gcc() {
  version=$1
  name=gcc
  tarball=$name-$version.tar.gz
  tar_type=z
  tar_url=http://www.netgull.com/gcc/releases/gcc-$gcc_version
  folder=$name-$version

  config_str=
  config_str+=" "--with-gmp=$compile_dir/gmp
  config_str+=" "--with-mpfr=$compile_dir/mpfr
  config_str+=" "--with-mpc=$compile_dir/mpc
  config_str+=" "--prefix=$compile_dir/$name

  path_dirs="bin"
  ldlpath_dirs="lib lib64"

  build_package "$name" "$tarball" "$tar_type" "$tar_url" "$folder" \
                "$config_str" "$path_dirs" "$ldlpath_dirs"
}

# Build OpenMPI
function build_openmpi() {
  version=$1
  name=openmpi
  tarball=$name-$version.tar.gz
  tar_type=z
  tar_url=http://www.open-mpi.org/software/ompi/v1.10/downloads
  folder=$name-$version

  config_str=
  config_str+=" "--prefix=$compile_dir/$name

  path_dirs="bin"
  ldlpath_dirs="lib"

  build_package "$name" "$tarball" "$tar_type" "$tar_url" "$folder" \
                "$config_str" "$path_dirs" "$ldlpath_dirs"
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
args="$@"
args=" "$args" "

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
build_gmp 6.1.0
build_mpfr 3.1.3
build_mpc 1.0.3
build_gcc 4.9.3
if [[ "$args" == *" mpi "* ]]; then
  build_openmpi 1.10.1
fi

# Pack output compiler tarball
pack_compile

# Delete unneeded stuff
cleanup
