#!/usr/bin/python

import sys
from os import listdir
from os.path import isfile, join
from os import system
import re
import getpass

## script to take a given directory, get the run files and determine the DAG graph to collapse the data
## down into its averaged parts

def build_graph(file_list):
    """
    builds a dot graph of the file collapse hierarchy
    
    Parameters
    ----------
    file_list : string[][] :: array of files produced by generation
    
    Returns
    ---------
    Nothing

    """
    file_name = "graph.dot"
    try:
        file = open(file_name,'w')
    except:
        print "Could not open file ", file_name, " to write to"
        exit()
    else:
        pass 

    file.write("digraph G {")
    # loop over files in this generation
    for i in range(1,len(file_list)):
        j=0
        for j in range(0,len(file_list[i])):
            file.write('"'+file_list[i-1][2*j]+'"->"'+file_list[i][j]+'"')
            file.write('"'+file_list[i-1][(2*j)+1]+'"->"'+file_list[i][j]+'"')
    file.write('}')
    file.close()
    return


def get_username():
    """ determines user name

    Paramaters
    ----------
    null
    
    Returns
    ---------
    username :: string
    """

    return getpass.getuser()

def get_generation_iteration(tar_gz_name):
    """ determines the generation and iteration number given the filename

    Paramaters
    ----------
    tar_gz_name : string : filename of the tar_gz_file
    
    Returns
    ---------
    gen : integer : generation number
    iteration : integer : iteration number
    """
    
    name = tar_gz_name
    name = name.split("_")
    gen = name[1]
    part_2 = name[2]
    part_2 = part_2.split(".")
    iteration = part_2[0]

    return (gen,iteration)


def num_2_alpha(integer):
    """ takes an interger and encodes to letter 

    Paramaters
    ----------
    integer :: integer :: (0-25)
    
    Returns
    ---------
    character
    """

    return chr(97+integer-1)


def build_dag_graph(dag_names):
    """
    Builds the DAG graph of the problem set
    Parameters
    ----------
    dag_graph :: list of lists :: contains the names of the DAG jobs
    
    Returns
    ---------
    Nothing

    """

    file_name = "dagman.dag"
    try:
        file = open(file_name,'w')
    except:
        print "Could not open file ", file_name, " to write to"
        exit()
    else:
        pass 
    
    job_names=[]

    # create alias list of job names for DAG
    for i in range(0,len(dag_names)):
        job_names.append([])
        for j in range(0,len(dag_names[i])):
            job_names[i].append("job_"+str(i)+"_"+str(j))
            file.write("JOB "+job_names[i][j]+" "+dag_names[i][j]+"\n")

            
    # determine when we get an odd job (add to next generation)
    counter_a=0
    for i in range(0,len(dag_names)):
        for j in range(0,len(dag_names[i])):
            pass
        # if we have an odd number
        if len(dag_names[i])%2 == 1 and counter_a == 0:
            remainder = job_names[i][j]
            counter_a += 1
            print remainder

    count = 0
    for i in range(1,len(dag_names)):
        for j in range(0,len(dag_names[i])):
#            print "PARENT "+dag_names[i-1][2*j]+" "+dag_names[i-1][(2*j)+1]+" CHILD "+dag_names[i][j]
            file.write("PARENT "+job_names[i-1][2*j]+" "+job_names[i-1][(2*j)+1]+" CHILD "+job_names[i][j]+"\n")

        if len(dag_names[i])%2 == 1:
            count+=1
        if len(dag_names[i])%2 == 1 and count == 2:
            job_names[i].append(remainder)


    file.close() #close the dagman file
    return

"""
def build_dag_graph(dag_names):

    Builds the DAG graph of the problem set
    Parameters
    ----------
    dag_graph :: list of lists :: contains the names of the DAG jobs
    
    Returns
    ---------
    Nothing



    file_name = "dagman.dag"
    try:
        file = open(file_name,'w')
    except:
        print "Could not open file ", file_name, " to write to"
        exit()
    else:
        pass 
    
    for gen in range(0,len(dag_names)):
        for entry in range(0,(len(dag_names[gen]))/2):
            file.write("PARENT "+dag_names[gen][2*entry]+" "+dag_names[gen][(2*entry)+1]+" CHILD "+dag_names[gen+1][entry]+"\n")

    file.close()
"""

