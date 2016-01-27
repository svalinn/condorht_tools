#!/bin/bash

check_inc=1   # Minutes to wait between checks to see if the tests have finished
tests_inc=15  # Minutes to wait between re-running the tests

check_inc=$(( $check_inc * 60 ))
tests_inc=$(( $tests_inc * 60 ))

CONDOR=ljjacobson@submit-3.chtc.wisc.edu
TUX=lucasj@best-tux.cae.wisc.edu
results_dir=/groupspace/cnerg/users/jacobson/DAGMC_condor_results
web_dir=/home/vhosts/cnergdata.engr.wisc.edu/html/DAGMC-tests/summaries
temp_dir=$results_dir/temp

mkdir -p $results_dir
mkdir -p $temp_dir

test_id=0
start_epoch=$(date +%s)
while true; do
  test_id=$(( $test_id + 1 ))

  # Submit the tests on Condor
  ssh $CONDOR 'cd condorht_tools/setup && condor_submit dag_mcnp_tests.sub'

  # Check periodically to see if the tests have finished
  tarball_exists=0
  while [[ $tarball_exists == 0 ]]; do
    sleep $check_inc
    tarball_exists=$(ssh $CONDOR 'ls --color=never condorht_tools/setup | grep ^results_ | grep .tar.gz | wc -l')
  done

  # Make sure Condor has finished copying the entire tarball back to the submit node
  sleep 60

  # Bring back the results tarball
  cd $temp_dir
  scp $CONDOR:condorht_tools/setup/results_*.tar.gz .
  ssh $CONDOR 'mv condorht_tools/setup/results_*.tar.gz condorht_tools/setup/process_* results'
  tarball=`echo results_*.tar.gz`
  datetime=${tarball#$"results_"}
  datetime=${datetime%$".tar.gz"}
  mv $tarball $results_dir

  # Extract the diff information
  summary_text=summary_$datetime.txt
  summary_html=summary_$datetime.html
  summary_html_current=summary__current.html
  cd $results_dir
  tar -xzvf $tarball summaries/$summary_text summaries/$summary_html --strip-components=1

  # Copy the diff information to the CNERG web server
  if [[ $(hostname -f) == tux-*.cae.wisc.edu ]]; then
    cp -f $summary_html $web_dir
    chmod 640 $web_dir/$summary_html
    cp -f $web_dir/$summary_html $web_dir/$summary_html_current
    cd $web_dir/..
    python write_index.py
    cd $results_dir
  else
    scp $summary_html $TUX:$web_dir
    ssh $TUX 'chmod 640 $web_dir/$summary_html;
              cp -f $web_dir/$summary_html $web_dir/$summary_html_current;
              cd $web_dir/..;
              python write_index.py'
  fi

  # Wait until it's time to run the tests again
  end_epoch=$(date +%s)
  sleep_seconds=$(( $test_id * $tests_inc + $start_epoch - $end_epoch ))
  if [ $sleep_seconds -lt 0 ]; then
    sleep_seconds=0
  fi
  sleep $sleep_seconds
done
