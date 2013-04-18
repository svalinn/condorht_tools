Collection of tools that allow the arbitrary splitting of MCNP input runs into many serial runs for submission onto the CHTC computing system. These runs are queued and submitted using Directed Acylic Graph (DAG) such that sub input decks are subservient to some master input file and allow resubmissions of failed runs.

CHTC Login Instructions
Login to  submit-1.chtc.wisc.edu with your assigned username and password

Instructions
The directory structure shows the layout of scrips and other folders

    /mcnp5dag
	|- /jobs (contains all jobs submission script and preprocessing scripts)
	+- /input (contains the mcnp driver file and run options for condor)

Submitting a job
In order to submit a job the input file should be stored in /input along with the control file (example shown below)

    number = 30
    directory = part
    events = 20t
    input = V6_w1
    output = bttest
    restart = restart.bin
    mctal = mctal_test
    meshtal = meshtal_test
    ~

To run the job, in directory below /input run

    ./mkmcnp5dag --jobscripts=jobs --data=ross_1bt3 --rundir=run_dir

NB --run_dir should be an empty directory

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
