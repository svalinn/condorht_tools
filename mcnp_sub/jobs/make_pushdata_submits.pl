#!/usr/bin/env perl

use File::Copy;
use File::Path;
use Getopt::Long;

# we know we are currently dividing into 8 pieces
$pieces = 8;

GetOptions (
		'help' => \$help,
		'jobscripts=s' => \$jobscripts,
		'project=s' => \$project,
		'resultsdir=s' => \$resultsdir,
		'runloc=s' => \$runloc,
	);

if ( $help )    { help() and exit(0); }

#print "make_job_submits: $jobscripts $unique $runloc $prenode $postnode\n";

open(SUBM,">$runloc/pushdata.cmd") or die "Can not write submit file<$runloc/doextract.cmd>:$!\n"; 
#print "Just created <$runloc/pushdata.cmd>\n";

print SUBM "universe = scheduler\n";
print SUBM "executable = $jobscripts/pushdata.pl\n";
print SUBM "arguments = $resultsdir $project\n";

print SUBM "getenv = true\n";

print SUBM "output= pushdata.out\n";
print SUBM "error = pushdata.err\n";
print SUBM "log = pushdata.log\n";

print SUBM "notification = never\n";

print SUBM "queue\n";
close(SUBM);

exit(0);


# =================================
# print help
# =================================

sub help 
{
    print "Usage: make_pushdata_submits.pl 
Options:
        [-h/--help]                      See this
		[-j/--jobscripts]                where are templates
		[-p/--project]                   what is input arg?
		[-r/--resultsdir]                running where?
		\n";
}

