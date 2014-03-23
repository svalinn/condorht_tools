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

Documenting Matrix of Computing Modes and Use Cases
=====================================================

There are a number of different run types that can be defined:

* Serial: A normal serial calculation, jobs are simply spawned to the batch system and are run when computation nodes have availability. Could be used for parameters scans to vary input data.
* HTC: High Throughput Computation, a normally serial calculation is split into a number of jobs. This is done by submitting the same input file N times, with each file running NPS/N particles. In maintain the RN sequence, the each run is seeded with the same RN seed, but each run starts on history such that the RN sequence isnt used twice
* HPC: High Performance Computing, a standard mode of operation for most HPC cluster systems. N cpu's work collectively on the same problem, communicating initialisation and output data using MPI (or OMP).
* HTPC: High Throughput Parallel Computation, like HPC but provisioned through an HTCondor scheduler on an opportunistic resource rather than a dedicated scheduler
* HyPC - Hybrid Parallel Computation, a combination of HTC and HTPC, the granularity of the calculation is set such that a number of inputs are created which appropriately stride through the RN seed, however each input is operated upon in parallel using MPI

There are also a number of calculation modes that must be tested, 
* Nat. Geom - Nat(ive) Geometry, an MCNP input deck 
* DAG Geom - Direct Accelerated Geometry, tracking of particles upon faceted CAD models, can have more stringent RAM requirements over Native Geometry; also needs to transport more files

There are also a number of scoring modes that must be tested
* Simple Tallies - A small number of uncomplicated tallies, several tallies of same types with no energy binning
* Complex Tallies - A large number of complex tallies, energy dependence, fm card multipliers, dose response functions, traditional mesh tally (additional file handling)
* Advanced Tallies - Newer style, using tetmesh and KDE tallies (additional file handling)

| Par Mode | Nat. Geom Simp. Tallies | DAG Geom Simp Tallies | Nat. Geom Comp Tallies | DAG Geom Comp. Tallies | DAG Geom Advanced Tallies | 
| ------------- |:-------------:|:-------------:|:-------------:|:-------------:|:-------------:|
| **Serial**  | beta | beta | beta | beta #11 | beta #17 #12 |
| **HTC**   | beta | beta #11  #3  | beta #3 | beta | beta |
| **HPC**    | x | x | x |  x | x |
| **HTPC**  | #4 | #4 | #4 | #4 | #4 |
| **HyPC**  | x | x | x | x | x |
