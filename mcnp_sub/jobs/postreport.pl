#! /usr/bin/env perl
use Getopt::Long;
use Cwd;
use Soar;

$savefile = "ENVVARS";

# Dagman passes node which maps to both where the job is running
$job = $ARGV[0];
$cwd = getcwd();

print "post report running here<$cwd>\n";

Soar::DebugOn();
Soar::ReadSetEnv($savefile);

$topdir = $ENV{TOPDIR};
$runloc = $ENV{RUNLOC};
$resultsloc = $ENV{RESLOC};
$unique = $ENV{UNIQUE};

$report = $unique . ".report";
$profile = $unique . ".png";
$params = "param.dat";

system("cp $report $profile $params $resultsloc");

exit(0);
