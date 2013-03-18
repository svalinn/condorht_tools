#!/usr/bin/env perl

use File::Copy;
use File::Path;
use Getopt::Long;

#my $dbinstalllog =  "makesubmits.out";
#print "Trying to open logfile... $dbinstalllog\n";
#open(OLDOUT, ">&STDOUT");
#open(OLDERR, ">&STDERR");
#open(STDOUT, ">>$dbinstalllog") or die "Could not open $dbinstalllog: $!";
#open(STDERR, ">&STDOUT");
#select(STDERR);
 #$| = 1;
#select(STDOUT);
 #$| = 1;

GetOptions (
		'help' => \$help,
		'jobscripts=s' => \$jobscripts,
		'unique=s' => \$unique,
		'runloc=s' => \$runloc,
		'prenode=s' => \$prenode, 		
		'postnode=s' => \$postnode,
		'imagedir=s' => \$imagedir,
	);

if ( $help )    { help() and exit(0); }

# Where is mcnp5
open(DP,"$jobscripts/DATAPATH") or die "Can't open jobs/DATAPATH\n";

my $widthfile = "$imagedir/$unique/mcnp_args";
my $datapath = <DP>;
print "DATAPATH = <$datapath>\n";
my $Partial = "";
if($datapath =~ /^datapath\s*=\s*(.*)$/) {
	$Partial = $l;
	print "Partial <$Partial>\n";
} else {
	print "Can't parse Mcnp5 locationo from <$datapath>\n"; 
}
print "$datapath\n";

