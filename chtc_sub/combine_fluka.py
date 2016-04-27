#!/usr/bin/python
import sys

fluka_scores = ["USRBDX","USRTRACK","USRBIN","USRYIELD","RESNUCLEI"]

# write the collapse fluka function
def write_collapse_fluka(filename):
      filename.write("function collapse_fluka {\n")
      filename.write("# check for args\n")
      filename.write("file_token=$1\n")
      filename.write("unit_name=$2\n")
      filename.write("file_type=$3\n")
      filename.write("output_name=$4\n")
      filename.write("\n")
      filename.write("if [[ $# -eq 0 ]] ; then\n")
      filename.write("      echo 'No arguments provided'\n")
      filename.write("      exit 1\n")
      filename.write("fi\n")
      filename.write("\n")
      filename.write("if [ $# -gt 0 ] && [ $# -lt 4 ] ; then\n")
      filename.write("     echo 'Not enough arguments provided'\n")
      filename.write("     exit 1\n")
      filename.write("fi\n")
      filename.write("\n")
      filename.write("if [[ $# -gt 4 ]] ; then\n")
      filename.write("    echo 'Too many arguments provided'\n")
      filename.write("    exit 1\n")
      filename.write("fi\n")
      filename.write("\n")
      filename.write('file_match=$file_token"*"$unit_name\n')
      filename.write("files=()\n")
      filename.write("\n")
      filename.write("# get all the matching files\n")
      filename.write("for file in $file_match ; do\n")
      filename.write("    files+=($file)\n")
      filename.write("done\n")
      filename.write("\n")
      filename.write("# get the number of files\n")
      filename.write("len=${#files[@]}\n")
      filename.write("\n")
      filename.write("# check for files\n")
      filename.write("if [ $len -eq 0 ] ; then\n")
      filename.write("    echo 'no files that match token', $file_token\n")
      filename.write("fi\n")
      filename.write("\n")
      filename.write("# otherwise write the job file\n")
      filename.write("for (( i = 0 ; i < $len ; i++ )) ; do\n")
      filename.write("    echo ${files[$i]} >> instructions\n")
      filename.write("done\n")
      filename.write("echo " " >> instructions\n")
      filename.write('echo $file_token"_"$2 >> instructions\n')
      filename.write("\n")
      filename.write("# process the file\n")
      filename.write('if [ $file_type == "usrbin" ] ; then\n')
      filename.write("    $FLUPRO/flutil/usbsuw < instructions\n")
      filename.write("fi\n")
      filename.write('if [ $file_type == "usrtrack" ] ; then\n')
      filename.write("    $FLUPRO/flutil/ustsuw < instructions\n")
      filename.write("fi\n")
      filename.write('if [ $file_type == "usrbdx" ] ; then\n')
      filename.write("    $FLUPRO/flutil/usxsuw < instructions\n")
      filename.write("fi\n")
      filename.write('if [ $file_type == "resnuclei" ] ; then\n')
      filename.write("    $FLUPRO/flutil/usrsuw < instructions\n")
      filename.write("fi\n")
      filename.write('if [ $file_type == "yield" ] ; then\n')
      filename.write("    $FLUPRO/flutil/usysuw < instructions\n")
      filename.write("fi\n")
      filename.write("\n")
      filename.write("# cleanup\n")
      filename.write("rm instructions\n")
      filename.write("}\n")
      return

def build_job_cmd_file():
      """ builds the command file for the job

      Parameters
      ----------
      inputfile: string : name of the input file the command file is being built for
      run_index: int : the integer id of the run
      
      Returns
      ----------
      nothing: writes out job command file
      """  
      file_name = "combine_fluka.cmd"
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
      file.write("executable = combine_fluka.sh\n")
      file.write(" \n")
      file.write("# Require execute servers that have Gluster:\n")
      file.write("Requirements = (Target.HasGluster == true)\n")
      file.write("copy_to_spool = false \n")
      file.write("should_transfer_files = yes \n")
      file.write("when_to_transfer_output = on_exit \n")
      file.write("output = combine_fluka.out\n")
      file.write("log = combine_fluka.log\n")     
      file.write("error = combine_fluka.err\n")
      file.write("transfer_input_files = combine_fluka.sh\n")
      file.write("+AccountingGroup = EngrPhysics_Wilson \n")
      file.write("request_cpus = 1\n")
      file.write("request_memory = 12GB\n")
      file.write("request_disk = 200GB\n")
      file.write("Queue \n")
      file.close()

      return

