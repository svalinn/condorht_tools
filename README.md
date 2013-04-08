Collection of tools that allow the arbitrary splitting of MCNP input runs into many serial runs for submission onto the CHTC computing system. These runs are queued and submitted using Directed Acylic Graph (DAG) such that sub input decks are subservient to some master input file and allow resubmissions of failed runs.

Instructions
We have added a report writer which will give you an instantaneous report
on the DAG as it runs.

mydag-status --help to see how.


Required files for it to run:

make-graphs  
mkdag 
PROFILE 
RESULTVALUES

Running Instructions
always use restart
    [Ff][Mm][E][Ee][Ss][Hh]    pattern determines if mesh requested
	different card for mctal request.

 --jobscripts=jobs --data=ross_1bt3 --rundir=btmcnp5

Hi Bill,

The card for producing an MCTAL file is the "prdmp" card (again, case-insensitive).

The arguments are tricky due to MCNP's long-standing syntax "features".  Basically, for any card like this, a user can skip entries and leave th
e default (without having to explicitly declare the default value) by putting a "J" in that spot.  Furthermore, the user can combine many succes
sive "J" entries by putting a digit before the J.  Therefore, to skip 4 entries, leaving all 4 with their default values, one would write "4J".

The PRDMP card takes 5 arguments, the 3rd of which is a flag for producing the MCTAL file.  If this third entry is non-zero, an MCTAL file will 
be produced.

So we'd need to be able to detect all the variations of a PRDMP card and in some cases need to insert the MCTAL entry into an otherwise compact 
set of J entries.

e.g.

    PRDMP 4J -1

	becomes

	    PRDMP J J 1 J -1

		The rest is left as an exercise for the reader...

		Paul 

