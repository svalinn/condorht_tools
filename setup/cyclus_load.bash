#!/bin/bash

set -e
export args="$@"
export args=" "$args" "

source ./common.bash
source ./build_funcs.bash
set_dirs
set_versions
set_env
export make_install_tarballs=false
export jobs=12

# Cleanup directories
rm -rf $build_dir $install_dir
mkdir -p $dist_dir $build_dir $install_dir $copy_dir $DATAPATH

# Make sure all the dependencies are built
packages=(python gcc mpc mpfr gmp hdf5 boost Cbc sigcpp sqlite xml2 pcre glib glibmm xmlpp)
for name in "${packages[@]}"; do
  eval version=\$"$name"_version
  echo Ensuring build of $name-$version ...
  ensure_build $name $version
done

# recover cyclus and cycamore
packages=(cyclus)
for name in "${packages[@]}"; do
  eval version=\$"$name"_version
  echo Ensuring build of $name-$version ...
  ensure_build $name $version
done


