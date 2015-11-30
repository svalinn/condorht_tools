#!/bin/bash

function dag_mcnp_tests() {
  cd $copy_dir
  git clone https://github.com/ljacobson64/DAGMC-tests
  cd DAGMC-tests
  bash get_files.bash
  declare -a suites=(DAGMC Meshtally Regression VALIDATION_CRITICALITY \
                     VALIDATION_SHIELDING VERIFICATION_KEFF)
  for suite in "${suites[@]}"; do
    cd $suite
    python run_tests.py -s -j $jobs
    python run_tests.py -r -j $jobs
    cd ..
  done
}

# Pack results tarball
function pack_results() {
  # put stuff here
}

# Delete unneeded stuff
function cleanup() {
  rm -rf $compile_dir
  rm -rf $dagmc_dir
  cd $copy_dir
  # put stuff here
}

set -e
export args="$@"
export args=" "$args" "

# Common functions
source ./common.sh

# Parallel jobs
export jobs=12

# Username where tarballs are found (/squid/$username)
export username=$1

# Tarball names
export compile_tar=compile.tar.gz
export dagmc_tar=dagmc.tar.gz

# Directory names
export copy_dir=$PWD
export base_dir=$HOME
export compile_dir=$base_dir/compile
export dagmc_dir=$base_dir/dagmc

# Get compilers, and DAGMC
get_compile
get_dagmc
