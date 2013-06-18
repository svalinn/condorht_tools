#!/usr/bin/python

import os
from subprocess import call

# a pre initialisation script the produces runtpe files appropriate for use in
# calculations in condor

def create_mcnp_input(input_dir,mcnp_input,rundir,run_num):
    """
    function to create mcnp input deck to generate a runtpe appropriate for the problem for example,
    with advanced tallies we need to pass a new output filename for the mesh tally mesh file. So very simply
    if there is no dagmc mentioned in the mcnp input deck then we can simply copy the runtpe file by running the
    normal input deck without modification.
    """

    dagmc_t=False
    out_t=False

    # open the mcnp input file and look for the phrase "dagmc" if absent normal run
    file = open(input_dir+"/"+mcnp_input)

    while 1:
        line = file.readline()
        # we treat #'s as comments
        if not line:
            break
        if 'dagmc' in line:
            dagmc_t=True
        if dagmc_t:
            if 'out' in line:
                out_t=True
                break
                
        # at this juncture we may wish to also check the file pointed to by the dagmc keyword. some users
        # like to use damgc file= to send the data to. However, currently we will fail unless we find the out
        # keyword

    # now we can either have dagmc_t = True/False, if dagmc_t then out can be either t or f
    if not dagmc_t:
        # normal mcnp run
        shutil.copyfile(input_dir+'/'+mcnp_input,rundir+'/'+mcnp_input)
    elif dagmc_t and not out_t:
        print "dagmc present but output not specified, fail!"
        exit()
    elif dagmc_t and out_t:
        # mcnp run with tetmesh
        file = open(input_dir+"/"+mcnp_input)
        ofile = open(rundir+'/'+mcnp_input+str(run_num),'w')
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
        
    return

def run_mcnp_input(rundir,mcnp_input,run_number,mcnp_input_dir):
    """
    Function that runs the mcnp input pointed to, to produce the runtpe file with the correct
    data stored.
    """
    working_dir=os.getcwd() #copy cwd
    os.chdir(rundir) #move to run dir
    os.system(mcnp_input_dir+' ix '+' i='+mcnp_input+str(run_number)+' g=divertor_simgeom.h5m')
    os.chdir(working_dir) #go back to original cwd
    return

def generate_runtapes(num_cpus,input_dir,mcnp_input,rundir,mcnp_input_dir):
    """
    Args
    num_cpus - the number of cpu's the problem will be divided into
    input_dir - the directory containing the input deck
    mcnp_input - the name of the mcnp input deck
    rundir - the directory where the run will take place
    """

    for i in range(1,num_cpus+1):
        # loop over each input deck in the problem
        create_mcnp_input(input_dir,mcnp_input,rundir,i) # create the input deck
        run_mcnp_input(rundir,mcnp_input,i,mcnp_input_dir) # run the mcnp input problem

    return


generate_runtapes(30,'/home/davisa/condorht_tools/chtc_submit/test','divertor_sim','/home/davisa/condorht_tools/chtc_submit/run_dir','/home/davisa/dagmc/mcnp5src/bin/mcnp5')
