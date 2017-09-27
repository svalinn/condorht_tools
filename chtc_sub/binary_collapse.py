#!/usr/bin/python

class Job:
    def __init__(self):
        self.name = ""
        self.parent1 = ""
        self.parent2 = ""
        self.file1 = ""
        self.file2 = ""

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

    # print the parent child line of a CONDOR DAG file
    def print_parent_child_line(self,filestream):
        # it may be the case that either parent may have ".tar.gz"
        # in the name, if this is the case then there is really 
        # only one parent
        filestream.write("PARENT ")
        if "tar.gz" not in self.parent1:
            filestream.write(self.parent1+" ")
        if "tar.gz" not in self.parent2:
            filestream.write(self.parent2+" ")
        filestream.write("CHILD "+self.name+"\n")

    def write_job_script(self):
        f = open(self.name+".sh","w")
        f.write(self.file1+"\n")
        f.write(self.file2+"\n")
        f.close()

    def write_command_file(self):
        f = open(self.name+".cmd","w")
        f.write(self.name+".sh\n")
        f.close()


class JobManager:
    def __init__(self):
        self.job_list = []
        self.jobs = []
        self.file_list = []
        self.generation = 0
        self.job_manager = 0

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

jobm = JobManager()
files = []

# load up list of files
for i in range(199):
    files.append("results_"+str(i+1)+".tar.gz")

# add files to job manager
jobm.set_files(files)
jobm.collapse()
#jobm.print_joblist()
jobm.print_daggraph()
