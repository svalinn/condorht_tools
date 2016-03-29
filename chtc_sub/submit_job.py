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
    print "--filesystem if you want to select gluster or SQUID"
    print "--user specify the username for Condor"
    print " "
    print "Directory structure expected"
    print " "
    print " ---+--> cwd"
    print "    | "
    print "    +------> input where we keep the code input files" 
    print "    +------> geometry where we keep the dag geometry if any"
    print "    +------> wwinp where we keep the weight windows if there are any"
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
        # only MCNP & DAGMC can use wwinps
        if 'MCNP' in type_run or 'DAGMCNP' in type_run:
            # see if there is a wwinp file
            if os.path.exists(datapath+'/wwinp'):
                command += ' wwinp' # need runtpe for mcnps
            
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

def build_job_cmd_file(inputfile,job_index,jobtype):
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
      if jobtype.lower() == "gluster":
          file.write("# Require execute servers that have Gluster:\n")
          file.write("Requirements = (Target.HasGluster == true)\n")

      file.write("copy_to_spool = false \n")
      file.write("should_transfer_files = yes \n")
      file.write("when_to_transfer_output = on_exit \n")
      file.write("output = job"+str(job_index)+".out\n")
      file.write("log = job"+str(job_index)+".log\n")     
      file.write("error = job"+str(job_index)+".err\n")
      file.write("transfer_input_files = job"+str(job_index)+".sh\n")
      file.write("+AccountingGroup = EngrPhysics_Wilson \n")
      file.write(" request_cpus = 1\n")
      file.write("request_memory = 12GB\n")
      file.write("request_disk = 20GB\n")

      file.write("Queue \n")
      file.close()

      return

