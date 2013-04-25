#!/usr/bin/python
# submit script to launch mcnp5 job(s) in a number of ways in order to facilitate parallel computation on CondorHT

# based on the original mkdagmcnp5 written by Bill Taylor and
# converted to python by Andrew Davis and Zach Welch, Department of Engineering Physics, Uw Madison

import sys # for command line args
import os  # for filepath tests
import re  # for regular expressions

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
                                            
    
    return

# build the dag nodes
def make_dag_nodes(datadir,rundir,mcdir,email_address,debug):

    print "checking input data"
    check_mcnp(datadir) #check the directives file for validity, found in datadir/mcnp_args

    print "creating digraph"

    return
    
# main program loop

print "launch mcnp tasks on condor"

(datadir,rundir,mcdir,debug,email_address)=command_args(sys.argv)

print "checking for existence of prequisites"
check_dirs(datadir,rundir,mcdir)

if(debug):
    print datadir, rundir, mcdir, email_address

print "creating DiGraph Nodes"
make_dag_nodes(datadir,rundir,mcdir,email_address,debug)
