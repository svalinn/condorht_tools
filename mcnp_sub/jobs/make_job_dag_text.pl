#!/usr/bin/env perl

use File::Copy;
use File::Path;
use Getopt::Long;

# we know we are currently dividing into 8 pieces
my $dbinstalllog =  "makedags.out";
print "Trying to open logfile... $dbinstalllog\n";
open(OLDOUT, ">&STDOUT");
open(OLDERR, ">&STDERR");
open(STDOUT, ">>$dbinstalllog") or die "Could not open $dbinstalllog: $!";
open(STDERR, ">&STDOUT");
select(STDERR);
 $| = 1;
select(STDOUT);
 $| = 1;

my $initthrottle = 10;

GetOptions (
		'help' => \$help,
		'jobscripts=s' => \$jobscripts,
		'unique=s' => \$unique,
		'runloc=s' => \$runloc,
		'prenode=s' => \$prenode, 		
		'postnode=s' => \$postnode,
		'imagedir=s' => \$imagedir,
	);

print "Imagedir for project is $imagedir\n";

if ( $help )    { help() and exit(0); }

##########################################################################
#
# This projects processing node is actually a dag in and of itself.
#
# We first divide the brain scan into N pieces(initially 8)
#
# and then we process all N pieces in parallel
#
# When they are all done, we collect the results.....
#
# There are two tie in nodes passed in which provides connecting
# points to the processing defined here.
#
##########################################################################


my $widthfile = "$imagedir/$unique/mcnp_args";

print "make_job_dag_text.pl: $jobscripts $unique $runloc $prenode $postnode $imagedir\n";
if(!(-f "$widthfile")) {
	die "Failed to find parallelism directive file<$imagedir/$unique/mcnp5_args>\n";
}

my $output = "";
my $restart = "";
my $input = "";
my $mctal = "";
my $meshtal = "";
my $line = "";
my $pieces = 0;
open(NS,"<$widthfile") or die "Can read width count from<$widthfile>:$!\n";
while(<NS>) {
	chomp();
	$line = $_;
	if($line =~ /^number\s*=\s*(\d+)\s*$/) {
		$pieces = $1;
		print "There will be a parallelism of<$pieces>\n";
	} elsif($line =~ /^input\s*=\s*(.*)\s*$/) {
		$input=$1;
	} elsif($line =~ /^restart\s*=\s*(.*)\s*$/) {
		$restart=$1;
	} elsif($line =~ /^output\s*=\s*(.*)\s*$/) {
		$output=$1;
	} elsif($line =~ /^mctal\s*=\s*(.*)\s*$/) {
		$mctal=$1;
	} elsif($line =~ /^meshtal\s*=\s*(.*)\s*$/) {
		$meshtal=$1;
	}
}
close NS;

@children = ();
@pre_children = ();
$unique_dag = $unique . "_dag";


print "make_job_dag_test: $jobscripts $unique $runloc $prenode $postnode\n";

##################################################################
#
# We want to be free to profile one or more logs which appropriate
# names for both the submit and the log files
#
##################################################################

$profile = "domcnp5";
open(PROF,">$runloc/../PROFILE") or die "Can not write PROFILE file<$runloc/../PROFILE>:$!\n"; 
print PROF "$profile\n";
close(PROF);

open(SUBM,">$runloc/$unique_dag") or die "Can not write submit file<$runloc/$unique_dag>:$!\n"; 
print "Just created <$runloc/$unique_dag>\n";

# 
# this node will do sanity checks and get the data moved
# only. The state 0 inits will happen in parallel soon
$procparent =  $job = "premcnp5.init";
print SUBM "JOB $job preinitcond.cmd DIR $unique\n";
#print SUBM "PRIORITY $job 5\n";
print SUBM "SCRIPT PRE $job $jobscripts/prejob.pl $unique\n";
print SUBM "RETRY $job 1\n";
$count= 1;
$submit = "";
# drop out the parallel portion
while($count < ($pieces + 1)) {
	$job = "mcnp5.$unique_$count";
	$prejob = "premncp5.$unique_$count";
	$submit = "mcnp5" . ".$count" . ".cmd";	
	$presubmit = "premcnp5" . ".$count" . ".cmd";	
	print SUBM "JOB $job $submit DIR $unique\n";
	print SUBM "SCRIPT PRE $job $jobscripts/premcnp5.pl $count\n";
	#print SUBM "JOB $prejob $presubmit DIR $unique\n";
	#print SUBM "PRIORITY $prejob 5\n";
	#print SUBM "PRIORITY $job 2\n";
	print SUBM "RETRY $job 3\n";
	#print SUBM "RETRY $prejob 3\n";
	push @children, $job;
	#push @pre_children, $prejob;
	#print SUBM "PARENT $prejob CHILD $job\n";
	$count += 1;
}
#print SUBM "PARENT $procparent CHILD"; 
#foreach $name (@pre_children) {
	#print SUBM " $name";
#}
#print SUBM "\n";

my $merge = "";
if(defined $meshtal) {
	$merge = "mncp5.meshmerge";

 	print SUBM "JOB $merge finalmerge.cmd dir $unique\n";
	print SUBM "SCRIPT POST $merge $jobscripts/postjob.pl $unique\n";
	print SUBM "RETRY $merge 1\n";

	print SUBM "PARENT";
	foreach $name (@children) {
		print SUBM " $name";
	}
	print SUBM " CHILD $merge\n"; 
}

close(SUBM);

exit(0);


# =================================
# print help
# =================================

sub help 
{
    print "Usage: make_job_dag_text.pl 
Options:
        [-h/--help]                      See this
		[-j/--jobscripts]                where are templates
		[-u/--unique]                    what is input arg?
		[-r/--runloc]                    running where?
		[--prenode]                      what node precedes
		[--postnode]                     what node follows
		\n";
}
