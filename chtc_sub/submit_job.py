#!/usr/bin/python

import sys
import os
from os import listdir
from os.path import isfile, join
import random
from subprocess import call


def print_help():
    """ prints instructions on how to use
    
    Parameters
    ----------
    None:

    Returns
    ----------
    Does not return, exits program
    """
    print "HELP."
    print "============================="
    print "--path <path_to_data>"
    print "--job <type of job> "
    print "--batch < number of jobs to run>"
    print "--combine if you would or would not like the results combined"  
    print " "
    print "Directory structure expected"
    print " "
    print " ---+--> cwd"
    print "    | "
    print "    +------> input where we keep the code input files" 
    print "    +------> geometry where we keep the dag geometry if any"
    print "    +------> meshes where we keep meshes if any"
    exit()


def convert_int(string):
    """ convert parsed string to int, return 0 if failed
    
    Parameters
    ----------
    string: string to try to convert into int

    Returns
    ----------
    Returns the int version of string if successful, otherwise
    raises an exception
    """

    try:
        integer = int(string)
	return integer
    except:
        print string, " is not a valid int"
        exit()

def check_valid_job(string):
    """ check the name of the job against the approved list

    Parameters
    ----------
    string: name of the job type

    Returns
    ----------
    Bool true if job is on ok list, False if not
    """

    job_list=[]
    job_list.append("MCNP")
    job_list.append("DAGMCNP")
    job_list.append("FLUKA")
    job_list.append("FLUDAG")

    for item in job_list:
        if string in item:
            return True
        else:
            pass
    # nothing matches job list
    return False

def generate_dag_graph(input_files,combine):
    """ loop through the input files to generate a DAG 
    Graph such that the jobs depend on one another for
    completion at the end of the run

    Parameters
    ----------
    input_files: list of the input files that belong to 
    this task
    combine: bool, whether or not we should generate statistics 
    at the end

    Returns
    ----------
    list containing the dag graph
    """

    # now write the config file for dag manager
    file_name = "dagman_config"
    try:
        file = open(file_name,'w')
    except:
        print "Could not open file ", file_name, " to write to"
        exit()
    else:
        pass
    file.write("DAGMAN_MAX_SUBMITS_PER_INTERVAL = 10 \n")
    file.write("DAGMAN_MAX_JOBS_IDLE = 100 \n")
    file.close()



    #  write the dag manager
    file_name = "dagman.dag"
    try:
        file = open(file_name,'w')
    except:
        print "Could not open file ", file_name, " to write to"
        exit()
    else:
        pass

    file.write("CONFIG dagman_config\n")

    counter=0
    for input in input_files:
        counter+=1
        file.write("JOB "+input+" "+"job"+str(counter)+".cmd"+"\n")
        file.write("RETRY "+input+" 5 \n")
    if combine:
        file.write("JOB merge_data finalmerge.cmd"+"\n")
        file.write("SCRIPT POST merge_data"+"\n")
        file.write("RETRY merge_data 1"+"\n")

    return

def pack_for_run(datapath,type_run):
    """ pack everything in the directory for the run

    Parameters
    ----------
    datapath: string :: directory where the input data are
    type_run: string :: type of run 

    Returns
    ----------
    name: name and path of the tar.gz file
    """

    try:
        test_string = listdir(datapath)
    except:
        print datapath," not a valid path"
        exit()
    else:
        tar_gz_name = str(os.urandom(16).encode('hex'))+'.tar.gz'
        command = 'tar -pczf '+datapath+'/'+tar_gz_name+' -C '+datapath+' input' # always need input
        if 'MCNP' in type_run:
            command += ' runtpes' # need runtpe for mcnps
        if 'DAGMCNP' in type_run:
            command += ' geometry' # need geometry for dag geom
        if 'FLUDAG' in type_run:
            command += ' geometry' # need geometry for dag geom

        if 'FLUDAG' in type_run or 'DAGMCNP' in type_run:
            try:
                test = listdir(datapath+'/geometry')
            except:
                print "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
                print "                ERROR "
                print "The geometry subdirectory has not been found, "
                print " this is required for a DAG type run "
                print "                ERROR "
                print "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
                exit()
            
        # everythin ok go ahead and zip
        os.system(command)

    return tar_gz_name # return name of the targz file

def get_input_file_list(datapath):
    """ look in the directory datapath/inputs anything found there
    is presumed to be input files"

    Parameters
    ----------
    datapath: string directory where the input files are kept

    Returns
    ----------
    input_files: list containing the input file names
    """

    try:
        test_string = listdir(datapath)
    except:
        print datapath," not a valid path"
        exit()
    else:
        input_files = [ f for f in listdir(datapath) if isfile(join(datapath,f))]
        print input_files[0]
    return input_files

