#!/bin/bash

check_inc=1   # Minutes to wait between checks to see if the tests havs finished
tests_inc=30  # Minutes to wait between re-running the tests

check_inc=$(( $check_inc * 60 ))
tests_inc=$(( $tests_inc * 60 ))

CONDOR=ljjacobson@submit-3.chtc.wisc.edu
results_dir=/groupspace/cnerg/users/jacobson/DAGMC_condor_results
temp_dir=$results_dir/temp

mkdir -p $results_dir
mkdir -p $temp_dir

while true; do
  start_epoch=$(date +%s)

  # Submit the tests on Condor
  ssh $CONDOR 'cd condorht_tools/setup && condor_submit dag_mcnp_tests.sub'

  # Check periodically to see if the tests have finished
  num_running=1
  while [[ $num_running > 0 ]]; do
    sleep $check_inc
    num_running=$(ssh $CONDOR 'condor_q $USER | grep $USER | grep dag_mcnp_tests.bas | wc -l')
  done

  # Bring back the results tarball
  cd $temp_dir
  scp $CONDOR:condorht_tools/setup/results_*.tar.gz .
  ssh $CONDOR 'mv condorht_tools/setup/*.tar.gz results'
  tarball=`echo results_*.tar.gz`
  folder="${tarball:8:${#tarball}-15}"
  tests=`tar --wildcards -tf $tarball */diff_summary | sed 's/\/.*//'`
  mv $tarball $results_dir

  # Extract the diff information
  cd $results_dir
  mkdir $folder
  for test in $tests; do
    tar -xzvf $tarball $test/diff_summary
    mv $test/diff_summary $folder/diff_summary_$test
    rm -rf $test
  done

  # Copy the diff information to the CNERG web server
  web_dir=/home/vhosts/cnergdata.engr.wisc.edu/html/DAGMC-tests/diff_summaries
  if [[ $(hostname -f) == tux-*.cae.wisc.edu ]]; then
    cp -r $folder $web_dir
  else
    scp -r $folder lucasj@best-tux.cae.wisc.edu:$web_dir
  fi

  # Wait until it's time to run the tests again
  end_epoch=$(date +%s)
  sleep_seconds=$(( $start_epoch + $tests_inc - $end_epoch ))
  if [[ $sleep_seconds < 0 ]]; then
    sleep_seconds=0
  fi
  sleep $sleep_seconds
done
