#!/bin/bash

function get_git_lfs() {
  cd $base_dir
  git_lfs_version=1.1.0
  git_lfs_tar=git-lfs-linux-amd64-$git_lfs_version.tar.gz
  get_tar $git_lfs_tar squid https://github.com/github/git-lfs/releases/download/v$git_lfs_version
  tar -xzvf $git_lfs_tar
  mv git-lfs-$git_lfs_version git-lfs
  export PATH=$base_dir/git-lfs:$PATH
}

function dag_mcnp_tests() {
  cd $copy_dir
  git clone https://github.com/ljacobson64/DAGMC-tests
  cd DAGMC-tests
  declare -a suites=(DAGMC Meshtally Regression VALIDATION_CRITICALITY \
                     VALIDATION_SHIELDING VERIFICATION_KEFF)
  for suite in "${suites[@]}"; do
    cd $suite
    python run_tests.py -s -j $jobs
    python run_tests.py -d -j $jobs
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

# Get git-lfs, compilers, and DAGMC
get_git_lfs
get_compile
get_dagmc