def build_dag_names(gen,number_batch,list_of_names):
    """ Builds the list of DAG jobs of the problem from the input set 

    Parameters
    ----------
    gen :: int :: generation number in the graph
    number_batch :: int :: number in the batch
    list_of_names :: list :: names of the dag elements

    Returns
    ----------
    
    """

    list_of_names.append([])
    for i in range(1,number_batch+1):
        gen_name = num_2_alpha(gen)
        string="job"+gen_name+str(i)
        list_of_names[gen-1].append(string)

    return list_of_names


def left_over(list_of_files):
    """ determines if we have an even or odd number of files in this generation
    
    Parameters
    ----------
    list_of_files : string[] :: list of files produced in the last generation
    
    Returns
    ----------
    number of files produced in the last generation
    """
    if(len(list_of_files)%2 != 0):
           return 1
    else:
           return 0

def generation(files,name,path_data,gen):
    """ prints the files to be combined in this generation
    
    Parameters
    ----------
    files : string[array] :: list of file names
    name : string :: file name to append
    path_data : string :: path to the file to create

    Returns
    ----------
    nothing

    """  

    # following the first batch will have files names
    # there will be len(files)/2 to create

    files = get_results(name,path_data)

    if (len(files) % 2) != 0:
        add_file=(len(files)/2)+1
        # in order to copy file
        name=''
        for i in range(0,gen):
            name+="_1"
        name+="_combined.tar.gz"
        touch_file(str(add_file)+name)
        remaining_files = (len(files)/2)+1
    else:
        remainder = len(files)/2
        remaining_files = (len(files)/2)       

    name=''
    for i in range(0,gen):
        name+="_1"
    name+="_combined.tar.gz"

    gen_files(name,len(files)/2)
    gen+=1

    return (gen,remaining_files)


def gen_files(name,num):
    for i in range(0,num):
        touch_file(str(i+1)+name)
    return


def touch_file(filename):
    """ prints instructions on how to use
    
    Parameters
    ----------
    filename : string :: filename of file to create

    Returns
    ----------
    nothing
    """
    system("touch "+filename)

    return


def build_job_cmd_file(filename,gen,job_index):
      """ builds the command file for the job

      Parameters
      ----------
      inputfile: string : name of the input file the command file is being built for
      gen : int :: generation number
      run_index: int : the integer id of the run
      
      Returns
      ----------
      nothing: writes out job command file
      """  
      file_name = filename
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
      file.write("#  Combine script automatically created   # \n")
      file.write("#                                         # \n")
      file.write("########################################### \n")
      
      file.write(" \n")
      if gen == 0:
          file.write("executable = combine_"+str(job_index)+".sh \n")
      else:
          file.write("executable = combine_"+str(gen)+"_"+str(job_index)+".sh \n")

      file.write(" \n")
      file.write("copy_to_spool = false \n")
      file.write("should_transfer_files = yes \n")
      file.write("when_to_transfer_output = on_exit \n")
      if gen == 0:
          file.write("output = combine_"+str(job_index)+".out\n")
      else:
          file.write("output = combine_"+str(gen)+"_"+str(job_index)+".out\n")

      if gen == 0:
          file.write("error = combine_"+str(job_index)+".err\n")
      else:
          file.write("error = combine_"+str(gen)+"_"+str(job_index)+".err\n")

      if gen == 0:
          file.write("transfer_input_files = combine_"+str(job_index)+".sh\n")
      else:
          file.write("transfer_input_files = combine_"+str(gen)+"_"+str(job_index)+".sh\n")

      file.write("+AccountingGroup = EngrPhysics_Wilson \n")
      
      file.write("Queue \n")
      file.close()

      return

def build_combine_script(filename,gen,count,code_type,code_options,username,files):
      """ builds the script to combine the MC data

      Parameters
      ----------
      filename : string :: name of the input file the command file is being built for
      code_type : string :: type of code (MCNP, FLUKA)
      code_options : string[n] :: options associated with the code type
      username : string :: username
      files: string[2] :: name of the results tar.gz to combine

      Returns
      ----------
      collapse_files :: string :: name of the resultant collapse files
      """  

      file_name = filename
      try:
          file = open(file_name,'w')
      except:
          print "Could not open file ", file_name, " to write to"
          exit()
      else:
          pass

      collapse_files=[]

      if "MCNP" in code_type:
          meshtal = False
          mctal = False
          for option in code_options:
              if "mctal" in option:
                  mctal = True
              if "meshtal" in option:
                  meshtal = True
                  

          file.write("#!/bin/bash"+"\n")         
          file.write("# get_until_got function - keeps trying to get file with wget \n")
          file.write("# until its successful \n")
          file.write("get_until_got(){ \n")
