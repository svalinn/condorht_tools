#!/bin/bash

# Run the FluDAG tests
function fludag_tests() {
  cd $test_dir
  git clone https://github.com/ljacobson64/DAGMC-tests
  cd DAGMC-tests/FluDAG
  bash get_files.bash
  bash run_all_smart.bash
  export datetime=`ls -t summaries/*.txt | head -1`
  export datetime=${datetime#$"summaries/summary_"}
  export datetime=${datetime%$".txt"}
}

# Pack results tarball
function pack_results() {
  export results_tarball=results_fludag_$datetime.tar.gz

  cd $test_dir/DAGMC-tests/FluDAG
  tar -czvf $results_tarball summaries */Results_native
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
  export test_dir=/home/$USER                    # Location to perform the FluDAG tests
  export install_dir=/home/$USER/opt             # Location to place binaries, libraries, etc.
  export copy_dir=/mnt/gluster/$USER             # Location where compiled software tarballs are found
  export results_dir=/mnt/gluster/$USER/results  # Location to place result tarballs
  mkdir -p $test_dir $install_dir $copy_dir $results_dir

  source ./versions.bash
  source ./common.bash
  set_compile_env
  set_dagmc_env
  get_compile
  get_dagmc
  export jobs=12

  fludag_tests
  pack_results
  cleanup
}

set -e
export args="$@"
export args=" "$args" "

main
