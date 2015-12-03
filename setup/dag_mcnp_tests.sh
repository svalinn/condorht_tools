#!/bin/bash

function get_xs_data() {
  mkdir -p $DATAPATH
  cd $DATAPATH
  get_tar $xs_data_tar squid
  tar -xzvf $xs_data_tar --strip-components=1
  rm -f $xs_data_tar
}

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
  cd $copy_dir/DAGMC-tests
  tar -czvf $results_tar */Results
  mv $results_tar $copy_dir
  cd $copy_dir
}

# Delete unneeded stuff
function cleanup() {
  rm -rf $base_dir/*
  cd $copy_dir
  ls | grep -v $results_tar | xargs rm -rf
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
export xs_data_tar=mcnp_data.tar.gz
export results_tar=results.tar.gz

# Directory names
export copy_dir=$PWD
export base_dir=$HOME
export compile_dir=$base_dir/compile
export dagmc_dir=$base_dir/dagmc
export DATAPATH=$base_dir/mcnp_data

# Get compilers, DAGMC, and xs_data
get_compile
get_dagmc
get_xs_data

# Run the DAG-MCNP5 tests
dag_mcnp_tests
