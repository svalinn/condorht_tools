#!/bin/bash

# Get cross section data
function get_xs_data() {
  xs_data_tar=mcnp_data.tar.gz
  mkdir -p $DATAPATH
  cd $DATAPATH
  if [ ! -e xsdir ]; then
    tar -xzvf $dist_dir/$xs_data_tar --strip-components=1
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

  if [[ "$args" == *" DAGMC "* ]]; then
    cd DAGMC
    mpi_runs="13 09 15 14"
    python run_tests.py $mpi_runs -s -r -j $jobs --mpi
    ser_runs="05 06 01 08 07 11 10 02 03 04 12"
    python run_tests.py $ser_runs -s -r -j $jobs
    cd ..
  fi

  if [[ "$args" == *" Meshtally "* ]]; then
    cd Meshtally
    python run_tests.py -s -r -j $jobs --mpi
    cd ..
  fi

  if [[ "$args" == *" Regression "* ]]; then
    cd Regression
    mpi_runs="35 37"
    python run_tests.py $mpi_runs -s -r -j $jobs --mpi
    ser_runs="36 02 41 31 42 04 39 98 99 06 90 93 33 95 30 01 07 64 12 03 68 20 32 21 23 10 28 19 09 94 47 61 63 65 66 67 86 62"
    python run_tests.py $ser_runs -s -r -j $jobs
    ser_runs="22 08 29 34 26 27"  # dependencies
    python run_tests.py $ser_runs -s -r -j $jobs
    cd ..
  fi

  if [[ "$args" == *" VALIDATION_CRITICALITY "* ]]; then
    cd VALIDATION_CRITICALITY
    python run_tests.py -s -r -j $jobs --mpi
    cd ..
  fi

  if [[ "$args" == *" VALIDATION_SHIELDING "* ]]; then
    cd VALIDATION_SHIELDING
    python run_tests.py -s -r -j $jobs --mpi
    cd ..
  fi

  if [[ "$args" == *" VERIFICATION_KEFF "* ]]; then
    cd VERIFICATION_KEFF
    ser_runs="10 23 09"  # ptrac
    mpi_runs="01 02 03 04 05 06 07 08 09 "$(seq 10 75)
    for s_run in $ser_runs; do mpi_runs=${mpi_runs/$s_run}; done
    python run_tests.py $mpi_runs -s -r -j $jobs --mpi
    python run_tests.py $ser_runs -s -r -j $jobs
    cd ..
  fi

  python write_summaries.py
  export datetime=`ls -t summaries/*.txt | head -1`
  export datetime=${datetime#$"summaries/summary_"}
  export datetime=${datetime%$".txt"}

  cd $copy_dir
}

# Pack results tarball
function pack_results() {
  export results_tar=results_$datetime.tar.gz
  cd $copy_dir/DAGMC-tests
  tar -czvf $results_tar summaries */Results
  mkdir -p $results_dir
  cp $results_tar $results_dir
  mv $results_tar $copy_dir
  cd $copy_dir
}

# Delete unneeded stuff
function cleanup() {
  cd $copy_dir
  ls | grep -v $results_tar | xargs rm -rf
}

function main() {
  export copy_dir=$PWD                  # Location of tarball to be copied back to submit node
  export base_dir=/mnt/gluster/$USER
  export dist_dir=$base_dir/dist        # Location where software tarballs are found
  export install_dir=$base_dir/opt      # Location to place binaries, libraries, etc.
  export build_dir=$copy_dir/build      # Location to perform builds
  export DATAPATH=$base_dir/mcnp_data   # Location of MCNP data
  export results_dir=$base_dir/results  # Location where results tarball will be placed
  mkdir -p $dist_dir $install_dir $build_dir $results_dir

  source ./versions.bash                # Get software versions
  source ./common.bash                  # Common functions
  setup_env                             # Setup environment variables
  export jobs=12                        # Parallel jobs

  get_xs_data                           # Get cross section data
  dag_mcnp_tests                        # Run the DAG-MCNP tests
  pack_results                          # Pack results tarball
  cleanup                               # Delete unneeded stuff
}

set -e
export args="$@"
export args=" "$args" "

main #1> $copy_dir/_condor_stdout 2> $copy_dir/_condor_stderr