def build_run_script(files_for_run,job_index,inputfile,pathdata,jobtype,username,filesystem,run_batches):
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
      # set the filename
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
      file.write("}\n")

      file.write("function set_env() { \n")
      file.write("# GMP \n")
      file.write("export LD_LIBRARY_PATH=$PWD/gmp/lib:$LD_LIBRARY_PATH\n")
      file.write("# MPFR \n")
      file.write("export LD_LIBRARY_PATH=$PWD/mpfr/lib:$LD_LIBRARY_PATH \n")
      file.write("# MPC \n")
      file.write("export LD_LIBRARY_PATH=$PWD/mpc/lib:$LD_LIBRARY_PATH \n")
      file.write("# GCC \n")
      file.write("export PATH=$PWD/gcc/bin:$PATH                 \n")
      file.write("export LD_LIBRARY_PATH=$PWD/gcc/lib:$LD_LIBRARY_PATH \n")
      file.write("export LD_LIBRARY_PATH=$PWD/gcc/lib64:$LD_LIBRARY_PATH \n")
      file.write("# OpenMPI \n")
      file.write("export PATH=$PWD/openmpi/bin:$PATH \n")
      file.write("export LD_LIBRARY_PATH=$PWD/openmpi/lib:$LD_LIBRARY_PATH \n")
      file.write("# CMake \n")
      file.write("export PATH=$PWD/cmake/bin:$PATH \n")
      file.write("export LD_LIBRARY_PATH=$PWD/cmake/lib:$LD_LIBRARY_PATH \n")
      file.write("# Python \n")
      file.write("export PATH=$PWD/python/bin:$PATH \n")
      file.write("export LD_LIBRARY_PATH=$PWD/python/lib:$LD_LIBRARY_PATH \n")
      file.write("# HDF5 \n")
      file.write("export PATH=$PWD/hdf5/bin:$PATH \n")
      file.write("export LD_LIBRARY_PATH=$PWD/hdf5/lib:$LD_LIBRARY_PATH \n")
      file.write("# LAPACK                \n")
      file.write("export LD_LIBRARY_PATH=$PWD/lapack/lib:$LD_LIBRARY_PATH \n")
      file.write("# Setuptools \n")
      file.write("export PATH=$PWD/setuptools/bin:$PATH \n")
      file.write("export PYTHONPATH=$PWD/setuptools/lib/python2.7/site-packages:$PYTHONPATH \n")
      file.write("# Cython \n")
      file.write("export PATH=$PWD/cython/bin:$PATH \n")
      file.write("export PYTHONPATH=$PWD/cython/lib/python2.7/site-packages:$PYTHONPATH \n")
      file.write("# NumPy \n")
      file.write("export PATH=$PWD/numpy/bin:$PATH \n")
      file.write("export PYTHONPATH=$PWD/numpy/lib/python2.7/site-packages:$PYTHONPATH \n")
      file.write("# SciPy \n")
      file.write("export PATH=$PWD/pytables/bin:$PATH \n")
      file.write("export PYTHONPATH=$PWD/scipy/lib/python2.7/site-packages:$PYTHONPATH \n")
      file.write("# NumExpr \n")
      file.write("export PYTHONPATH=$PWD/numexpr/lib/python2.7/site-packages:$PYTHONPATH \n")
      file.write("# PyTables \n")
      file.write("export PYTHONPATH=$PWD/pytables/lib/python2.7/site-packages:$PYTHONPATH \n")
      file.write("# Nose \n")
      file.write("export PATH=$PWD/nose/bin:$PATH \n")
      file.write("export PYTHONPATH=$PWD/nose/lib/python2.7/site-packages:$PYTHONPATH \n")
      file.write("# CUBIT \n")
      file.write("export PATH=$PWD/cubit/bin:$PATH \n")
      file.write("export LD_LIBRARY_PATH=$PWD/cubit/bin:$LD_LIBRARY_PATH \n")
      file.write("# CGM \n")
      file.write("export LD_LIBRARY_PATH=$PWD/cgm/lib:$LD_LIBRARY_PATH \n")
      file.write("# MOAB \n")
      file.write("export PATH=$PWD/moab/bin:$PATH \n")
      file.write("export LD_LIBRARY_PATH=$PWD/moab/lib:$LD_LIBRARY_PATH \n")
      file.write("# MeshKit \n")
      file.write("export PATH=$PWD/meshkit/bin:$PATH \n")
      file.write("export LD_LIBRARY_PATH=$PWD/meshkit/lib:$LD_LIBRARY_PATH \n")
      file.write("# PyTAPS \n")
      file.write("export PATH=$PWD/pytaps/bin:$PATH \n")
      file.write("export PYTHONPATH=$PWD/pytaps/lib/python2.7/site-packages:$PYTHONPATH \n")
      file.write("# Geant4 \n")
      file.write("export PATH=$PWD/geant4/bin:$PATH \n")
      file.write("export LD_LIBRARY_PATH=$PWD/geant4/lib:$LD_LIBRARY_PATH \n")
      file.write("export LD_LIBRARY_PATH=$PWD/geant4/lib64:$LD_LIBRARY_PATH \n")
      file.write("# FLUKA \n")
      file.write("export PATH=$PWD/fluka/bin:$PATH \n")
      file.write("export FLUFOR=gfortran \n")
      file.write("export FLUPRO=$PWD/fluka/bin \n")
      file.write("export FLUDAG=$PWD/dagmc/bin \n")
      file.write("# DAGMC \n")
      file.write("export PATH=$PWD/dagmc/bin:$PATH \n")
      file.write("export LD_LIBRARY_PATH=$PWD/dagmc/lib:$LD_LIBRARY_PATH \n")
      file.write("# PyNE \n")
      file.write("export PATH=$PWD/pyne/bin:$PATH \n")
      file.write("export PYTHONPATH=$PWD/pyne/lib/python2.7/site-packages:$PYTHONPATH \n") 
      file.write("# SRAG \n")
      file.write("export GCR_SOURCE_PATH=$PWD/srag/RadSource/GCRSource/\n")
      file.write("} \n")

      file.write("cwd=$PWD\n")
      if filesystem.lower() == "squid":
        file.write("get_until_got http://proxy.chtc.wisc.edu/SQUID/"+username+"/"+files_for_run+"  \n")
        file.write("# get and set the gcc compiler suite and set ld and paths \n")
        file.write("get_until_got http://proxy.chtc.wisc.edu/SQUID/"+username+"/compiler.tar.gz \n")
        file.write("# unpack all the dependencies\n")       
        file.write("tar -zxf compiler.tar.gz \n")
        file.write("# unpack all the dependencies\n")
        file.write('ls *.tar.gz | grep -v "compiler.tar.gz" | grep -v "'+files_for_run+'" | xargs -i tar -zxvf {}\n')
      if filesystem.lower() == "gluster":
        file.write("# copy the files for run\n")
        file.write("cp /mnt/gluster/"+username+"/"+files_for_run+" . \n")
        file.write("# copy the dependencies\n")        
        file.write("cp /mnt/gluster/"+username+"/tar_install/*.tar.gz . \n")
        file.write("# unpack the dependencies - note the below command is purposeful\n")  
        file.write("ls /mnt/gluster/$USER/tar_install/ | xargs -i tar -zxf {}\n")

      # always set the env
      file.write("# set all the library paths\n")  
      file.write("set_env\n")
      if "FLUKA" in jobtype:
          file.write("# get and set the required fluka paths \n")
          file.write("export FLUPRO=$PWD/fluka/bin \n")
      if "FLUDAG" in jobtype:
          file.write("# get and set the required fluka paths \n")
          file.write("export FLUPRO=$PWD/fluka/bin \n")
          file.write("export FLUDAGPATH=$PWD/dagmc/bin/mainfludag \n")
      # MCNP & DAGMCNP paths already set
      
      # untar the actual run data
      file.write("tar -zxvf "+files_for_run+"\n")
      file.write("mkdir job"+str(job_index)+"\n")
      file.write("cd job"+str(job_index)+"\n")
      file.write("cp ../input/"+inputfile+" . \n")
      
      if "DAGMCNP" in jobtype:
          file.write("cp ../geometry/* ."+"\n")
          file.write("cp ../runtpes/run1 run"+str(job_index)+" \n")
          file.write("geom_file=`ls ../geometry/* | grep 'h5m' | head -n1`"+"\n")
          file.write('wwinp_cmd=""\n')
          file.write('if [ -d "../wwinp" ] ; then \n')
          file.write("    wwinp_file=`ls ../wwinp/* | head -n1`\n")
          file.write('    wwinp_cmd="wwinp=$wwinp_file"\n')
          file.write('fi\n')
          file.write("mcnp5 c i="+inputfile+" g=$geom_file n=job"+str(job_index)+". r=run"+str(job_index)+" $wwinp_cmd\n")
      elif "MCNP" in jobtype:
          file.write("cp ../runtpes/run1 run"+str(job_index)+"\n")
          file.write('wwinp_cmd=""\n')
          file.write('if [ -d "../wwinp" ] ; then \n')
          file.write("    wwinp_file=`ls ../wwinp/* | head -n1`\n")
          file.write('    wwinp_cmd="wwinp=$wwinp_file"\n')
          file.write('fi\n')
          file.write("mcnp5 c i="+inputfile+" n=job"+str(job_index)+". r=run"+str(job_index)+" $wwinp_cmd\n")
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

      # if we are a gluster job
      if filesystem == "gluster":
          # the unique dir is a place where will collect all the output files
          # to do with the run
          # only done for gluster runs
          unique_dir = files_for_run[0:-7]
          file.write("if [ ! -d /mnt/gluster/"+username+"/"+unique_dir+" ] ;then \n")
          file.write("    mkdir /mnt/gluster/"+username+"/"+unique_dir+"\n")
          file.write("fi\n")
          file.write("mv job"+str(job_index)+"_results.tar.gz /mnt/gluster/"+username+"/"+unique_dir+"/.\n")
          
      # close the file
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
    if '--help'  in sys.argv[arg] or '-h' in sys.argv[arg]:
        print_help()

combine = False
filesystem = "gluster"
# default to the current username if unspecified
username = os.getlogin()

#loop over the args      			
for arg in range(0,len(sys.argv)):
    if '--job' in sys.argv[arg]:
    # look for job type
       job_type = sys.argv[arg+1]
    if '--path' in sys.argv[arg]:
    # look for the path to data
       path_data = sys.argv[arg+1]						
    if '--batch' in sys.argv[arg]:
    # set the number of batches
       int_t = convert_int(sys.argv[arg+1])
       num_batches = int_t
    if '--combine' in sys.argv[arg]:
    # set wether we want to combine the output data
        combine = True
    if '--filesystem' in sys.argv[arg]:
    # set whether we want to use the gluster or squid filesystem
        filesystem = sys.argv[arg+1]
    if '--user' in sys.argv[arg]:
    # set whether we want to use the current usnername, or a specified one
        username = sys.argv[arg+1]

# ensure all vars exist
if not job_type:
    print "The job type has not been defined"
    sys.exit()
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
    build_job_cmd_file(inputfile,counter,filesystem)
    build_run_script(files_for_run,counter,inputfile,path_data,job_type,username,filesystem,num_batches)


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