def build_job_cmd_file(inputfile,job_index):
      """ builds the command file for the job

      Parameters
      ----------
      inputfile: string : name of the input file the command file is being built for
      run_index: int : the integer id of the run
      
      Returns
      ----------
      nothing: writes out job command file
      """  
      file_name = "job"+str(job_index)+".cmd"
      try:
          file = open(file_name,'w')
      except:
          print "Could not open file ", file_name, " to write to"
          exit()
      else:
          pass

      # write the cmd file
      file.write("########################################### \n")
      file.write("#                                         # \n")
      file.write("# Submission script automatically created # \n")
      file.write("#                                         # \n")
      file.write("########################################### \n")
      
      file.write(" \n")
      file.write("executable = job"+str(job_index)+".sh \n")
      file.write(" \n")
      file.write("copy_to_spool = false \n")
      file.write("should_transfer_files = yes \n")
      file.write("when_to_transfer_output = on_exit \n")
      file.write("output = job"+str(job_index)+".out\n")
      file.write("log = job"+str(job_index)+".log\n")     
      file.write("error = job"+str(job_index)+".err\n")
      file.write("transfer_input_files = job"+str(job_index)+".sh\n")
      file.write("+AccountingGroup = EngrPhysics_Wilson \n")
      file.write(" request_cpus = 1\n")
      file.write("request_memory = 2GB\n")
      file.write("request_disk = 1GB\n")

      file.write("Queue \n")
      file.close()

      return

def build_run_script(files_for_run,job_index,inputfile,pathdata,jobtype,run_batches):
      """ builds the script the the command file actually submits to condor

      Parameters
      ----------
      files_for_run: string: name of the tar.gz file containing all input data
      job_index: int: index number of the job
      inputfile: string : name of the input file the command file is being built for
      pathdata: string : path to the input data
      jobtype: string : the kind of job, eg mcnp, fluka etc
      run_batches: int : the number of tasks to run
      
      Returns
      ----------
      nothing: writes out script file
      """  

      # get the user name since this is where we must put file for squid wget
      username = os.getlogin()

      # the script may need to copy the zip files of the codes
      
      # the script file must copy the input data from 

      file_name = "job"+str(job_index)+".sh"
      try:
          file = open(file_name,'w')
      except:
          print "Could not open file ", file_name, " to write to"
          exit()
      else:
          pass

      file.write("#!/bin/bash"+"\n")

      file.write("# get_until_got function - keeps trying to get file with wget \n")
      file.write("# until its successful \n")
      file.write("get_until_got(){ \n")
      file.write("wget -c -t 5 --waitretry=20 --read-timeout=10 $1\n")
#      file.write("while [[ $? != 0 ]]\n")
#      file.write("do\n")
#      file.write("wget $1\n")
#      file.write("done\n")
      file.write("}\n")
               
      file.write("cwd=$PWD\n")
      file.write("get_until_got http://proxy.chtc.wisc.edu/SQUID/"+username+"/"+files_for_run+"  \n")

      # copy the required files to run the code
      file.write("# get and set the gcc compiler suite and set ld and paths \n")
      file.write("get_until_got http://proxy.chtc.wisc.edu/SQUID/"+username+"/compile.tar.gz \n")
      #file.write("wget http://proxy.chtc.wisc.edu/SQUID/"+username+"/compiler_tools.tar.gz\n")
      file.write("tar -zxf compile.tar.gz \n")
      file.write("export LD_LIBRARY_PATH=$cwd/compile/gcc/lib:$cwd/compile/gcc/lib64:$cwd/compile/gmp/lib:$cwd/compile/mpc/lib:$cwd/compile/mpfr/lib  \n") #sets the compiler paths

      # bring moab with us
      file.write("# get and set the moab and hdf5 libs \n")
      file.write("get_until_got http://proxy.chtc.wisc.edu/SQUID/"+username+"/runtime.tar.gz \n")
      file.write("tar -zxf runtime.tar.gz \n")
      file.write("export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$cwd/runtime/hdf5/lib\n")
      file.write("export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$cwd/runtime/moab/lib\n")
      file.write("export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$cwd/runtime/DAGMC/lib\n")
      
      if "FLUKA" in jobtype:
          file.write("# get and set the required fluka paths \n")
          file.write("export FLUPRO=$PWD/runtime/fluka \n")
      if "FLUDAG" in jobtype:
          file.write("# get and set the required fluka paths \n")
          file.write("export FLUPRO=$PWD/runtime/fluka \n")
          file.write("export FLUDAGPATH=$PWD/runtime/DAGMC/bin/mainfludag \n")

      if "MCNP" in jobtype:
          file.write("# get and set the required fluka paths \n")
          file.write("export PATH=$PWD/runtime/DAGMC/bin/:$PATH \n")
      if "DAGMCNP" in jobtype:
          file.write("# get and set the required fluka paths \n")
          file.write("export PATH=$PWD/runtime/DAGMC/bin/:$PATH \n")
            

      # untar the actual run data
      file.write("tar -zxvf "+files_for_run+"\n")
      file.write("mkdir job"+str(job_index)+"\n")
      file.write("cd job"+str(job_index)+"\n")
      file.write("cp ../input/"+inputfile+" . \n")
      
      if "DAGMCNP" in jobtype:
          file.write("cp ../geometry/* ."+"\n")
          file.write("cp ../runtpes/run1 run"+str(job_index)+" \n")
          file.write("geom_file=`ls ../geometry/* | grep 'h5m' | head -n1`"+"\n")
          file.write("mcnp5 c i="+inputfile+" g=$geom_file n=job"+str(job_index)+". r=run"+str(job_index)+"\n")
      elif "MCNP" in jobtype:
          file.write("cp ../runtpes/run1 run"+str(job_index)+"\n")
          file.write("mcnp5 c i="+inputfile+" n=job"+str(job_index)+". r=run"+str(job_index)+"\n")
          
      if "FLUKA" in jobtype:
          file.write("$FLUPRO/flutil/rfluka -M"+str(num_batches)+" "+inputfile+"\n")
      if "FLUDAG" in jobtype:
          file.write("cp ../geometry/* ."+"\n")
          file.write("geom_file=`ls * | grep 'h5m' | head -n1`"+"\n")
          file.write("$FLUPRO/flutil/rfluka -e $FLUDAGPATH -d $geom_file -N0 -M"+str(num_batches)+" "+inputfile+"\n")
       

      # may need to remove all original input data
      
      if "DAGMCNP" in jobtype:
          file.write("cd ..\n")
          file.write("tar -pczf job"+str(job_index)+"_results.tar.gz job"+str(job_index)+"\n") # add the dir to folder
      elif "MCNP" in jobtype:
          file.write("cd ..\n")
          file.write("tar -pczf job"+str(job_index)+"_results.tar.gz job"+str(job_index)+"\n") # add the dir to folder

      # fluka or fludag
      if "FLUKA" in jobtype:
          file.write("tar -pczf job"+str(job_index)+"_results.tar.gz *"+"\n")
          file.write("cd .."+"\n")
          file.write("cp job"+str(job_index)+"/"+"job"+str(job_index)+"_results.tar.gz ."+"\n")
      if "FLUDAG" in jobtype:
          file.write("tar -pczf job"+str(job_index)+"_results.tar.gz *"+"\n")
          file.write("cd .."+"\n")
          file.write("cp job"+str(job_index)+"/"+"job"+str(job_index)+"_results.tar.gz ."+"\n")         

      # clean up before we leave this computer, delete everything but results
      file.write( "ls | grep -v job"+str(job_index)+"_results.tar.gz | xargs rm -rf"+"\n")
      file.close()

      return

