#!/bin/bash

# Get cross section data
function get_xs_data() {
  xs_data_tarball=mcnp_data.tar.gz
  cd $DATAPATH
  if [ ! -e xsdir ]; then
    tar -xzvf $dist_dir/$xs_data_tarball --strip-components=1
  fi
}

# Run the DAG-MCNP tests
function dagmcnp5_tests() {
  cd $test_dir
  git clone https://github.com/ljacobson64/DAGMC-tests
  cd DAGMC-tests/DAG-MCNP5
  bash get_files.bash
  bash run_all_smart.bash
  export datetime=`ls -t summaries/*.txt | head -1`
  export datetime=${datetime#$"summaries/summary_"}
  export datetime=${datetime%$".txt"}
}

# Pack results tarball
function pack_results() {
  export results_tarball=results_dagmcnp5_$datetime.tar.gz

  cd $test_dir/DAGMC-tests/DAG-MCNP5
  tar -czvf $results_tarball summaries */Results
  cp $results_tarball $results_dir
  mv $results_tarball $orig_dir
}

# Delete unneeded stuff
function cleanup() {
  rm -rf $test_dir/DAGMC-tests $install_dir
}

function main() {
  # Directory names
  export orig_dir=$PWD
  export test_dir=/home/$USER                    # Location to perform the DAG-MCNP tests
  export install_dir=/home/$USER/opt             # Location to place binaries, libraries, etc.
  export copy_dir=/mnt/gluster/$USER             # Location where compiled software tarballs are found
  export results_dir=/mnt/gluster/$USER/results  # Location to place result tarballs
  export DATAPATH=/mnt/gluster/$USER/mcnp_data   # Location of MCNP data
  mkdir -p $test_dir $install_dir $copy_dir $results_dir $DATAPATH

  source ./versions.bash
  source ./common.bash
  set_compile_env
  set_dagmc_env
  get_compile
  get_dagmc
  export jobs=12

  get_xs_data
  dagmcnp5_tests
  pack_results
  cleanup
}

set -e
export args="$@"
export args=" "$args" "

main
