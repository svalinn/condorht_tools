#!/usr/bin/python
import sys # for command line args
import os  # for filepath tests
import re  # for regular expressions
import shutil # for copy files
#from subprocess import call # for sys calls

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
def check_mcnp(datadir,rundir):
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

    dagmc_input_path=""
    mcnp_input_path=""

    while 1:
        line = file.readline()
        # we treat #'s as comments
        if not line:
            break
#        print line
        if "#" in line:
#            print line
            continue
        else:
#            print line
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
                # if a dag run copy the input geometry
                #call(["cp",datadir+dagmc_input_path.strip(),rundir+dagmc_input_path.strip()])
                                            
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
                # copy the tetmesh if requried
                # call(["cp",datadir+tetmesh_input_path.strip(),rundir+tetmesh_input_path.strip()])
            if 'runtpe = ' in line:
                run_t = True
                runtpe_input_path = line[line.find(" = ")+3:len(line)]
                if  not os.path.exists(datadir+runtpe_input_path.strip()):
                    print "Runtpe does not exist", datadir+runtpe_input_path.strip()
                    sys.exit()
                # copy the runtpe file 
                # call(["cp",datadir+runtpe_input_path.strip(),rundir+datadir+runtpe_input_path.strip()])
                # copy the runtpe ncpu times
                # for i in range(1,num_t+1):
                #    print "cp "+datadir+runtpe_input_path.strip()+" "+rundir+datadir+runtpe_input_path.strip()+str(i)
                #    call(["cp",datadir+runtpe_input_path.strip(),rundir+datadir+runtpe_input_path.strip()+str(i)])
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

    # preinit now redundant since original logic was wrong
#    fp.write("JOB premcnp5.init preinitcond.cmd \n")
#    fp.write("RETRY premcnp5.init 1 \n")

    # loop over the job hierarchy, we allow 3 resubmits of the mcnp file
    for jobs in range(1,int(num_cpu)):
        #fp.write("SCRIPT PRE mcnp5.test_"+str(jobs)+" some clever script "+str(jobs)+"\n")
        fp.write("JOB mcnp5.test_"+str(jobs)+" mcnp5."+str(jobs)+".cmd \n")
        fp.write("RETRY mcnp5.test_"+str(jobs)+" 3\n")

#should ultimately perform merge but dont worry for now
                
    # now create script for merging data
   # fp.write("JOB mcnp5.meshmerge finalmerge.cmd \n")
   # fp.write("SCRIPT POST mcnp5.meshmerge \n")
   # fp.write("RETRY mcnp5.meshmerge 1\n")

###
   
###    fp.write("PARENT")
###    for jobs in range(1,int(num_cpu)):
###        fp.write(" mcnp5.test_"+str(jobs))

###    fp.write(" CHILD mcnp5.meshmerge \n")

    
    fp.close()

    return dag_name



# test for tetmesh information in file
# return true/false for tet_mesh in file
# return true/false for meshtal in file
# return true/false for mctal information

# should also modify the mcnp5 input file to include prdmps based off of nps
# if prdmp doesnt exist

# also should remove ctme and replace with nps if doesnt exist

# recommend dumping schedule in none exists
def mcnp_input_query(mcnp_filename,tetmesh):

    tet_mesh_tf = False
    meshtal_tf = False
    mctal_tf = False

    fp = open(mcnp_filename,'r')
    while 1:
        line = fp.readline()
        if not line:
            break
        else:
#            print line
            if not line.startswith('c '):
                # test for advanced tallies
                if "geom=dag" in line:
                   tet_mesh_tf = True
                # check for normal meshtal
                if not "geom=dag" in line and "fmesh" in line:
                   meshtal_tf = True
                # check for prdmp card
                if "prdmp" in line:
                    if "prdmpjj" in line.lower().strip() or \
                       "prdmp2j" in line.lower().strip():
                        mctal_tf = True
                           
    # if advanced tallies on check for existance of file
    if(tet_mesh_tf):
       if not os.path.exists(str(tetmesh)):
           print "Tetmesh, ",str(tetmesh)," does not exist"
           sys.exit()
            
    fp.close()

    return (tet_mesh_tf,meshtal_tf,mctal_tf)

