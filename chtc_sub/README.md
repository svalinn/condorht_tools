Instructions for use
====================================

Within this directory you should find split_mcnp and submit_job. The purpose
of split_mcnp is to be used on your OWN machine to create runtpe files that can
then be transferred to condor and used. The purpose of  submit_job is to take
the directory structure created by split_mcnp and launch those tasks on chtc

split_mcnp
=====================================
To use split mcnp create a folder, for example mcnp_run, and copy the mcnp 
file you would like to split for running. Bring with it any ancilliary files
that you may want, weight windows, DAG geometry inputs, mesh inputs etc.

      $> mkdir mcnp_run
      $> cp mcnp_inp .
      $> cp mcnp_geom.h5m

The script takes direction from the MCNP input deck, if you have not specified
the random number seed the script takes the MCNP default. You can also specify
is on the argument line. 

Run the script as follows

      $> ./split_mcnp.py --rundir /data/opt/condorht_tools/mcnp_run/run/ 
         --inputdir /data/opt/condorht_tools/mcnp_run/ 
         --mcnp "mcnp5 i=mcnp_inp g=mcnp_geom.h5m" --cpu 100 

Which will split the MCNP jobs mcnp_inp, into 100 sub tasks, striding through 
the Random number seed appropriately. All the script does is launch mcnp with 
the arguments you specify in addition to 'ix'. The 'ix' command tells MCNP
to initialise the calculation, creating all the arrys and reading all the xsdata
that you required and writing it all to a runtpe file.

The submit job command, looks in the run directory for the input files and 
sumits each one as an mcnp continue run.

split_fluka
=====================================
<< to be continued >>

submit_job
=====================================
To run submit job

    $> submit_job.py --path /data/opt/fludag-v-and-v/fng-dose/job_chtc 
       --job FLUKA --batch 20

Will launch each input file in the --path directory --batch times 20. In the 
case where --job is FLUKA or FLUDAG -batch means run 20 statistically 
independent runs, in the case of MCNP is will mean lauch 20 mpi tasks, 
currently it is ignored.

Submit job assumes a certain directory structure for the input data. It assumes

    ----> input_dir
       +---> geometry
       |
       +---> run
       |
       +---> ????

The script collects all the input files in the run directory and adds them
to a list to run. The input directory is tar.gz'ed up and copied to volatile
remote storage (this is important on CHTC). The script creates a Directed 
Acyclic Graph to control and resubmit the jobs upon failiure. Currently
the script does not collect the output data and produce averagaes, but there is
a flag for it.