#          wget -c -t 5 --waitretry=20 --read-timeout=10
          file.write("wget -c -t 5 --waitretry=20 --read-timeout=10 $1 \n")
          file.write("}\n")
          file.write("cwd=$PWD\n")
          file.write("# copy the data to compress\n")
#          print files[0],files[1]
          file.write("get_until_got http://proxy.chtc.wisc.edu/SQUID/"+username+"/"+files[0]+"  \n")
          file.write("get_until_got http://proxy.chtc.wisc.edu/SQUID/"+username+"/"+files[1]+"  \n")
          file.write("# get the merge tools \n")
          file.write("get_until_got http://proxy.chtc.wisc.edu/SQUID/"+username+"/"+"merge_tools.tar.gz \n")
          file.write("# unzip the data files\n")
          file.write("tar -zxf "+files[0]+" \n")
          file.write("tar -zxf "+files[1]+" \n")
          file.write("# unzip the merge tools \n")
          file.write("tar -zxf merge_tools.tar.gz \n")
          file.write("# combine the mctal files \n")
          
          dir_name = []
          name = files[0]
          name=name.split("_")
          dir_name.append(name[0])
          name = files[1]
          name=name.split("_")                  
          dir_name.append(name[0])


          if gen == 0:
              if mctal:
                  file.write("# merge the mctal \n")
                  file.write("./mctal_combine.py -o combined_"+str(gen)+"_"+str(count)+".m "+dir_name[0]+"/"+dir_name[0]+".m "+dir_name[1]+"/"+dir_name[1]+".m \n")
              if meshtal:
                  file.write("# merge the meshtal \n")
                  file.write("./meshtal_combine.py -o mesh_combined_"+str(gen)+"_"+str(count)+".m "+dir_name[0]+"/meshtal "+dir_name[1]+"/meshtal \n")
              file.write("# zip up the output data \n")
              file.write("rm -rf "+dir_name[0]+" "+dir_name[1]+"\n")
              # create tar file
#              file.write("tar -pczf combined_"+str(gen)+"_"+str(count)+".tar.gz combined_"+str(gen)+"_"+str(count)+".m "+"mesh_combined_"+str(gen)+"_"+str(count)+" \n")
              # pack up the the data
              file.write("tar -cvf combined_"+str(gen)+"_"+str(count)+".tar --files-from=/dev/null\n") # creates the tar file
              if mctal:
                  file.write("tar -rvf combined_"+str(gen)+"_"+str(count)+".tar combined_"+str(gen)+"_"+str(count)+".m \n") #add the mctal if it exists
              if meshtal:
                  file.write("tar -rvf combined_"+str(gen)+"_"+str(count)+".tar mesh_combined_"+str(gen)+"_"+str(count)+".m \n") #add the meshtal if it exists
              file.write("gzip combined_"+str(gen)+"_"+str(count)+".tar \n") # zips the file
               # add this ot the collapsed filesnames
              collapse_files="combined_"+str(gen)+"_"+str(count)+".tar.gz" 
          else:
              (gen1,iter1)=get_generation_iteration(files[0])
              (gen2,iter2)=get_generation_iteration(files[1])
              if mctal:
                  file.write("# merge the mctal \n")
                  file.write("./mctal_combine.py -o combined_"+str(gen)+"_"+str(count)+".m combined_"+str(gen1)+"_"+str(iter1)+".m combined_"+str(gen2)+"_"+str(iter2)+".m \n")
              if meshtal:
                  file.write("# merge the meshtal \n")
                  file.write("./meshtal_combine.py -o mesh_combined_"+str(gen)+"_"+str(count)+" mesh_combined_"+str(gen1)+"_"+str(iter1)+" mesh_combined_"+str(gen2)+"_"+str(iter2)+" \n")
              file.write("# zip up the output data \n")
              file.write("rm -rf "+dir_name[0]+" "+dir_name[1]+"\n")
              # pack up the combined results
              file.write("tar -cvf combined_"+str(gen)+"_"+str(count)+".tar --files-from=/dev/null \n") # creates an empty the tar file
              if mctal:
                  file.write("tar -rvf combined_"+str(gen)+"_"+str(count)+".tar combined_"+str(gen)+"_"+str(count)+".m \n") #add the mctal if it exists
              if meshtal:
                  file.write("tar -rvf combined_"+str(gen)+"_"+str(count)+".tar mesh_combined_"+str(gen)+"_"+str(count)+".m \n") #add the meshtal if it exists
              file.write("gzip combined_"+str(gen)+"_"+str(count)+".tar \n") # zips the file
