#!/usr/bin/python
import sys # for command line args
import os  # for filepath tests
import re  # for regular expressions
import shutil # for copy files

# print the help screen

def print_usage():
    print "Python based script to launch jobs on condor, use as"
    print " "
    print "mkmcnp5dag --data=ross_1bt3 --rundir=run_dir"
    print " "
    print "--data <path_to_prequisite> path to run required before full condor launch"
    print "--rundir <path_to_rundir> path to the directory where output files will appear"
    print "--debug <on or off> more verbose messages are printed along with output scripts retained"
    print "--mcpath <path_and_name of exec> pull path and extension to mcnp executable"
    print "--notify <email> address to email completion of jobs"
    return

# check the command args and ensure valid input
def command_args(argv):
    rundir=""
    datadir=""
    mcnpdir=""
    email_address=""
    debug=False
    
    
    if (len(argv) < 2):
        print_usage()
        sys.exit()
    # loop over the args and check for the keywords    
    for arg in range(1,len(argv)):
        if ( argv[arg] == '--rundir' ):
            rundir=argv[arg+1]
        if ( argv[arg] == '--data' ):
            datadir=argv[arg+1]
        if ( argv[arg] == '--mcpath' ):
            mcnpdir=argv[arg+1]
        if (argv[arg] == '--debug' ):
            if ( argv[arg+1] == 'on' ):
                debug=True
            else:
                debug=False
        if (argv[arg] == '--notify' ):
            email_address=argv[arg+1]
        

    # if strings for datapath or run dir doesnt exist must exit
    if not datadir:
        print "--data directory not specified"
        sys.exit()
    if not rundir:
        print "--rundir directory not specified"
        sys.exit()
    if not mcnpdir:
        print "--mcdir path not specified"
        sys.exit() 

    
    return (datadir,rundir,mcnpdir,debug,email_address)

# check the command args to make sure they are valid
def check_dirs(datadir,rundir,mcdir):
    
    if not os.path.isdir(str(datadir)):
        print "data directory does not exist"
        sys.exit()
        
    if os.path.exists(str(rundir)):
        print "run directory exists, need an empty dir"
        sys.exit()

    if not os.path.exists(str(mcdir)):
        print "mcnp executable does not exist"
        sys.exit()

    return

# check_mcnp_directives for validity
def check_mcnp(datadir):
    # var for truth test
    # determines the truth vals
    num_t = False
    dir_t = False
    eve_t = False
    inp_t = False
    dag_t = False
    out_t = False
    mct_t = False
    mes_t = False
    tet_t = False
    run_t = False
    
    file = open(datadir+"/mcnp_args")

    while 1:
        line = file.readline()
        if not line:
            break
#        print line
        if 'number = ' in line:
            num_cpu = ''.join(x for x in line if x.isdigit())
#            print re.match(r'\d+',line)
#            num_cpu=int(re.match(r'\d+', line))
            num_t = True
            if not num_cpu > 0:
                print "number of cpus needs to be greater than 0"
                sys.exit()
        if 'directory = ' in line:
            dir_t = True
        if 'events = ' in line:
            eve_t = True
        if 'input = ' in line:
            inp_t = True
            mcnp_input_path = line[line.find(" = ")+3:len(line)]
            if not os.path.isfile(datadir+mcnp_input_path.strip()):
                print "MCNP input deck does not exist", datadir+mcnp_input_path.strip()
                sys.exit()
                
        if 'dagmc = ' in line:
            dag_t = True
            dagmc_input_path = line[line.find(" = ")+3:len(line)]
            if not os.path.exists(datadir+dagmc_input_path.strip()):
                print "Dagmc input deck does not exist", datadir+dagmc_input_path.strip()
                sys.exit()
                                            
        if 'output = ' in line:
            out_t = True
        if 'mctal = ' in line:
            mct_t = True
        if 'meshtal = ' in line:
            mes_t = True
        if 'tetmesh = ' in line:
            tet_t = True
            tetmesh_input_path = line[line.find(" = ")+3:len(line)]
            if not os.path.exists(datadir+tetmesh_input_path.strip()):
                print "Tetmesh does not exist", datadir+tetmesh_input_path.strip()
                sys.exit()
        if 'runtpe = ' in line:
            run_t = True
            runtpe_input_path = line[line.find(" = ")+3:len(line)]
            if  not os.path.exists(datadir+runtpe_input_path.strip()):
                print "Runtpe does not exist", datadir+runtpe_input_path.strip()
                sys.exit()

    file.close()

# check the minium prequisites
# if these fail then we can not run
    if not num_t:
        print "Number of cpus to split run onto not specified"
        sys.exit()
    if not dir_t:
        print "directory not specified"
        sys.exit()
    if not eve_t:
        print "events not specified"
        sys.exit()
    if not inp_t:
        print "mcnp input deck not specified"
        sys.exit()
    if not out_t:
        print "mcnp output filename stub not specified"
        sys.exit()
    if not run_t:
        print "runtpe filename not specified"
        sys.exit()