print "make_job_submits: $jobscripts $unique $runloc $prenode $postnode $imagedir\n";
if(!(-f "$widthfile")) {
	die "Failed to find parallelism directive file<$imagedir/$unique/num_subprocess.txt>\n";
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
	if($line =~ /^number\s*=\s*(\d+)$/) {
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

#This node secures input and does sanity screening
open(TEMP,"<$jobscripts/preinitcond.template") or die "Can not read template<$jobscripts/preinitcond.template>:$!\n";
open(SUBM,">$runloc/preinitcond.cmd") or die "Can not write submit file<$runloc/preinitcond.cmd>:$!\n"; 
print "Just created <$runloc/preinitcond.cmd>\n";
$line = "";
while(<TEMP>) {
	chomp;
	$line = $_;	
	print "$_\n";
	if($line =~ /^executable\s+=\s+XXX.*$/) {
		print SUBM "executable = $jobscripts/preinitcond.pl\n";
	} else {
		print SUBM "$line\n";
	}
}
close(TEMP);
close(SUBM);

# Both of the next sets of submits handle one job. The first
# respeats the basic arg testing and creates random seed and
# time zero data. This one runs schedular universe on the
# submit machine.

# The second is the actual remote job
# print "About to make job submit files for initialization of<$unique>\n";
# $count = 1;
# print "Starting: count = $count/pieces = $pieces\n";
# while($count < ($pieces + 1)) {
# 	print "count = $count/pieces = $pieces\n";
# 	my $goal = "$unique$count.mat";
# 	print "<<<$goal>>>\n";
# 	open(PRETEMP,"<$jobscripts/premcnp5.template") 
# 			or die "Can not read template<$jobscripts/premcnp5.template>:$!\n";
# 	open(MCNP5CMD,">$runloc/premcnp5.$count.cmd") 
# 			or die "Can not write submit file<$runloc/premcnp5.$count.cmd>:$!\n"; 
# 	print "Just created <$runloc/premcnp5.$count.cmd>\n";
# 	$line = "";
# 	while(<PRETEMP>) {
# 		chomp;
# 		$line = $_;	
# 		print "$_";
# 		if($line =~ /^\s*executable\s*=\s*XXX.*$/) {
# 			print "Saw executable line for premcnp5.pl\n";
# 			print MCNP5CMD "executable = $jobscripts/premcnp5.pl\n";
# 		}elsif($line =~ /^arguments\s+=\s+.*/) {
# 			print MCNP5CMD "arguments = $count\n";
# 		}elsif($line =~ /^output\s+=\s+.*/) {
# 			print MCNP5CMD "output = dopremcnp5.$count.out\n";
# 		}elsif($line =~ /^error\s+=\s+.*/) {
# 			print MCNP5CMD "error = dopremcnp5.$count.err\n";
# 		}elsif($line =~ /^log\s+=\s+.*/) {
# 			print MCNP5CMD "log = dopremcnp5.$count.log\n";
# 		} else {
# 			print MCNP5CMD "$line\n";
# 		}
# 	}
# 	close(PRETEMP);
# 	close(MCNP5CMD);

# 	$count += 1;
# }

print "About to make remote job submit files for <$unique>\n";
$count = 1;
print "Starting: count = $count/pieces = $pieces\n";
while($count < ($pieces + 1)) {
	print "count = $count/pieces = $pieces\n";
	my $goal = "$unique$count.mat";
	print "<<<$goal>>>\n";
	open(TEMP,"<$jobscripts/mcnp5.template") 
			or die "Can not read template<$jobscripts/mcnp5.template>:$!\n";
	open(SUBM,">$runloc/mcnp5.$count.cmd") 
			or die "Can not write submit file<$runloc/mcnp5.$count.cmd>:$!\n"; 
	print "Just created <$runloc/mcnp5.$count.cmd>\n";
	$line = "";
	while(<TEMP>) {
		chomp;
		$line = $_;	
		print "$_";
		if($line =~ /^executable\s+=\s+(.*)$/) {
			print SUBM "executable = $Partial$1\n";
		}elsif($line =~ /^arguments\s+=\s+.*/) {
			if(($mctal ne "") && ($meshtal ne "")) {
				print SUBM "arguments = c i=$input.$count.cont o=$output.$count ru=$restart.$count mctal=$mctal.$count mesh=$meshtal.$count\n";
			} else {
				print SUBM "arguments = c i=$input.$count.cont o=$output.$count ru=$restart.$count \n";
			}
		}elsif($line =~ /^output\s+=\s+.*/) {
			print SUBM "output = domcnp5.$count.out\n";
		}elsif($line =~ /^error\s+=\s+.*/) {
			print SUBM "error = domcnp5.$count.err\n";
		}elsif($line =~ /^log\s+=\s+.*/) {
			print SUBM "log = domcnp5.$count.log\n";
		}elsif($line =~ /^transfer_input_files\s+=.*/) {
			print SUBM "transfer_input_files = $input.$count.cont,$restart.$count\n";
		} else {
			print SUBM "$line\n";
		}
	}
	close(TEMP);
	close(SUBM);

	$count += 1;
}

if(defined $meshtal) {
	open(TEMP,"<$jobscripts/finalmerge.template") or die "Can not read template<$jobscripts/finalmerge.template>:$!\n";
	open(SUBM,">$runloc/finalmerge.cmd") or die "Can not write submit file<$runloc/finalmerge.cmd>:$!\n"; 
	print "Just created <$runloc/finalmerge.cmd>\n";
	$line = "";
	while(<TEMP>) {
		chomp;
		$line = $_;	
		print "$_";
		if($line =~ /^arguments\s+=\s+.*/) {
			print SUBM "arguments = $pieces $mctal $meshtal\n";
		} else {
			print SUBM "$line\n";
		}
	}
	close(TEMP);
	close(SUBM);
}

exit(0);


# =================================
# print help
# =================================

sub help 
{
    print "Usage: make_job_submits.pl 
Options:
        [-h/--help]                      See this
		[-j/--jobscripts]                where are templates
		[-u/--unique]                    what is input arg?
		[-r/--runloc]                    running where?
		[--prenode]                      what node precedes
		[--postnode]                     what node follows
		\n";
}
