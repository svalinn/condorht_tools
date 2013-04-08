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