###
### Script to take the mcnp input file pointed to in order to stratify the input deck into
### a given number of parts determined by how many cpu's we would wish to run on
###
def generate_mcnp_inputs(rundir,mcnpfname,cpu_id,n_cpu,nps,seed):

    file = open(rundir+'/'+mcnpfname,'w')

    seed = 12512813139

    print nps

    if int(nps) <= 100000:
        print "nps is very low, is it really worth a distributed run?"

    if int(nps) > 1000000000:
        print "nps is large"
        print "consider chopping the job up into at least 1000 tasks"
    

    if int(nps) < int(n_cpu):
        print "number of particles to run is less than the number of cpus"
        print "do you really need a distributed run"
        sys.exit()

    num2run = int(nps)/int(n_cpu)

    file.write("continue\n")
    file.write("rand gen=2 seed="+str(seed)+" hist="+str(int(num2run)*(int(cpu_id)-1)+1)+"\n")
    if ( cpu_id < n_cpu):
        file.write("nps "+str(num2run)+"\n")
    else:
        num2run =( nps - (int(nps)/int(n_cpu)*n_cpu) + (int(nps)/int(n_cpu)))
        file.write("nps "+str(num2run)+"\n")

    # turn on mctal dumping
    file.write("prdmp "+str(num2run)+" "+str(num2run)+" 2 2j")

    file.close()
    
    return



