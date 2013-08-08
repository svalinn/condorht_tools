#!/usr/bin/python

import sys

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
    job_list.append("FLUKA")

    for item in job_list:
        if string in item:
            return True
        else:
            pass
    # nothing matches job list
    return False



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

# check to see if help has been asked for first
for arg in range(0,len(sys.argv)):
    if '-h ' or '--help' or '--h ' in sys.argv[arg]:
        print_help

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





