#!/bin/bash

# Figure out what dependencies are needed
function get_dependencies() {
  packages=()
  for arg in $args; do
    packages+=($arg)
  done
  if [[ " ${packages[@]} " =~ " pyne " ]]; then
    packages+=(gcc)
    packages+=(cmake)
    packages+=(python)
    packages+=(hdf5)
    packages+=(lapack)
    packages+=(setuptools)
    packages+=(cython)
    packages+=(numpy)
    packages+=(scipy)
    packages+=(pytables)
    packages+=(nose)
    packages+=(moab)
    packages+=(pytaps)
  fi
  if [[ " ${packages[@]} " =~ " dagmc " ]]; then
    packages+=(gcc)
    packages+=(cmake)
    packages+=(hdf5)
    packages+=(moab)
  fi
  if [[ " ${packages[@]} " =~ " fluka " ]]; then
    packages+=(gcc)
  fi
  if [[ " ${packages[@]} " =~ " geant4 " ]]; then
    packages+=(gcc)
    packages+=(cmake)
  fi
  if [[ " ${packages[@]} " =~ " mcnp5 " ]]; then
    : # no dependencies
  fi
  if [[ " ${packages[@]} " =~ " pytaps " ]]; then
    packages+=(gcc)
    packages+=(python)
    packages+=(hdf5)
    packages+=(lapack)
    packages+=(numpy)
    packages+=(moab)
  fi
  if [[ " ${packages[@]} " =~ " meshkit " ]]; then
    packages+=(gcc)
    packages+=(hdf5)
    packages+=(cgm)
    packages+=(moab)
  fi
  if [[ " ${packages[@]} " =~ " moab " ]]; then
    packages+=(gcc)
    packages+=(hdf5)
  fi
  if [[ " ${packages[@]} " =~ " cgm " ]]; then
    packages+=(gcc)
  fi
  if [[ " ${packages[@]} " =~ " cubit " ]]; then
    : # no dependencies
  fi
  if [[ " ${packages[@]} " =~ " nose " ]]; then
    packages+=(gcc)
    packages+=(python)
  fi
  if [[ " ${packages[@]} " =~ " pytables " ]]; then
    packages+=(gcc)
    packages+=(python)
    packages+=(hdf5)
    packages+=(lapack)
    packages+=(setuptools)
    packages+=(cython)
    packages+=(numpy)
    packages+=(numexpr)
  fi
  if [[ " ${packages[@]} " =~ " numexpr " ]]; then
    packages+=(gcc)
    packages+=(python)
    packages+=(numpy)
  fi
  if [[ " ${packages[@]} " =~ " scipy " ]]; then
    packages+=(gcc)
    packages+=(python)
    packages+=(lapack)
    packages+=(cython)
    packages+=(numpy)
  fi
  if [[ " ${packages[@]} " =~ " numpy " ]]; then
    packages+=(gcc)
    packages+=(python)
    packages+=(lapack)
    packages+=(cython)
  fi
  if [[ " ${packages[@]} " =~ " cython " ]]; then
    packages+=(gcc)
    packages+=(python)
  fi
  if [[ " ${packages[@]} " =~ " setuptools " ]]; then
    packages+=(gcc)
    packages+=(python)
  fi
  if [[ " ${packages[@]} " =~ " hdf5 " ]]; then
    packages+=(gcc)
  fi
  if [[ " ${packages[@]} " =~ " python " ]]; then
    packages+=(gcc)
  fi
  if [[ " ${packages[@]} " =~ " cmake " ]]; then
    packages+=(gcc)
  fi
  if [[ " ${packages[@]} " =~ " openmpi " ]]; then
    packages+=(gcc)
  fi
  if [[ " ${packages[@]} " =~ " gcc " ]]; then
    packages+=(mpc)
  fi
  if [[ " ${packages[@]} " =~ " mpc " ]]; then
    packages+=(mpfr)
  fi
  if [[ " ${packages[@]} " =~ " mpfr " ]]; then
    packages+=(gmp)
  fi
  if [[ " ${packages[@]} " =~ " gmp " ]]; then
    : # no dependencies
  fi
  if [[ " ${packages[@]} " =~ " boost " ]]; then
    : # no dependencies
  fi
  if [[ " ${packages[@]} " =~ " mpfr " ]]; then
    packages+=(gcc)
  fi
  if [[ " ${packages[@]} " =~ " sigcpp " ]]; then
    packages+=(gcc)
    packages+=(mpc)
    packages+=(gmp)
    packages+=(mpfr)
  fi
  if [[ " ${packages[@]} " =~ " xml2 " ]]; then
    packages+=(gcc)
  fi
  if [[ " ${packages[@]} " =~ " xmlpp " ]]; then
    packages+=(gcc)
    packages+=(mpc)
    packages+=(mpfr)
    packages+=(gmp)
  fi
  # Put the dependencies in the correct build order
  all_packages=" gmp mpfr mpc gcc openmpi cmake python hdf5 lapack
                 setuptools cython numpy scipy numexpr pytables nose
                 cubit cgm moab meshkit pytaps mcnp5 geant4 fluka dagmc pyne
                 boosti mpfr sigcpp xml2 xmlpp "
  packages_ordered=()
  for package in $all_packages; do
    if [[ " ${packages[@]} " =~ " ${package} " ]]; then
      packages_ordered+=($package)
    fi
  done
  packages=("${packages_ordered[@]}")
}

# Delete unneeded stuff
function cleanup_build() {
  cd $orig_dir
  rm -rf $orig_dir/* $build_dir $install_dir
}

set -e
export args="$@"
export args=" "$args" "

source ./common.bash
source ./build_funcs.bash
set_dirs
set_versions
set_env
export make_install_tarballs=true
export jobs=12

# Figure out which packages need to be built
get_dependencies

# Cleanup directories
rm -rf $build_dir $install_dir
mkdir -p $dist_dir $build_dir $install_dir $copy_dir $DATAPATH

# Build the packages
for name in "${packages[@]}"; do
  eval version=\$"$name"_version
  echo Ensuring build of $name-$version ...
  ensure_build $name
done

# Cleanup the build
cleanup_build
