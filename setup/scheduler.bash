#!/bin/bash

check_inc=1   # Minutes to wait between checks to see if the tests havs finished
tests_inc=60  # Minutes to wait between re-running the tests

check_inc=$(( $check_inc * 60 ))
tests_inc=$(( $tests_inc * 60 ))

CONDOR=ljjacobson@submit-3.chtc.wisc.edu
results_dir=/groupspace/cnerg/users/jacobson/DAGMC_condor_results
temp_dir=$results_dir/temp

mkdir -p $results_dir
mkdir -p $temp_dir

test_id=0
while true; do
  test_id=$(( $test_id + 1 ))

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
  datetime=${tarball:8:${#tarball}-15}
  output=diff_$datetime
  tests=`tar --wildcards -tf $tarball */diff_summary | sed 's/\/.*//'`
  mv $tarball $results_dir

  # Extract the diff information
  cd $results_dir
  rm -f $output
  echo DAG-MCNP test suite diffs > $output
  echo Test ID: $test_id >> $output
  echo $datetime >> $output
  for test in $tests; do
    tar -xzvf $tarball $test/diff_summary
    echo >> $output
    echo $test >> $output
    cat $test/diff_summary >> $output
    rm -rf $test
  done
  cp -f $output diff_most_recent

  # Copy the diff information to the CNERG web server
  web_dir=/home/vhosts/cnergdata.engr.wisc.edu/html/DAGMC-tests/diff_summaries
  if [[ $(hostname -f) == tux-*.cae.wisc.edu ]]; then
    cp -f $output diff_most_recent $web_dir
    chmod 640 $web_dir/$output $web_dir/diff_most_recent
  else
    scp $output diff_most_recent lucasj@best-tux.cae.wisc.edu:$web_dir
    ssh lucasj@best-tux.cae.wisc.edu 'chmod 640 $web_dir/$output $web_dir/diff_most_recent'
  fi

  # Wait until it's time to run the tests again
  end_epoch=$(date +%s)
  sleep_seconds=$(( $test_id * $tests_inc + $start_epoch - $end_epoch ))
  if [[ $sleep_seconds < 0 ]]; then
    sleep_seconds=0
  fi
  sleep $sleep_seconds
done
