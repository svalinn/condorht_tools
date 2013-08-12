#!/usr/bin/python

import sys
import os
from os import listdir
from os.path import isfile, join
import random

def print_help(NULL):
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
        file.write("RETRY "+input+"\n")
    if combine:
        file.write("JOB merge_data finalmerge.cmd"+"\n")
        file.write("SCRIPT POST merge_data"+"\n")
        file.write("RETRY merge_data 1"+"\n")

    return

def pack_for_run(datapath):
    """ pack everything in the directory for the run

    Parameters
    ----------
    datapath: string directory where the input data are

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
        command = 'tar -pczf '+datapath+'/'+tar_gz_name+' -C '+datapath+' input geometry'
        os.system(command)

    return tar_gz_name

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
      file.write("error = job"+str(job_index)+".err\n")
      file.write("transfer_input_files = job"+str(job_index)+".sh\n")
      file.write("+AccountingGroup = EngrPhysics_Wilson \n")
      
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

      file.write("cwd=$PWD\n")
      file.write("wget http://proxy.chtc.wisc.edu/SQUID/"+username+"/"+files_for_run+"\n")

      # copy the required files to run the code
      file.write("# get and set the gcc compiler suite and set ld and paths \n")
      file.write("wget http://proxy.chtc.wisc.edu/SQUID/"+username+"/"+compiler_tools.tar.gz "\n")
      file.write("tar -zxf compiler_tools.tar.gz \n")
      file.write("export LD_LIBRARY_PATH=$cwd/compiler/gcc-4.8.1/lib:$cwd/compiler/gcc-4.8.1/lib64:$cwd/compiler/gmp-5.1.2/lib:$cwd/compiler/mpc-1.0.1/lib:$cwd/compiler/mpfr-3.1.2/lib \n") #sets the compiler paths

      # bring moab with us
      file.write("# get and set the moab and hdf5 libs \n")                 
      file.write("wget http://proxy.chtc.wisc.edu/SQUID/"+username+"/"+moab_tools.tar.gz "\n")
      file.write("tar -zxf moab_data.tar.gz \n")
      file.write("export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$cwd/hdf5-1.8.4/lib\n")
      file.write("export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$cwd/moab-4.6.0/lib \n")

      if "FLUKA" or "FLUDAG" in jobtype:
          file.write("# get and set the required fluka paths \n")
          file.write("wget http://proxy.chtc.wisc.edu/SQUID/"+username+"/"+fludag_fluka_run.tar.gz "\n")         
          file.write("export FLUPRO=$PWD/fluka \n")

      # untar the actual run data
      file.write("tar -zxvf "+files_for_run+"\n")
      file.write("mkdir job"+str(job_index)+"\n")
      file.write("cd job"+str(job_index)+"\n")
      file.write("cp ../input/"+inputfile+"\n")
      
      if "MCNP" in jobtype:
          file.write("mcnp5 c="+inputfile+" n=job"+str(job_index)+"\n")
      if "DAG-MCNP" in jobtype:
          file.write("cp ../geometry/* ."+"\n")
          file.write("geom_file=`ls geometry/* | grep 'h5m' | head -n1`"+"\n")
          file.write("mcnp5 c="+inputfile+" g=$geom_file n=job"+str(job_index)+"\n")
      if "FLUKA" in jobtype:
          file.write("$FLUPRO/flutil/rfluka -M"+str(num_batches)+" "+inputfile+"\n")
      if "FLUDAG" in jobtype:
          file.write("cp ../geometry/* ."+"\n")
          file.write("geom_file=`ls geometry/* | grep 'h5m' | head -n1`"+"\n")
          file.write("$FLUPRO/flutil/rfluka -e $FLUDAGPATH -d $geom_file -M"+str(num_batches)+" "+inputfile+"\n")

      # may need to remove all original input data
      file.write("tar -pczf job"+str(job_index)+"_results.tar.gz *"+"\n")
      file.write("cd .."+"\n")
      file.write("cp job"+str(job_index)+"/"+"job"+str(job_index)+"_results.tar.gz ."+"\n")
      # clean up before we leave this computer, delete everything but results
      file.write( "ls * | grep -v job"+str(job_index)+"_results.tar.gz | xargs rm -rf"+"\n")
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

if len(sys.argv) < 2:
    print_help

# check to see if help has been asked for first
for arg in range(0,len(sys.argv)):
    if '-h ' or '--help' or '--h ' in sys.argv[arg]:
        print_help

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
    exit()
elif not path_data:
    print "Path to data has not been defined"
    exit()
elif num_batches < 1:
    print "there are no jobs to run, batches < 1"
    exit()
elif not check_valid_job(job_type):
    print job_type, " is not a valid job name"
    exit()
else:
    pass


# get the input files from the path+'/input'
input_files = get_input_file_list(path_data+'/input')

print input_files

generate_dag_graph(input_files,combine)
print "Zipping files for run..."
files_for_run = pack_for_run(path_data)

counter=0

# build the DAG graph
generate_dag_graph(input_files,combine)

# loop over the input files present
for inputfile in input_files:
    counter+=1
    # creating the script files that are run by the cmd files
    build_job_cmd_file(inputfile,counter)
    build_run_script(files_for_run,counter,inputfile,path_data,job_type,num_batches)
