#!/bin/bash

# Get cross section data
function get_xs_data() {
  xs_data_tar=mcnp_data.tar.gz

  mkdir -p $DATAPATH
  cd $DATAPATH
  if [ ! -a xsdir ]; then
    tar -xzvf $tar_dir/$xs_data_tar --strip-components=1
  fi
}

# Run the DAG-MCNP tests
function dag_mcnp_tests() {
  cd $copy_dir
  git clone https://github.com/ljacobson64/DAGMC-tests
  cd DAGMC-tests
  bash get_files.bash

  # - Run longer tests in MPI mode
  # - Order for runs is from longest to shortest
  # - Runs with PTRAC must be run in serial
  # - Runs with dependencies on other runs must come after those runs

  cd DAGMC
  mpi_runs="13 09 15 14"
  python run_tests.py $mpi_runs -s -r -j $jobs --mpi
  ser_runs="05 06 01 08 07 11 10 02 03 04 12"
  python run_tests.py $ser_runs -s -r -j $jobs

  cd ../Meshtally
  python run_tests.py -s -r -j $jobs --mpi

  cd ../Regression
  mpi_runs="35 37"
  python run_tests.py $mpi_runs -s -r -j $jobs --mpi
  ser_runs="36 02 41 31 42 04 39 98 99 06 90 93 33 95 30 01 07 64 12 03 68 20 32 21 23 10 28 19 9 94 47 61 63 65 66 67 86 62"
  python run_tests.py $ser_runs -s -r -j $jobs
  ser_runs="22 08 29 34 26 27"  # dependencies
  python run_tests.py $ser_runs -s -r -j $jobs

  cd ../VALIDATION_CRITICALITY
  python run_tests.py -s -r -j $jobs --mpi

  cd ../VALIDATION_SHIELDING
  python run_tests.py -s -r -j $jobs --mpi

  cd ../VERIFICATION_KEFF
  ser_runs="10 23 09"  # ptrac
  mpi_runs="01 02 03 04 05 06 07 08 09 "$(seq 10 75)
  for s_run in $ser_runs; do mpi_runs=${mpi_runs/$s_run}; done
  python run_tests.py $mpi_runs -s -r -j $jobs --mpi
  python run_tests.py $ser_runs -s -r -j $jobs

  cd $copy_dir
}

# Pack results tarball
function pack_results() {
  results_tar=results.tar.gz

  cd $copy_dir/DAGMC-tests
  tar -czvf $results_tar */Results
  cp $results_tar /mnt/gluster/$USER
  mv $results_tar $copy_dir
  cd $copy_dir
}

# Delete unneeded stuff
function cleanup() {
  cd $copy_dir
  ls | grep -v $results_tar | xargs rm -rf
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
export dagmc_dir=$base_dir/dagmc
export DATAPATH=$base_dir/mcnp_data

# Setup environment variables and get xs_data
setup_compile_env
setup_dagmc_env
get_xs_data

# Run the DAG-MCNP5 tests
dag_mcnp_tests

# Create a results tarball
pack_results

# Delete unneeded stuff
cleanup
