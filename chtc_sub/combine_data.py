#!/usr/bin/python

import sys
from os import listdir
from os.path import isfile, join
from os import system

import re
import getpass

class Job:
    def __init__(self):
        self.name = ""
        self.parent1 = ""
        self.parent2 = ""
        self.file1 = ""
        self.file2 = ""

        # data related to the writing of files
        self.filepath = ""
        self.code_type = ""
        self.code_options = []
        self.username = ""

    def set_filepath(self,filepath):
        self.filepath = filepath

    def set_code_type(self,code_type):
        self.code_type = code_type

    def set_code_options(self,code_options):
        self.code_options = code_options

    def set_username(self,username):
        self.username = username

    def set_name(self,name):
        self.name = name

    def set_output_name(self,name):
        self.output_name = name

    def set_parents(self,parent1,parent2):
        self.parent1 = parent1
        self.parent2 = parent2

    def set_child(self,child_name):
        self.child = child_name

    def set_files(self,file1,file2):
        self.file1 = file1
        self.file2 = file2

    # print the job name line of a CONDOR job file
    def print_dag_line(self,filestream):
        filestream.write("JOB "+self.name+" "+self.name+".cmd\n")
        filestream.write("RETRY "+self.name+" 5\n")

    # print the parent child line of a CONDOR DAG file
    def print_parent_child_line(self,filestream):
        # it may be the case that either parent may have job"
        # in the name, if this is the case then there is really 
        # only one parent
        filestream.write("PARENT ")
        if "job" not in self.parent1:
            filestream.write(self.parent1+" ")
        if "job" not in self.parent2:
            filestream.write(self.parent2+" ")
        filestream.write("CHILD "+self.name+"\n")

    def write_job_script(self):

        """ builds the script to combine the MC data

        Parameters
        ----------
        code_type : string :: type of code (MCNP, FLUKA)
        code_options : string[n] :: options associated with the code type
        username : string :: username
        """        

        try:
            file = open(self.name+".sh",'w')
        except:
            print "Could not open file ", file_name, " to write to"
            exit()
        else:
            pass

        if "MCNP" in self.code_type:
            meshtal = False
            mctal = False
            for option in self.code_options:
                if "mctal" in option:
                    mctal = True
                if "meshtal" in option:
                    meshtal = True
                  

        file.write("#!/bin/bash"+"\n")         
        file.write("# get_until_got function - keeps trying to get file with wget \n")
        file.write("# until its successful \n")
        file.write("get_until_got(){ \n")
        file.write("wget -c -t 5 --waitretry=20 --read-timeout=10 $1 \n")
        file.write("}\n")
        file.write("cwd=$PWD\n")
        file.write("# copy the data to compress\n")

        if filesystem == "squid":
            file.write("get_until_got http://proxy.chtc.wisc.edu/SQUID/"+username+"/"+self.file1+"  \n")
            file.write("get_until_got http://proxy.chtc.wisc.edu/SQUID/"+username+"/"+self.file2+"  \n")
            file.write("# get the merge tools \n")
            file.write("get_until_got http://proxy.chtc.wisc.edu/SQUID/"+username+"/"+"merge_tools.tar.gz \n")
            file.write("# unzip the merge tools \n")
            file.write("tar -zxf merge_tools.tar.gz \n")

        if filesystem == "gluster":
            file.write("cp "+self.filepath+"/"+self.file1+" .\n")
            file.write("cp "+self.filepath+"/"+self.file2+" .\n")

        file.write("# get the merge tools \n")
        file.write("git clone https://github.com/svalinn/condorht_tools.git\n")
        file.write("cp $PWD/condorht_tools/combine/meshtal_combine.py . \n")
        file.write("cp $PWD/condorht_tools/combine/mctal_combine.py . \n")

        file.write("# unzip the data files\n")
        file.write("tar -zxf "+self.file1+" \n")
        file.write("tar -zxf "+self.file2+" \n")

        file.write("# combine the mctal files \n")

        if "job" in self.file1:
            pos_under = self.file1.index("_")
            file1 = self.file1[0:pos_under]+"/meshtal"
        else:
            file1 = "mesh_"+self.file1[:-7]+".m"
        
        if "job" in self.file2:
            pos_under = self.file2.index("_")
            file2 = self.file2[0:pos_under]+"/meshtal"
        else:
            file2 = "mesh_"+self.file2[:-7]+".m"

        # set the common output stem
        outputfile_stem = self.output_name

        if mctal:
            file.write("# merge the mctal \n")
            file.write("./mctal_combine.py -o "+outputfile_stem+".m "+dir_name[0]+"/"+dir_name[0]+".m "+dir_name[1]+"/"+dir_name[1]+".m \n")
        if meshtal:
            file.write("# merge the meshtal \n")
            file.write("./meshtal_combine.py -o mesh_"+outputfile_stem+".m -s --avg "+file1+" "+file2+" \n")


        # check to make sure that data was produced
        if mctal:
            file.write("if [ ! -s "+outputfile_stem+".m ] ; then \n")
            file.write("    rm -rf *\n")
            file.write("    echo 'mctal file not found'\n")
            file.write("    exit 1\n")
            file.write("fi\n")
        if meshtal:
            file.write("if [ ! -s mesh_"+outputfile_stem+".m ] ; then \n")
            file.write("    rm -rf *\n")
            file.write("    echo 'meshtal file not found'\n")
            file.write("    exit 1\n")
            file.write("fi\n")

        # create tar file
        file.write("tar -cvf "+outputfile_stem+".tar --files-from=/dev/null\n") # creates the tar file
        if mctal:
            file.write("tar -rvf "+outputfile_stem+".tar "+outputfile_stem+".m \n") #add the mctal if it exists
        if meshtal:
            file.write("tar -rvf "+outputfile_stem+".tar mesh_"+outputfile_stem+".m \n") #add the meshtal if it exists
        # pack up the the data
        file.write("gzip "+outputfile_stem+".tar \n") # zips the file

        # add this ot the collapsed filesnames
        file.write("ls | grep -v "+outputfile_stem+".tar.gz | xargs rm -rf \n")
        file.write("mv "+outputfile_stem+".tar.gz "+self.filepath+"\n")
        file.close()

        if "FLUKA" in self.code_type:
            return

    def write_command_file(self):
        """ builds the command file for the job
        
        Parameters
        ----------
        nothing: all stored in self
        
        Returns
        ----------
        nothing: writes out job command file
        """  

        try:
            file = open(self.name+".cmd",'w')
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
        file.write("executable = "+self.name+".sh \n")
        file.write("copy_to_spool = false \n")
        file.write("should_transfer_files = yes \n")
        file.write("when_to_transfer_output = on_exit \n")
        
        file.write("# Require execute servers that have Gluster:\n")
        file.write("Requirements = (Target.HasGluster == true)\n")
        file.write("request_cpus = 1\n")
        file.write("request_memory = 12GB\n")
        file.write("request_disk = 20GB\n")
        
        file.write("output = "+self.name+".out\n")
        file.write("error = "+self.name+".err\n")
        file.write("transfer_input_files = "+self.name+".sh\n")
          
        file.write("+AccountingGroup = EngrPhysics_Wilson \n")
        file.write("Queue \n")
        file.close()