# check that all input data pointed to by mcnp_args points to valid data
# check that tet meshes exist if pointed to
# check that the mcnp input deck exists
# check that the dagmc geometry exists if pointed to
# check_mcnp_directives for validity
def generate_condor_scripts(datadir,rundir,mcnp_exec):

    """ The purpose of this routine is to create complete condor input command files to run the mcnp
    problem pointed to by mcnp_args. It should generate command scripts on the basis of files pointed
    to by including, the tetmesh files and dagmc geometries to copy
    """

    print "Generating condor scripts"
    
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
    tetmesh_input_path=""
    file = open(datadir+"/mcnp_args")


    while 1:
        line = file.readline()
        if not line:
            break
        if "#" in line:
            continue
        else:
            print line
           
            if 'number = ' in line:
                num_cpu = int(''.join(x for x in line if x.isdigit()))
                num_t = True
                if not num_cpu > 0:
                    print "number of cpus needs to be greater than 0"
                    sys.exit()

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
                # copy dag input data
                shutil.copyfile(datadir+'/'+dagmc_input_path.strip(),rundir+'/'+dagmc_input_path.strip())
                print "dagmc"
            if 'tetmesh = ' in line:
                tet_t = True
                tetmesh_input_path = line[line.find(" = ")+3:len(line)]
                if not os.path.exists(datadir+tetmesh_input_path.strip()):
                    print "Tetmesh does not exist", datadir+tetmesh_input_path.strip()
                    sys.exit()
                # copy tetmesh if need be
                shutil.copyfile(datadir+'/'+tetmesh_input_path.strip(), rundir+'/'+tetmesh_input_path.strip())
                print "tetmesh"

            if 'runtpe = ' in line:
                run_t = True
                runtpe_input_path = line[line.find(" = ")+3:len(line)]
                if  not os.path.exists(datadir+runtpe_input_path.strip()):
                    print "Runtpe does not exist", datadir+runtpe_input_path.strip()
                    sys.exit()
                for i in range (1,num_cpu+1):
                    shutil.copyfile(datadir+'/'+runtpe_input_path.strip(),rundir+'/'+runtpe_input_path.strip()+str(i))
                print "runtpe"
                                                                                
                
    tet_tf = False
    mesh_tf = False
    mctal_tf = False

    # query the mcnp input deck for input information
    (tet_tf,mesh_tf,mctal_tf)=mcnp_input_query(datadir+mcnp_input_path.strip(),datadir+tetmesh_input_path.strip())

    # check for logic failures, eg if tet mesh pointed to in mcnp_args but no file in input deck
    if tet_tf and tet_t:
        print "tetmesh listed in mcnp args and in mcnp input"
    if tet_tf and not tet_t:
        print "tetmesh not listed in mcnp args but referenced in mcnp input"
        sys.exit()
    if not tet_tf and tet_t:
        print "tetmesh listed in mcnp args but not in input"
        sys.exit()
    # check for mctal data

    for i in range(1,num_cpu+1):

        input_files = ""
        
        # write the command file
        string = rundir+'/mcnp5.'+str(i)+'.cmd'
        print string
        fp = open(rundir+'/mcnp5.'+str(i)+'.cmd','w')

        fp.write("########################################### \n")
        fp.write("#                                         # \n")
        fp.write("# Submission script automatically created # \n")
        fp.write("#                                         # \n")
        fp.write("########################################### \n")

        fp.write(" \n")
        fp.write("executable = "+mcnp_exec+" \n")

        # input command string
        input_command   = " c i="+mcnp_input_path.strip()+str(i)
        runtpe_command  = " r=runtpe"+str(i)
        output_command  = " o=output."+str(i)
        mctal_command   = " mctal=mctal"+str(i)

        mcnp_args = input_command+" "+runtpe_command+" "+output_command+" "+mctal_command
        if mesh_tf:
            mcnp_args += " mesh=meshtal"+str(i)
        if dag_t:
            mcnp_args += " g="+dagmc_input_path.strip()
        
        # write the arguments
        fp.write("arguments = "+mcnp_args+"\n")

        fp.write("universe = vanilla \n")
        fp.write("output = mcnp5."+str(i)+".out \n")
        fp.write("error = mcnp5."+str(i)+".err \n")
        fp.write("log = mcnp5."+str(i)+".log \n")

        # files to copy to compute node that are required
        input_stream  = mcnp_input_path.strip()+str(i)+","
        runtpe_stream = "runtpe"+str(i)

        # if the input files exists then copy it
        if inp_t:
            input_files += input_stream
        # if the damgc input exits copy it
        if dag_t:
            input_files += dagmc_input_path.strip()+","
        # if tet mesh exists then copy it
        if tet_t:
            input_files += tetmesh_input_path.strip()+","

        input_files += runtpe_stream           

        fp.write(" \n")
        fp.write("copy_to_spool = false \n")
        fp.write("should_transfer_files = yes \n")
        fp.write("when_to_transfer_output = on_exit \n")
        fp.write("transfer_input_files = "+input_files+"\n")
        fp.write("+AccountingGroup = EngrPhysics_Wilson \n")

        fp.write("Queue \n")

        print "Generating mcnp inputs for job", i
        seed = 123745775
        nps = 100000
        generate_mcnp_inputs(rundir,mcnp_input_path.strip()+str(i),i,num_cpu+1,nps,seed)
  
        fp.close

 
# build the dag nodes
def make_dag_nodes(datadir,rundir,mcdir,email_address,debug):

    """
    Function to make the Directed Acyclic Graph nodes, links in with
    create_dag_file

    """

    # args
    # datadir - directory containing the input data
    # rundir  - the directory where the run data will be put
    # mcdir   - is the directory where the mcnp executable will be found
    # email_address - is a valid email address which can be emailed upon job completion
    # debug - flag for extra input data

    print "checking input data"
    (mcnp_input_path,dag_input_path,num_cpu)=check_mcnp(datadir,rundir) #check the directives file for validity, found in datadir/mcnp_args

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
    dag_filename=create_dag_hierarchy(rundir,num_cpu)

    return dag_filename

# make the scripts for the problem
# make all the scripts for the problem being submitted along with
# all required ancilliary files
def make_dag_scripts(datadir,rundir,mcdir,email_address,debug):
    """
    Wrapper function the takes arguments and passes them to functions that
    check the validity of the arguments and then generate the condor submission
    files on the basis of the valid inputs
    """
    # returns the number of cpus
    print "Making the input scripts"
    (mcnp_input_path,dag_input_path,num_cpu)=check_mcnp(datadir,rundir)
    generate_condor_scripts(datadir,rundir,mcdir)
    
    return num_cpu
