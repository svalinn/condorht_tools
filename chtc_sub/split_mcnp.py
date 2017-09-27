#!/usr/bin/python

import os
import sys
import shutil
import argparse

from subprocess import call

# takes string, and if last char is '/' removes it
def remove_slash(string):
    """ removes the trailing '/'

    Parameters
    -------------
    string :: string :: typically a directory path to remove trailing / from

    Returns string, either changed or not
    --------------
    """
    last_char = len(string)
    if string[last_char-1] == '/':
        string=string[:-1]

    return string

def create_mcnp_input(input_dir,mcnp_input,rundir,run_num):
    """
    function to create mcnp input deck to generate a runtpe appropriate for the problem for example,
    with advanced tallies we need to pass a new output filename for the mesh tally mesh file. So very simply
    if there is no dagmc mentioned in the mcnp input deck then we can simply copy the runtpe file by running the
    normal input deck without modification.

    Arguments
    --------------
    input_dir: string : directory containg the mcnp input
    input: string : name of the mcnp input file
    rundir: string : directory of the run
    run_num: int : the run index

    Returns
    --------------
    nps : int :: the number of particles to simulate
    """
 
    nps = 0 
    
    dagmc_t=False
    out_t=False

    shutil.copy(mcnp_input,input_dir+'/'+mcnp_input)


    # open the mcnp input file and look for the phrase "dagmc" if absent then we 
    # have no advanced tallies
    try:
        file = open(mcnp_input)

    except:
        print input_dir+'/'+mcnp_input
        print "Could not open the input file, ",mcnp_input," in directory ", input_dir
        sys.exit()

    while 1:
        line = file.readline()
        # we treat #'s as comments
        if not line:
            break
        if 'nps' or 'NPS' in line:
            nps_t = True
            for token in line.split():
                if "nps" in token:
                    print token
                    pos_in = token.find('s')
                    nps = int(float(line[pos_in+1:len(line)]))
        if 'dagmc' in line:
            dagmc_t=True
            if 'inp=' in line:
                pos_eq = line.find('=')
                mesh_name = line[pos_eq+1:len(line)-1]
        if dagmc_t:
            if 'out' in line:
                out_t=True
                break
                
        # at this juncture we may wish to also check the file pointed to by the dagmc keyword. 
        # some users like to use damgc file= to send the data to. However, currently we will 
        # fail unless we find the out

        # now we can either have dagmc_t = True/False, if dagmc_t then out can be either t or f
    if not dagmc_t:
        # normal mcnp run
        try:
            shutil.copy(mcnp_input,input_dir+'/'+mcnp_input+str(run_num))
        except:
            print mcnp_input, ' to ',  input_dir+mcnp_input+str(run_num)
            print "could not copy file"
            sys.exit()
    elif dagmc_t and not out_t:
        print "dagmc present but output not specified, fail!"
        exit()
    elif dagmc_t and out_t:
        print "mcnp run with advcancec tallyt"
        try:
#           print input_dir+mesh_name
 #          print rundir+mesh_name
            shutil.copy(mesh_name,input_dir+'/'+mesh_name)

        except:
            print "could not find the  mesh file", mesh_name
            sys.exit()

        # mcnp run with advanced tally
        file = open(mcnp_input)
        ofile = open(input_dir+'/'+mcnp_input+str(run_num),'w')
        while 1:
            line = file.readline()
            if not line:
                break
            else:
                if 'out' in line:
                    # if 'out' in line modify and add mesh file number to end
                    # this ensures uniqueness to mesh filename
                    pos=line.find('.h5m')
                    ofile.write('  '+line[0:pos]+str(run_num)+line[pos:len(line)])
                else:
                    # if not line containing 'out' dump the line straight to file
                    ofile.write(line)

        # close the file
        ofile.close()

    if not nps_t:
        print "NPS is not specified in the input file"
        print "This script is not compatable with ctme"
        sys.exit()
        
    return nps

def run_mcnp_input(mcnp_command):
    """
    Function that runs the mcnp input pointed to, to produce the runtpe file with the correct
    data stored.

    Arguments
    --------------
    rundir : string : directory of the run
    mcnp_commands: string :: string containg the command to run the problem
    mcnp_exec: string :: command to run mcnp
    run_num: int : the run index

    Returns
    --------------
    Nothing
    """
    
    print mcnp_command
