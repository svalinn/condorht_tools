Collection of tools that allow the arbitrary splitting of MCNP input runs into many serial runs for submission onto the CHTC computing system. These runs are queued and submitted using Directed Acylic Graph (DAG) such that sub input decks are subservient to some master input file and allow resubmissions of failed runs.

Run Instructions
=====================================================
split_mcnp.py
-----------------------------------------------------
Run the script as follows

      $> ./split_mcnp.py 
         --inputdir /data/opt/condorht_tools/mcnp_run/ 
         --mcnp "mcnp5 i=mcnp_inp g=mcnp_geom.h5m" --cpu 100 

Which will split the MCNP jobs mcnp_inp, into 100 sub tasks, striding through 
the Random number seed appropriately. All the script does is launch mcnp with 
the arguments you specify in addition to 'ix'. The 'ix' command tells MCNP
to initialise the calculation, creating all the arrays and reading all the 
cross section data that are required and writing it all to a runtpe file.

The submit job command, looks in the run directory for the input files and 
sumits each one as an mcnp continue run.

split_fluka.py
-----------------------------------------------------
Run the script as follows

      $> ./split_fluka.py 
         --input fluka_inp.inp  --cpu 100 

Which will split the Fluka job fluka_inp.inp, into 100 sub tasks, assigning
each one a unique random number seed. 

The submit job command, looks in the run directory for the input files and 
sumits each one as an mcnp continue run.

submit_job.py
-----------------------------------------------------
To run submit job

    $> submit_job.py --path /data/opt/fludag-v-and-v/fng-dose/job_chtc 
       --job FLUKA --batch 20

Will launch each input file in the --path directory --batch times 20. In the 
case where --job is FLUKA or FLUDAG -batch means run 20 statistically 
independent runs, in the case of MCNP is will mean lauch 20 mpi tasks, 
currently it is ignored.

    $> submit_job.py --path /data/opt/fludag-v-and-v/fng-dose/job_chtc 
       --job MCNP 


Submit job assumes a certain directory structure for the input data. It assumes

    ----> input_dir
       +---> input
       +---> geometry
       +---> run
       +---> tet_mesh

The script collects all the input files in the run directory and adds them
to a list to run. The input directory is tar.gz'ed up and copied to volatile
remote storage SQUID (this is important on CHTC). The script creates a Directed 
Acyclic Graph to control and resubmit the jobs upon failiure.

combine_data.py
-----------------------------------------------------
To run the combine script, 

      $> ./combine_data.py --path /data/prod/chtc_test/mcnp/results/ --job MCNP 
      
Will produce a collection of CHTC job files and scripts and a DAG graph that will collapse the data. Create a directory in your squid directory
and copy the produced *.sh *.dag and *.cmd files to this location, along with the results files produced earlier.

