#!/bin/bash

# Get cross section data
function get_xs_data() {
  xs_data_tarball=mcnp_data.tar.gz
  cd $DATAPATH
  if [ ! -e xsdir ]; then
    tar -xzvf $dist_dir/$xs_data_tarball --strip-components=1
  fi
}

# Run the DAGMC tests
function dagmc_tests() {
  cd $test_dir
  git clone https://github.com/ljacobson64/DAGMC-tests
  cd DAGMC-tests/DAG-MCNP5
  bash get_files.bash no_sat
  cd ../FluDAG
  bash get_files.bash
  bash run_all_smart.bash
  cd ../DAG-MCNP5
  bash run_all_smart.bash
  cd ..
  python write_summaries.py
  export datetime=`(cd summaries; ls summary_DAG-MCNP5_*.txt) | head -1`
  export datetime=${datetime#$"summary_DAG-MCNP5_"}
  export datetime=${datetime%$".txt"}
}

# Pack results tarball
function pack_results() {
  export results_tarball=results_$datetime.tar.gz

  cd $test_dir/DAGMC-tests
  tar -czvf $results_tarball summaries */*/Results
  mv $results_tarball $results_dir
}

# Delete unneeded stuff
function cleanup_tests() {
  cd $orig_dir
  rm -rf $orig_dir/* $test_dir/DAGMC-tests $build_dir $install_dir
}

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
packages=(gmp mpfr mpc gcc openmpi cmake hdf5 fluka)
for name in "${packages[@]}"; do
  eval version=\$"$name"_version
  echo Ensuring build of $name-$version ...
  ensure_build $name $version
done

# Re-build DAGMC
packages=(openmpi moab mcnp5 fluka dagmc)
for name in "${packages[@]:1}"; do
  eval version=\$"$name"_version
  echo Building $name-$version ...
  build_$name
done

get_xs_data
dagmc_tests
pack_results
cleanup_tests