# these are the specific tests to determine the type of run
# if there are considerations we need to add more truth tests to this
    if num_t and  dir_t and eve_t and inp_t and dag_t and out_t and mct_t and mes_t and tet_t and run_t:
        print "dagmc with meshtal, tetmesh, mctal"
    elif num_t and dir_t and eve_t and inp_t and dag_t and out_t and mct_t and mes_t and run_t:
        print "dagmc with meshtal, mctal"
    elif num_t and dir_t and eve_t and inp_t and dag_t and out_t and mct_t  and run_t:
        print "dagmc with mctal"
    elif num_t and dir_t and eve_t and inp_t and dag_t and out_t and run_t:
        print "dagmc with no additional output"
    elif num_t and dir_t and eve_t and inp_t and out_t and mct_t and mes_t and run_t and tet_t:
        print "mcnp5 with meshtal, mctal and tet mesh"
    elif num_t and dir_t and eve_t and inp_t and out_t and mct_t and mes_t and run_t:
        print "mcnp5 with meshtal and mctal"
    elif num_t and dir_t and eve_t and inp_t and out_t and mct_t  and run_t:
        print "mcnp5 with mctal"
    elif num_t and dir_t and eve_t and inp_t and out_t and run_t:
        print "mcnp5"
                                            
    
    return (mcnp_input_path.strip(),dagmc_input_path.strip(),num_cpu)

# create the initial dag file
def create_dag_file(rundir,num_cpu):
    dag_name = "mydag.dag"

    print "writing ",dag_name

    # create the dag file
    fp = open(rundir+'/'+dag_name, "w")
    fp.write("CONFIG dagman_config")
    fp.close()

    # set the maximum number of idle jobs

    fp = open(rundir+'/dagman_config', "w")
    # set the maximum number of idle jobs on the basis of the
    # granularity of the job

    num_cpu = int(num_cpu)

    if num_cpu > 500 and num_cpu <= 5000:
        fp.write("DAGMAN_MAX_SUBMITS_PER_INTERVAL = 100 \n")
        fp.write("DAGMAN_MAX_JOBS_IDLE = 1000 \n")
    elif  num_cpu > 5000:
        fp.write("DAGMAN_MAX_SUBMITS_PER_INTERVAL = 100 \n")
        fp.write("DAGMAN_MAX_JOBS_IDLE = 5000 \n")
    elif num_cpu <= 500:
        fp.write("DAGMAN_MAX_SUBMITS_PER_INTERVAL = 10 \n")
        fp.write("DAGMAN_MAX_JOBS_IDLE = 100 \n")                      
        
    fp.close()
          

    return

# build the DiGraph of the run
def create_dag_hierarchy(rundir,num_cpu):
    dag_name = "mydag.dag"

    # create the dag file
    fp = open(rundir+'/'+dag_name, "w")
    fp.write("JOB premcnp5.init preinitcond.cmd \n")
    fp.write("RETRY premcnp5.init 1 \n")

    # loop over the job hierarchy, we allow 3 resubmits of the mcnp file
    for jobs in range(1,int(num_cpu)):
        fp.write("SCRIPT PRE mcnp5.test_"+str(jobs)+" some clever script "+str(jobs)+"\n")
        fp.write("RETRY mcnp5.test_"+str(jobs)+" 3\n")
                
    # now create script for merging data
    fp.write("JOB mcnp5.meshmerge finalmerge.cmd \n")
    fp.write("SCRIPT POST mcnp5.meshmerge \n")
    fp.write("RETRY mcnp5.meshmerge 1\n")

    fp.write("PARENT")
    for jobs in range(1,int(num_cpu)):
        fp.write(" mcnp5.test_"+str(jobs))

    fp.write(" CHILD mcnp5.meshmerge \n")
    fp.close()

    return

 
# build the dag nodes
def make_dag_nodes(datadir,rundir,mcdir,email_address,debug):

    print "checking input data"
    (mcnp_input_path,dag_input_path,num_cpu)=check_mcnp(datadir) #check the directives file for validity, found in datadir/mcnp_args

    # echo to screen what we are doing
    print "Creating DiGraph "
    print "MakeDagNodes: ", rundir, datadir, "running on ", num_cpu," cores"
    
    # create the directory to store the run data in
    os.makedirs(rundir)

    # copy the continue file to the run directory
    shutil.copyfile(datadir+mcnp_input_path,rundir+'/'+mcnp_input_path)


    # it isnt clcear to me that this is even required!!
    # it seems that its overwritten before its even submitted
    # to the queueing system
    
    #create the dagfile
    create_dag_file(rundir,num_cpu)

    #create the dag hierarchy
    create_dag_hierarchy(rundir,num_cpu)

    return

# make the scripts for the problem
def make_dag_scripts(datadir,rundir,mcdir,email_address,debug):
    print "Making the input scripts"
    (mcnp_input_path,dag_input_path,num_cpu)=check_mcnp(datadir)
    
    for split_run in range(1,int(num_cpu)):
        print split_run
#        write_condor_sub(mcnp_input_path,split)
    
    print num_cpu
    return
