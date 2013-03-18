#! /usr/bin/env perl
use Getopt::Long;
use Cwd;
use Soar;

##########################################################################
#
# predivide will get the image to the run location
#
##########################################################################

my $dbinstalllog =  "prejob.out";
print "Trying to open logfile... $dbinstalllog\n";
open(OLDOUT, ">&STDOUT");
open(OLDERR, ">&STDERR");
open(STDOUT, ">>$dbinstalllog") or die "Could not open $dbinstalllog: $!";
open(STDERR, ">&STDOUT");
select(STDERR);
 $| = 1;
select(STDOUT);
 $| = 1;

my $imagedir = "";
$savefile = "../ENVVARS";
system("cat $savefile");

# Dagman passes node which maps to both where the job is running
$unique = $ARGV[0];
$cwd = getcwd();

print "Starting prejob here<$cwd>\n";

Soar::DebugOn();
Soar::ReadSetEnv($savefile);

$topdir = $ENV{TOPDIR};
$runloc = $ENV{RUNLOC};
$resultsloc = $ENV{RESLOC};
$tarcache = $ENV{TARCACHE};
$imagedir = $ENV{DATASETS};
$counter = 0;

print "imagedir = $imagedir\n";
print "tarcache = $tarpath\n";
print "moviedir = $moviedir\n";

my $inputfile = "";
my $shared_code = "";
my $jobdir = "";

my $widthfile = "$imagedir/$unique/mcnp_args";

my $input = "";
my $line = "";
open(NS,"<$widthfile") or die "Can read width count from<$widthfile>:$!\n";
while(<NS>) {
	chomp();
	$line = $_;
	if($line =~ /^input\s*=\s*(.*)\s*$/) {
		$input=$1;
	} 
}
close NS;

# now lets get the input file
my $cpcmd = "cp $imagedir/$unique/$input $widthfile $runloc/$unique";
my $cpargs = "cp $widthfile $runloc";
print "cmd to place input file is<$cpcmd>\n";
system("$cpcmd");
system("$cpargs");

debug("Run loaction currently holds:\n");
my $cmd = "ls -l $runloc";
system($cmd);

exit(0);