#    sys.exit()
    os.system(mcnp_command+' ix')
    os.system("rm -rf outp")
    os.makedirs('runtpes')     
    os.system("mv runtpe runtpes/run1") #move the runtpe file to the runtpe directory
       
    return


    working_dir=os.getcwd() #copy cwd

    os.chdir(rundir) #move to run dir
    print "rundir = ", rundir
    print mcnp_commands
#    sys.exit()
    os.system(mcnp_exec+' ix '+mcnp_commands)
    os.system("rm -rf outp")
    # ensure the runtpe was produced

    

    # get dag file from 

    if not os.path.isfile(rundir+'/run'+str(run_number)):
        print input_dir+'/run'+str(run_number)
        print "There was a problem producing the runtpe, please check output messages"
        sys.exit()
    else:
        # move the runtpe file
        if not os.path.exists('../runtpes'): #check is exists
            os.makedirs('../runtpes')     
        os.system("mv run1 ../runtpes/.") #move the runtpe file to the runtpe directory

    for token in mcnp_commands.split():
        if "i=" in token:
            input_name = token[2:len(token)]
            os.system('rm '+input_name)             # remove the created output file

    os.chdir('..') #go back to original cwd
    return

def generate_runtapes(num_cpus,input_dir,rundir,seed,mcnp_command,instructions,nps):
    """
    Arguments
    --------------------
    num_cpus - the number of cpu's the problem will be divided into
    input_dir - the directory containing the input deck
    rundir - the directory where the run will take place
    seed : int :: seed the rn seed of the problem
    mcnp_command : string :: command to launch mcnp 
    instructions : string :: commands to pass to mcnp

    Returns
    --------------------
    Nothing
    """

    # run the problem generate seed runtpe file 
    run_mcnp_input(mcnp_command)  

    # builds the continue run files
    for i in range(1,num_cpus+1):
        mcnp_fname = "job" + str(i)
        if not os.path.exists(input_dir+'/input'):
            os.mkdir(input_dir+'/input')
        generate_mcnp_inputs(input_dir+'/input',mcnp_fname,i,num_cpus,nps,seed)

    return

def generate_mcnp_inputs(rundir,mcnpfname,cpu_id,n_cpu,nps,seed):
    """
    Script to take the mcnp input file pointed to in order to stratify the input deck into
    a given number of parts determined by how many cpu's we would wish to run on

    Arguments
    --------------------
    rundir : string :: the directory where the run will take place
    mcnpfname : string :: mcnpfilename
    cpu_id : int :: run index
    num_cpus - the number of cpu's the problem will be divided into
    nps : int :: the number of particles to simulate
    seed : int :: the starting random number seed

    Returns
    --------------------
    Nothing
    """

    file = open(rundir+'/'+mcnpfname,'w')

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
        num2run = (int(nps) - (int(nps)/int(n_cpu)*int(n_cpu)) + (int(nps)/int(n_cpu)))
        file.write("nps "+str(num2run)+"\n")

    # turn on mctal dumping
    file.write("prdmp "+str(num2run)+" "+str(num2run)+" 2 2j")

    file.close()
    
    return

# creates directory to store copy of input file
# and copies file to it
def copy_and_create(input_dir,new_dir,file_copy):
    print "Copying file ", file_copy
    print "From ", input_dir
    print "To ", new_dir
    
    try:
        os.mkdir(input_dir+'/'+new_dir)
    except:
        pass
    
    shutil.copy(input_dir+'/'+file_copy,input_dir+'/'+new_dir+'/'+file_copy)

# opens the mcnp input deck and scans for 
# dagmc tally commands
def check_advanced_tally(input_dir,mcnp_input):
    mesh_files = set()
    # already checked for existence
    f = open(input_dir+'/'+mcnp_input,'r')
    for line in f:
        if all(x in line for x in ['fc','dagmc','inp']):
            for token in line.split():
                if "inp=" in token:
                    pos_in = token.find('=')
                    file = token[pos_in+1:len(token)]
                    mesh_files.add(file)

    # now if meshes exist copy the files to meshes directory
    for mesh in mesh_files:
        copy_and_create(input_dir,"meshes",mesh)

    return mesh_files