class JobManager:
    def __init__(self):
        self.job_list = []
        self.jobs = []
        self.file_list = []
        self.generation = 0
        self.job_manager = 0
        
        # data related to the writing of files
        self.filepath = ""
        self.code_type = ""
        self.code_options = []
        self.username = ""

    def set_filepath(self,filepath):
        self.filepath = filepath

    def set_code_type(self,code_type):
        self.code_type = code_type

    def set_code_options(self,code_options):
        self.code_options = code_options

    def set_username(self,username):
        self.username = username

    def set_generation(self,gen):
        self.generation = gen

    def set_files(self,file_list):
        self.file_list = file_list

    def set_jobs(self,job_list):
        self.job_list = job_list

    def _make_pairs(self):
        count = 0
        while(len(self.file_list) > 1):
            job = Job()
            count += 1
            # set the job name
            job.set_name("output_"+str(self.generation)+"_"+str(count))
            # set the input files
            file1 = self.file_list.pop(1)
            file2 = self.file_list.pop(0)
            # set the parent job names
            job.set_parents(file1,file2)           
            # set the input files
            job.set_files(file1+".tar.gz",file2+".tar.gz")
            # set the output file name
            job.set_output_name("output_"+str(self.generation)+"_"+str(count))

            # set job specific details
            job.set_filepath(self.filepath)
            job.set_code_type(self.code_type)
            job.set_code_options(self.code_options)
            job.set_username(self.username)

            # append to list
            self.job_list.append(job)

        # add the new files to the list
        new_files = []
        for i in range(len(self.job_list)):
            new_files.append(self.job_list[i].output_name)

        # we have a straggler file, add it to the list 
        if(len(self.file_list) == 1):
            new_files.append(self.file_list[0])

        # if there are no new files, then we are done
        if(len(new_files) == 1 ):
            return

        # make a new manager with the new files
        self.job_manager = JobManager()
        self.job_manager.set_filepath(self.filepath)
        self.job_manager.set_code_type(self.code_type)
        self.job_manager.set_code_options(self.code_options)
        self.job_manager.set_username(self.username)

        gen = self.generation + 1
        self.job_manager.set_generation(gen)
        self.job_manager.set_files(new_files)
        self.job_manager.collapse()

    # make the pairs for the current file
    def collapse(self):
        if len(self.file_list) == 0:
            print "No jobs to collapse"
            return

        self._make_pairs()

    # print the job list for the current manager
    def print_jobs(self):
        print "job list"
        for i in range(len(self.job_list)):
            print self.job_list[i].name
            print self.job_list[i].file1, self.job_list[i].file2
            print self.job_list[i].output_name       

    # print the dag joblist  portion for the current job manager
    def _print_dag_joblist(self,filestream):
        for i in range(len(self.job_list)):
            self.job_list[i].print_dag_line(filestream)

    # print the dag parent-child portion for the current job manager
    def _print_dag_parent_child(self,filestream):
        for i in range(len(self.job_list)):
            self.job_list[i].print_parent_child_line(filestream)
    
    # prints the complete dag 
    def print_daggraph(self):
        # first print all the job memebers
        f = open("dagman.dag","w")
        jobm = self
        while ( jobm.job_manager != 0 ):
            jobm._print_dag_joblist(f)
            jobm = jobm.job_manager
        jobm._print_dag_joblist(f)

        # now print parent_child links
        jobm = self.job_manager # skip the first one
        while ( jobm.job_manager != 0 ):
            jobm._print_dag_parent_child(f)
            jobm = jobm.job_manager
        jobm._print_dag_parent_child(f)
        f.close()

    # prints the complete job list
    def print_joblist(self):
        jobm = self
        while ( jobm.job_manager != 0 ):
            jobm.print_jobs()
            jobm = jobm.job_manager
        jobm.print_jobs()


    # print the job files for the current job manager
    def print_jobfiles(self):
        for i in range(len(self.job_list)):
            self.job_list[i].write_job_script()
            self.job_list[i].write_command_file()

    # prints all job files
    def print_job_files(self):
        jobm = self
        while ( jobm.job_manager != 0 ):
            jobm.print_jobfiles()
            jobm = jobm.job_manager
        jobm.print_jobfiles()

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

    # strip the .tar.gz from each item in the list
    for item in range(len(no_res)):
        file_name = no_res[item]
        file_name = file_name[:-7]
        no_res[item] = file_name
    return no_res