def build_run_script(username,tardir_name,scores,filename,output):
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
      file_name = "combine_fluka.sh"
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

      write_collapse_fluka(file)

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
      file.write("# copy the dependencies\n")        
      file.write("cp /mnt/gluster/"+username+"/tar_install/*.tar.gz . \n")
      file.write("# unpack the dependencies - note the below command is purposeful\n")  
      file.write("ls /mnt/gluster/"+username+"/tar_install/ | xargs -i tar -zxf {}\n")

      # always set the env
      file.write("# set all the library paths\n")  
      file.write("set_env\n")
      file.write("# get and set the required fluka paths \n")
      file.write("export FLUPRO=$PWD/fluka/bin \n")
      
      # get the data to process
      file.write("mkdir data_process\n")
      file.write("cp /mnt/gluster/"+username+"/"+tardir_name+"/* data_process/.\n") #copy all tarballs
      # unpack the tarballs
      file.write("cd data_process\n")
      file.write("ls /mnt/gluster/"+username+"/"+tardir_name+" | xargs -i tar -zxf {} \n")
      # print the tallies to process
      process_options = print_input(scores,filename,output)
      # close the file
      for item in process_options:
            file.write("collapse_fluka "+item)

      # now tidy up
      file.write("tar -pczf combined_data.tar.gz "+output+"*\n")
      file.write("mv combined_data.tar.gz ../. \n")
      file.write("cd ..\n")
      
      # clean up before we leave this computer, delete everything but results
      file.write("ls | grep -v combined_data.tar.gz | xargs rm -rf"+"\n")
      # move it to gluster
      file.write("mv combined_data.tar.gz /mnt/gluster/"+username+"/"+tardir_name+"/.\n")
      file.close()

      return

# read the file
def read_file(filename):
    with open(filename) as f:
        file = f.readlines()
    return file

# get all the scores in the file
def get_scores(file):
    scores = {}
    for score in fluka_scores:
        matches = [s for s in file if score in s]
        # remove every second line
        sorted = []
        for i in range(0,len(matches),2):
            if matches[i].split()[3] not in sorted:
                sorted.append(matches[i].split()[3])
        scores[score] = sorted
    return scores

# print the data for fluka combine:
# scores = dictionary of score type and array of unit number
# filename = name of the input deck - in order to guess the output filenames
# output = name of the output file to use
def print_input(scores,filename,output):
    # get the token of the input file
    input_file = filename[:-4]
    options=[]
    for data in scores.keys():
        usr_scores = scores[data]
        for item in usr_scores:
           # turn the unit number into a +ve int
           # prepend _ to input file, as this is what split fluka does
           options.append("_"+input_file+" "+str(int(float(item)*-1.0))+" "+data.lower()+" "+output+"\n")  
    #       print input_file,int(float(item)*-1.0),data.lower(),output
            
    return options

filename = ""
username = ""
output = ""
tardirname = ""

# early exit
if (len(sys.argv) < 2):
    print "No arguments provided"
    sys.exit()

# loop over the args and check for the keywords    
for arg in range(1,len(sys.argv)):
    if "--input" in sys.argv[arg]:
        filename = sys.argv[arg+1]
    if "--user" in sys.argv[arg]:
        username = sys.argv[arg+1]
    if "--output" in sys.argv[arg]:
        output = sys.argv[arg+1]
    if "--dirname" in sys.argv[arg]:
        tardirname = sys.argv[arg+1]

if username == "":
    print "No username provided"
    sys.exit()

if filename == "":
    print "No filename provided"
    sys.exit()

if tardirname == "":
    print "No directory name provided"
    sys.exit()

if output == "":
    print "No output filename set"
    sys.exit()

# read the input deck into memory
file = read_file(filename)
# get all the scoring options used
scores = get_scores(file)
# build the job command file
build_job_cmd_file()
# build the job script
build_run_script(username,tardirname,scores,filename,output)


