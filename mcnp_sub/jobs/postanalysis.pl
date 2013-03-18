#! /usr/bin/env perl
use Getopt::Long;
use Cwd;
use Soar;


my $imagedir = "";
$savefile = "../ENVVARS";

# What kind of status are we interested in?
$kind = $ARGV[0];

print "Starting status check on $kind\n";

Soar::DebugOff();
Soar::ReadSetEnv($savefile);

$topdir = $ENV{TOPDIR};
$runloc = $ENV{RUNLOC};
$resultsloc = $ENV{RESLOC};
$mydagruns;

print "Run loc is $runloc\n";
print "Postanalysis  Done\n";
system("touch POSTANALYSIS");

exit(0);

# =================================
# print help
# =================================

sub help
{
    print "Usage: 
        Options:
            [-h/--help]                             See this
            \n";
}
