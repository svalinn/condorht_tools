#!/usr/bin/perl

# Break up the mcnp5 run into N jobs
#
# control read from file mcnp5_args
#
# sample
#
# number = 2
# directory = part
# events = 3t
# input = sph_test.ini
# output = bttest
# restart = restart.bin
# mctal = test_mctal
# meshtal = test_meshtal
#

use strict;

use Cwd;
use File::Copy;

my @ERRORMSG; # Container for accumulating execution error messages.
my @WARNMESG; # Container for accumulating execution warning messages.
my $jobid = $ARGV[0];

my $dbinstalllog =  "premcnp5.$jobid.out";
print "Trying to open logfile... $dbinstalllog\n";
open(OLDOUT, ">&STDOUT");
open(OLDERR, ">&STDERR");
open(STDOUT, ">>$dbinstalllog") or die "Could not open $dbinstalllog: $!";
open(STDERR, ">&STDOUT");
select(STDERR);
 $| = 1;
select(STDOUT);
 $| = 1;

print "This JOBID<$jobid>\n";

my $configfile = "mcnp_args";
my %runconfig = ();

ParseArgFile($configfile);
ShowArgs();

$ENV{DATAPATH} = "/home/bt/mcnp5/data";
system("printenv");

my $jobs;
my $dirhandle;
my $stopn;
my $stopc;
my $events;
my @npsperjob;
my @starthist;
my $inpfile;
my $outfile;
my $rstfile;
my $events;
my $binfile = 'restart.bin';
my $mctal = "";
my $meshtal = "";

$ENV{PATH} = "/home/bt/mcnp5/bin:$ENV{PATH}";

print "\nExecuting the '$0' script.\n";
foreach my $env (sort keys %ENV) {
	print "$env = $ENV{$env}\n";
}

# Parse the command line arguments and check for errors.
#if ( ! exists $ARGV[0] ) {
    #die "Usage: $0 i=<inputfile> o=<outputfile> n=<#ofjobs> d=<directoryname> t=<runtime>{n/t}\n\n";
#}

if(exists $runconfig{input}) {
	print "Setting input = $runconfig{input}\n";
	$inpfile = $runconfig{input};
} else {
        push @ERRORMSG, "input file name missing.";
}

if(exists $runconfig{output}) {
	print "Setting output = $runconfig{output}\n";
	$outfile = $runconfig{output};
} else {
        push @ERRORMSG, "output file name missing.";
}

if(exists $runconfig{number}) {
	print "Setting number = $runconfig{number}\n";
	$jobs = $runconfig{number};
} else {
}

if(exists $runconfig{directory}) {
	print "Setting directory = $runconfig{directory}\n";
	$dirhandle = $runconfig{directory};
} else {
}

if(exists $runconfig{restart}) {
	print "Setting restart = $runconfig{restart}\n";
	$binfile = $runconfig{restart};
} else {
}

if(exists $runconfig{mctal}) {
	print "Setting mctal = $runconfig{mctal}\n";
	$mctal = $runconfig{mctal};
} else {
}

if(exists $runconfig{meshtal}) {
	print "Setting meshtal = $runconfig{meshtal}\n";
	$meshtal = $runconfig{meshtal};
} else {
}


if(exists $runconfig{events}) {
	print "Setting events = $runconfig{events}\n";
	$events = $runconfig{events};
	if($events =~ /^(\d+)(t)$/) {
		push @WARNMESG, "using CPU time as a limiting criterion runs a slight risk of history overlap.";
		$stopn = $1;
		$stopc = $2;
	} elsif($events =~ /^(\d+)(n)$/) {
		push @WARNMESG, "Using particle count<$events>";
		$stopn = $1;
		$stopc = $2;
        my $scraps = $stopn - $jobs*int($stopn/$jobs);
        if ( $scraps > 0 ) {
            push @WARNMESG, "Number particle histories requested is not evenly divisible over the";
            if ( $scraps == 1 ) {
                push @WARNMESG, "number of jobs requested. The first job will run for one extra history.";
            } else {
                push @WARNMESG, "number of jobs requested. The first $scraps jobs will run for one extra history.";
            }
        }
		for (my $i=1;$i<=$jobs;$i++) {
			$npsperjob[$i] = int($stopn/$jobs);
			if ( $scraps > 0 ) {
				$npsperjob[$i]++;
				$scraps--;
			}
			if ($i == 1) {
				$starthist[$i] = 1;
			} else {
				$starthist[$i] = $starthist[$i-1] + $npsperjob[$i-1];
			}
		}

	} else {
		push @WARNMESG, "undefined events counter<$events>";
	}
} else {
}