################################################
# Python script to launch and divide condor jobs
# into workable chunks, builds dag graph etc
# 
# Assumes that the user has already prepared the data
# i.e. has already generated the runtpe files for mcnp
# etc 
################################################

print 'Number of arguments:', len(sys.argv), 'arguments.'
print 'Argument List:', str(sys.argv)

if len(sys.argv) <= 2:
    print_help()

# check to see if help has been asked for first
for arg in range(0,len(sys.argv)):
    if '--help'  in sys.argv[arg]:
        print_help()

combine = False
#loop over the args      			
for arg in range(0,len(sys.argv)):
    if '--job' in sys.argv[arg]:
    # look for job type
       job_type = sys.argv[arg+1]
    if '--path' in sys.argv[arg]:
    # look for the path to data
       path_data = sys.argv[arg+1]						
    if '--batch' in sys.argv[arg]:
       int_t = convert_int(sys.argv[arg+1])
       num_batches = int_t
    if '--combine' in sys.argv[arg]:
        combine = True

# ensure all vars exist
if not job_type:
    print "The job type has not been defined"
    sys.exit()
#elif not path_data:
#    print "Path to data has not been defined"
#    sys.exit()
elif num_batches < 1:
    print "there are no jobs to run, batches < 1"
    sys.exit()
elif not check_valid_job(job_type):
    print job_type, " is not a valid job name"
    sys.exit()
else:
    pass

path_data = os.getcwd()
# get the input files from the path+'/input'
input_files = get_input_file_list(path_data+'/input')

print input_files

generate_dag_graph(input_files,combine)
print "Zipping files for run..."
files_for_run = pack_for_run(path_data,job_type)

counter=0

# build the DAG graph
generate_dag_graph(input_files,combine)

# loop over the input files present
for inputfile in input_files:
    counter+=1
    # creating the script files that are run by the cmd files
    build_job_cmd_file(inputfile,counter)
    build_run_script(files_for_run,counter,inputfile,path_data,job_type,num_batches)


# 
print "---------------------------------------------"
print "All done"
print " "
print "Copy this containing folder, "+os.getcwd()+" to CHTC"
print "Copy the file, "+files_for_run+", to your squid directory"
print "To submit this job, login to CHTC, eg. ssh davisa@submit-1.chtc.wisc.edu"
print "then type, condor_submit_dag --MaxPre 10 dagman.dag"
print "---------------------------------------------"

# copy the job tar.gz
# get the user name since this is where we must put file for squid wget
# username = os.getlogin()
# os.system('cp '+path_data+'/'+files_for_run+' /squid/'+username+'/'+files_for_run)

# submit the jobs
# this would actually submit the jobs
# call(["condor_submit_dag","--MaxPre","4","dagman.dag"])

