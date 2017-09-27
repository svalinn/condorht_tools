#!/usr/bin/python

import os
import sys
import shutil
import argparse

#from random import seed, randint
import random
from subprocess import call
from sets import Set

# a pre initialisation script the produces runtpe files appropriate for use in
# calculations in condor

# list containing each line of the the fluka input deck
geant4_input_deck = []
# set of approved unique seeds
seeds = Set()

def read_geant4_input(file_name):
    """ reads the fluka input file pointed to by file, and places each
        line into a list

    file_name: string filename 
    """
    # open the file
    f = open(file_name,'r')
    # read each line into list
    for line in f:
        geant4_input_deck.append(line)

    return

def write_geant4_macro(filestub,seed,idx):
    """ given the geant4 file in memory, the geant4_input list, for each run
        print out the input deck named _filename_index.mac, but with the 
        seed set  such that each run is completly independent

        idx: the cpu index, used to index into seed
    """
    working_dir = os.getcwd()
    
    f = open(working_dir+'/input/_'+filestub+'_'+str(idx)+'.mac','w')

    # always write the new seed
    f.write('## set the random seed\n')
    f.write('/random/setSeeds '+str(seed[0])+' '+str(seed[1])+'\n')
    for line in geant4_input_deck:
        if("/random/setSeeds" not in line):
            f.write(line)
    f.close()
    return
 

def generate_seed_random():
    """ generate a random integer between 1 and 9E8, add this to the 
        list of used seeds for this run
    """
    # generate a rn between 1 and 9e8
    seed = random.randint(1,900000000)
    # while we aren't done
    seed_not_set = True
    while(seed_not_set):
        # while the seed is not approved
        if(seed in seeds):
            # seed already used generate another
            seed = random.randint(1,900000000)
        else:
            # seed isn't used
            seeds.add(seed)
            seed_not_set = False
            break

    return seed

################################################### 
# Python script to take starting geant4 macro file#
# and chop into a number of runs ready for condor #
###################################################  
# start

parser = argparse.ArgumentParser(description='Splits a Fluka input into several sequentially numbered runs, each with a unique seed')
parser.add_argument('-i','--input', type=str, help="The Fluka input file to split", required=True)
parser.add_argument('-c','--cpu', type=int, help="The number of CPU's this calculation will run on", required=True)
parser.add_argument('-s','--seed', type=int,  help="Set a non-default random number seed, default is 54217137")

args = parser.parse_args()
input = args.input
num_cpu = args.cpu
seed = args.seed

# seed used to seed the python random number generator
if not seed:
    seed = 54217137

# set the seed for python rn
random.seed(seed)

# read the fluka input deck
read_geant4_input(input)

# mkdir to store all inputs in
working_dir = os.getcwd()
if not os.path.exists(working_dir+"/input"):
    os.makedirs(working_dir+"/input")

# the input file may have path, extract from the last / to the end of string
# thus giving the input file name
file_stub = ""
if "/" not in input:
    end = input.find('.mac')
    file_stub = input[0:end]
else:
    idx = input.rfind('/')
    end = input.find('.mac')
    file_stub = input[idx+1:end-4]

# make all the input decks
for i in range(1,int(num_cpu)+1):
    seed1 = generate_seed_random()
    seed2 = generate_seed_random()
    seed = [seed1,seed2]
    write_geant4_macro(file_stub,seed,i)