# Check for the existance of optional arguments, if null set the default value
if ( ! $dirhandle ) {
    $dirhandle = 'part';
    push @WARNMESG, "using default value \"$dirhandle\" for the directory prefix.";
}
if ( ! $jobs ) {
    $jobs = 5;
    push @WARNMESG, "using default value of $jobs for the number of jobs to spawn.";
}
if ( ! $stopn ) {
    $stopn = 5;
    push @WARNMESG, "using default stopping value of $stopn";
}
if ( ! $stopc ) {
    $stopc = 'n';
    push @WARNMESG, "using default stopping condition of total particle histories (nps)";
}



# Check for the existance of the input file
if ( ! -s $inpfile ) { push @ERRORMSG, "input file \"$inpfile\" not found in this directory or has zero size."; }

# Check to make sure that file names are unique
if ( $inpfile eq $outfile ) { push @ERRORMSG, "input and output files must be uniquely named!"; }

# Check for nps >= no. of directories
if ( $stopc =~ "n") {
    if ( $stopn < $jobs ) {
        push @ERRORMSG, "requested number of particles is less than the number of directories to be created.";
    }
}



# Check for the existance of job directories.
my @dirnames;
$dirnames[$jobid] = sprintf("%s%03d",$dirhandle,$jobid);
if (-d $dirnames[$jobid]) {
	push @ERRORMSG,"directory '$dirnames[$jobid]' already exists!";
}


if (exists $WARNMESG[0]) {
    print "The script will execute with the warning(s) issued below.\n";
    foreach my $MSG (@WARNMESG) {
        print "\tWRN: $MSG\n";
    }
}

if (exists $ERRORMSG[0]) {
    print "Script did not execute due to the following error(s):\n";
    foreach my $MSG (@ERRORMSG) {
        print "\tERR: $MSG\n";
    }
    die "\n";
}

printf("The command-line arguments evaluated to:
\tNumber of directories to create = %d
\tPrefix of the created directories = %s
\tNumerical stopping point = %d
\tStop Condition: time in CPU-minutes per directory (t) or
\t                total number of particle histories (n) = %s
\tInput file name = %s
\tOutput file name = %s\n", $jobs, $dirhandle, $stopn, $stopc, $inpfile, $outfile);

print "Pre-flight complete, executing script.\n";

my $basedir = cwd;

# Create the directory
my $localin = $inpfile . ".$jobid";
my $rstfile = $localin . ".cont";
my $localout = $outfile . ".$jobid";
my $localrestart = $binfile . ".$jobid";

# Change to i^th directory
my $currdir = $basedir . "/" . $dirnames[$jobid];
print "\tInitializing mcnp5 data for job $jobid\n";

# Copy the master input file to this directory
copy("$inpfile","$localin") or die "Copy of $localin failed: $!\n";

open (INPFILE, '>>'.$localin);

# Add the stopping condition to the input file
if ($stopc =~ "t") {
    print INPFILE "ctme $stopn\n";
} else {
    print INPFILE "nps $npsperjob[$jobid]\n";
}

# Modify the random number generator in the input file. Divide the total histories requested
# on the command line and divide by the number of jobs requested.
if ($stopc =~ "t") {
    my $startseed = 1 + 2 * int(rand(2147483647));
    print INPFILE "rand seed=$startseed\n";
} else {
    print INPFILE "rand hist=$starthist[$jobid]\n";
}

close (INPFILE);

# Do a 0-particle run to populate the restart binary
#my $ret=system "crunch ix i=$localin o=$localout runtpe=$localrestart >/dev/null";
system("which crunch");
my $ret=system "crunch ix i=$localin o=$localout runtpe=$localrestart";
if ($ret == 0) {
    print "It worked!\n";
	}
	else
	{
	print "crunch failed!($ret)\n";
	}

# Create a restart file based on the command-line option
open (CONTFILE, '>'.$rstfile);
print CONTFILE "continue\n";
if ($stopc =~ "t") {
    print CONTFILE "ctme $stopn\n";
} else {
    print CONTFILE "nps $npsperjob[$jobid]\n";
}
close (CONTFILE);


print "The script '$0' exited normally.\n\n";

exit 0;

sub ShowArgs
{
	foreach my $arg (sort keys %runconfig) {
		print "$arg = $runconfig{$arg}\n";
	}
}

sub ParseArgFile
{
	my $argfile = shift;
	print "Parsing $argfile\n";

	my $line = "";
	open(AF, "<$argfile") or die "Can not open config file<$argfile>:$!\n";
	while(<AF>){
		chomp();
		$line = $_;
		if($line =~ /^\s*(.*?)\s*=\s*(.*?)\s*$/) {
			#print "Line: $1 = $2\n";
			if(! exists $runconfig{$1}) {
				$runconfig{$1} = $2;
			} else {
				print "Ignoring repeat definition of <$1> <= $2>\n";
			}
		} else {
			print "Line format did not parse <$line>\n";
		}
	}
	close(AF);
}