def check_and_setup(mcnp_cmd,input_dir):
    print "check_and_setup", mcnp_cmd

    # all input_files
    inputs = set()

    dag_run = False


    # check for various command features
    if "l=" in mcnp_cmd:
        dag_run = True
        # step through bits looking for g=
        print "bob", mcnp_cmd
        for token in mcnp_cmd.split():
            if "l=" in token:
                pos_in = token.find('=')
                lcad_file = token[pos_in+1:len(token)]
                inputs.add(lcad_file)
                print lcad_file
                
        # check to see if the file exists
        if not os.path.isfile(input_dir+'/'+lcad_file):
            print "The dag file specified, ",lcad_file," does not exist"
            sys.exit()

        copy_and_create(input_dir,"lcad",lcad_file)

    
    # check for various command features
    if "g=" in mcnp_cmd:
        dag_run = True
        # step through bits looking for g=
        print "bob", mcnp_cmd
        for token in mcnp_cmd.split():
            if "g=" in token:
                pos_in = token.find('=')
                dag_file = token[pos_in+1:len(token)]
                inputs.add(dag_file)
                print dag_file
                
        # check to see if the file exists
        if not os.path.isfile(input_dir+'/'+dag_file):
            print "The dag file specified, ",dag_file," does not exist"
            sys.exit()

        copy_and_create(input_dir,"geometry",dag_file)

    wwinp = False
    if "wwinp=" in mcnp_cmd or "w=" in mcnp_cmd:
        wwinp = True
        # step through bits looking for wwinp
        for token in mcnp_cmd.split():
            if "wwinp=" in token or "w=" in token:
                pos_in = token.find('=')
                wwinp_file = token[pos_in+1:len(token)]
                inputs.add(wwinp_file)
                # check to see if the file exists

        if not os.path.isfile(input_dir+'/'+wwinp_file):
            print "The wwinp file specified, ",input_dir+'/'+wwinp_file," does not exist"
            sys.exit()
        # create wwinp dir
        copy_and_create(input_dir,"wwinp",wwinp_file)


    if "i=" in mcnp_cmd:
        input = True
        # step through bits looking for i=
        for token in mcnp_cmd.split():
            print token
            if "i=" in token:
                pos_in = token.find('=')
                mcnp_input = token[pos_in+1:len(token)]
                inputs.add(mcnp_input)
                print mcnp_input
                # check to see if the file exists
        if not os.path.isfile(input_dir+'/'+mcnp_input):
            print input_dir+'/'+mcnp_input
            print "The mcnp input file specified, ",mcnp_input," does not exist"
            sys.exit()

        if not input:
            print "mcnp input deck not specified"
            sys.exit()

        meshes = check_advanced_tally(input_dir,mcnp_input)
        if len(meshes) > 0:
            for mesh in meshes:
                inputs.add(mesh)

    calc_config="mcnp5 calculation with"
    if not wwinp:
        calc_config+="out wwinp"
    else:
        calc_config+=" wwinp"
            
    if dag_run:
        calc_config+=" with DAG"

    return inputs

################################################### 
# Python script to take starting mcnp input deck  #
# and chop into a number of runs ready for condor #
###################################################  
# start

parser = argparse.ArgumentParser(description = 'Splits a MCNP input file into several input decks, with a strided seed and rand card so that it is equivalent to a MCNP input problem with a single run')
parser.add_argument('--mcnp','-m',type=str,help='The MCNP command used to run the problem, this is needed so as to produce a number of runtpe files', required = True)
parser.add_argument('--cpu', '-c', type=int, help='The number of CPU\'s the problem will run on', required=True)
parser.add_argument('--seed', '-s', type=int, help='The starting random number seed, the default is 12512813139')
parser.add_argument('--nps','-n', type=int, help='The number of particles to simulate',required=True)
        
args = parser.parse_args()

# input dir is always the
input_dir = os.getcwd()

# get the mcnp command
instructions=""

# get the individual tokens, like i= g= etc
for token in args.mcnp.split():
    if "mcnp" in token:
        mcnp_command = token
    else:
        instructions+=token+" "

# check and setup directories and inputs
inputs = check_and_setup(args.mcnp,input_dir)

# if seed not defined
if not args.seed:
    seed = 12512813139
else:
    seed = args.seed

# generate runtpe files
rundir=input_dir+"/runtpes"
generate_runtapes(args.cpu,input_dir,rundir,seed,args.mcnp,instructions,args.nps)