#              file.write("tar -pczf combined_"+str(gen)+"_"+str(count)+".tar.gz combined_"+str(gen)+"_"+str(count)+".m "+"mesh_combined_"+str(gen)+"_"+str(count)+" \n")
              collapse_files="combined_"+str(gen)+"_"+str(count)+".tar.gz"
              
          file.write("ls | grep -v combined_"+str(gen)+"_"+str(count)+".tar.gz | xargs rm -rf \n")
          file.close()

          return collapse_files

      if "FLUKA" in code_type:
          return
      return

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
    print "--type <type of data>"
    print "--batch < number to collapse per session>"
    print " "
    sys.exit()

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

def numericalSort(value):
    numbers = re.compile(r'(\d+)')
    parts = numbers.split(value)
    parts[1::2] = map(int, parts[1::2])
    return parts

def get_results(search_string,dir_path):
    """ determines the initial results files to condense, takes dirpath as arg
    
    Parameters
    ----------
    search_string : string :: string to search for
    dirpath : string :: path to all the output data

    Returns
    ----------
    no_res : string [list] :: list of all files in direcotry dir_path that have the word "results" somehwere in the anme
    """
    
    print dir_path

    try:
        test_string = listdir(dir_path)
    except:
        print dir_path," not a valid path"
        exit()
    else:
        list_of_files = [ f for f in listdir(dir_path) if isfile(join(dir_path,f))]

        list_of_files = sorted(list_of_files,key = numericalSort)
        print list_of_files

        
    # remove those that dont have "results" 
    no_res = [ f for f in list_of_files if search_string in f ]
        
    return no_res


############################################################
#
# Python script to collect and launch jobs that process the output data
# of split mcnp or flukar runs to determine the appropriate averaged
# quantities
# 
###########################################################

print 'Number of arguments:', len(sys.argv), 'arguments.'
print 'Argument List:', str(sys.argv)

if len(sys.argv) <= 2:
    print_help()
    sys.exit()

# check to see if help has been asked for first
for arg in range(0,len(sys.argv)):
    if '--help'  in sys.argv[arg]:
        print_help()
        sys.exit()

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

# used for filenaming conventions
user_name = get_username()

# for the DAG 
dag_names=[]

# get the inputs to combine
files = get_results("results.tar.gz",path_data)
count=0
#(gen,remaining)=generation(files,"results.tar.gz",path_data,0)
collapse_files=[]
gen=0

command_list=[]
command_list.append([])

job_options=[]
job_options.append("mctal")

#### from here
file_list=[]
for i in range(0,len(files)):
    file_list.append([])
    file_list[0].append(files[i])
#### to here is used to produce data for graph plot

# first generation 
for file in range(0,len(files)/2):
    count+=1
    job_files=[]
    filename = "combine_"+str(file+1)+".sh"
    # append targz to job_files is str[2]
    job_files.append(files[2*file])
    job_files.append(files[(2*file)+1])


    # get back list of new files,  and build script that combined its parents
    new_files = build_combine_script(filename,gen,count,job_type,job_options,user_name,job_files)

    ### used to produce graph plot
    file_list[1].append(new_files)
    ### used to produce graph plot

    collapse_files.append(new_files) # add files to list
    filename = "combine_"+str(file+1)+".cmd"
    build_job_cmd_file(filename,gen,count) # build the command file for this generation
    command_list[0].append(filename)

# while there are files to collapse
while len(collapse_files) > 1: 
    gen+=1
    next_gen_files=[]
    count = 0

    file_list.append([]) #list of files for dot graph
    command_list.append([]) # list of cmd files
    # loop over the files in this generation
    for file in range(0,len(collapse_files)/2):
        count+=1 #increment file counter
        filename = "combine_"+str(gen)+"_"+str(file+1)+".sh"
        job_files[0]=collapse_files[2*file]
        job_files[1]=collapse_files[(2*file)+1]
       
        # build the combine script
        new_files = build_combine_script(filename,gen,count,job_type,job_options,user_name,job_files)
        file_list[gen+1].append(new_files) #used to produce plot
        next_gen_files.append(new_files)
        filename = "combine_"+str(gen)+"_"+str(file+1)+".cmd"
        build_job_cmd_file(filename,gen,count)
        command_list[gen].append(filename)
    # copy the list of new files to that of the next generation
    if left_over(collapse_files) == 1:
        next_gen_files.append(collapse_files[len(collapse_files)-1]) #append the last one to the list

    # update the collapse files
    collapse_files = next_gen_files
#    sys.exit()
       

build_dag_graph(command_list)

#build_graph(file_list)

sys.exit()