def numericalSort(value):
    numbers = re.compile(r'(\d+)')
    parts = numbers.split(value)
    parts[1::2] = map(int, parts[1::2])
    return parts

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

job_options = []

#loop over the args      
for arg in range(0,len(sys.argv)):
    if '--job' in sys.argv[arg]:
    # look for job type
       job_type = sys.argv[arg+1]
    if '--path' in sys.argv[arg]:
    # look for the path to data
       path_data = sys.argv[arg+1]
    if '--batch' in sys.argv[arg]:
       int_t = int(sys.argv[arg+1])
       num_batches = int_t
    if '--filesystem' in sys.argv[arg]:
        if 'squid' in sys.argv[arg+1].lower():
            filesystem = "squid"
        else:
            filesystem = "gluster"
    if '--tally' in sys.argv[arg]:
        if 'mctal' in sys.argv[arg+1]:
            job_options.append('mctal')
        if 'meshtal' in sys.argv[arg+1]:
            job_options.append('meshtal')


# used for filenaming conventions
user_name = getpass.getuser()

# get the inputs to combine
files = get_results("results.tar.gz",path_data)

# list of tallies to combine
command_list=[]
command_list.append([])

jobmanager = JobManager()
jobmanager.set_files(files)
jobmanager.set_username(user_name)
jobmanager.set_filepath(path_data)
jobmanager.set_code_type(job_type)
jobmanager.set_code_options(job_options)

# make the tree
jobmanager.collapse()
# print the dag graph
jobmanager.print_daggraph()
# print the job file
jobmanager.print_job_files()
