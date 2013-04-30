#!/usr/bin/python
# submit script to launch mcnp5 job(s) in a number of ways in order to facilitate parallel computation on CondorHT

# based on the original mkdagmcnp5 written by Bill Taylor and
# converted to python by Andrew Davis and Zach Welch, Department of Engineering Physics, Uw Madison

import sys # for command line args
from subprocess import call

from condor_mcnp_funcs import *
    
# main program loop
print "--------------------------------------"
print "Script to launch tasks on Condor"
print "--------------------------------------"
print "launch mcnp tasks on condor"

(datadir,rundir,mcdir,debug,email_address)=command_args(sys.argv)

print "checking for existence of prequisites"
check_dirs(datadir,rundir,mcdir)

if(debug):
    print datadir, rundir, mcdir, email_address

print "creating DiGraph Nodes"
dagfile=make_dag_nodes(datadir,rundir,mcdir,email_address,debug)

num_cpu = make_dag_scripts(datadir,rundir,mcdir,email_address,debug)

print "submitting task"
os.chdir( rundir )

# submit the jobs
# this would actually submit the jobs
# call(["condor_submit_dag","--MaxPre","4",dagfile])
