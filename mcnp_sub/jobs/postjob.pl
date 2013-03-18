#! /usr/bin/env perl
use Getopt::Long;
use Cwd;

##########################################################################
#
# postcollect will get the final results to the results location
#
##########################################################################

$jobout = "./doextract.out";
$savefile = "../ENVVARS";

my $dbinstalllog =  "postjob.out";
print "Trying to open logfile... $dbinstalllog\n";
open(OLDOUT, ">&STDOUT");
open(OLDERR, ">&STDERR");
open(STDOUT, ">>$dbinstalllog") or die "Could not open $dbinstalllog: $!";
open(STDERR, ">&STDOUT");
select(STDERR);
 $| = 1;
select(STDOUT);
 $| = 1;

# Dagman passes node which maps to both where the job is running
$job = $ARGV[0];
$cwd = getcwd();

print "Starting postjob here<$cwd> for job <$job>\n";


my $widthfile = "./mcnp_args";

if(!(-f "$widthfile")) {
	die "Failed to find parallelism directive file<$cwd/mcnp_args>\n";
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

print "number = <$pieces> input = <$input> restart = <$restart> output = <$output> mctal = <$mctal> meshtal = <$meshtal>\n";
close NS;

# ensure we keep variations of the output files....
my @outparts = split /\./, $output;
my $outlength = length($outparts[0]);
my $outpattern = substr( $outparts[0], 0, $outlength - 1);
$output = $outpattern;

#loose the .cont files.
system("rm -f $input*.cont");


my $cmd = "ls -l .";
print "Run location holds:\n" ;

print "moving $output* $input* domcnp5*.out to $resultloc\n" ;
#system("mv $output* $resultloc");
#system("mv $input* $resultloc");
#system("mv domcnp5*.out $resultloc");
if( $meshtal ne "" ) {
	#system("mv final_mesh final_mctal $resultloc");
}


open(RES,">RESULT") || die "Can not open RESULT for writing:$!\n";
	print RES "0\n";
close(RES);
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
