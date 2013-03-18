#! /usr/bin/env perl
use Cwd;

my $LogFile = "doselecting.out";
open(OLDOUT, ">&STDOUT");
open(OLDERR, ">&STDERR");
system("pwd");
open(STDOUT, ">$LogFile") or die "Could not open $LogFile: $!\n";
open(STDERR, ">&STDOUT");
select(STDERR); $| = 1;
select(STDOUT); $| = 1;

my $job = $ARGV[0];
my $inputbase = $ARGV[1];
my $start = $ARGV[2];
my $end = $ARGV[3];

my $startidx = 0;
my $endidx = 0;

$startidx = $start;
$endidx = $end;

$ENV{HOME} = ".";

$ENV{LD_LIBRARY_PATH} = "/data2/matlab_runtime/linux64/v710/runtime/glnxa64:/data2/matlab_runtime/linux64/sys/os/glnxa64:/data2/matlab_runtime/linux64/v710/bin/glnxa64:/data2/matlab_runtime/linux64/v710/sys/java/jre/glnxa64/jre/lib/amd64/native_threads:/data2/matlab_runtime/linux64/v710/sys/java/jre/glnxa64/jre/lib/amd64/server:/data2/matlab_runtime/linux64/v710/sys/java/jre/glnxa64/jre/lib/amd64";
$ENV{XAPPLRESDIR}  = "/data2/matlab_runtime/linux64/v710/X11/app-defaults";
$ENV{DISPLAY} = ":0.0";
$ENV{HOME} = ".";
$ENV{MATLAB_PREF} = ".";

system("df -k");
system("pwd");

print "Running here: ";
system("hostname");
print "job<$job> inputfile<$inputbase> startidx<$startidx> endidx<$endidx>\n";

system("ls -la");
system("ls -l $job $inputbase $startidx $endidx");
print "Look for access to runtime in /data2/matlab_runtime/linux64\n";
system("ls /data2/matlab_runtime/linux64");

system("ls -la");

system("printenv");
print "Running $job \n";
system("chmod 755 $job");
$res = system("./$job $inputbase $startidx $endidx");

print "Done Running $job $dir Result was <$res>\n";
if($res != 0) {
	print "Non-zero job status so exit(1)....\n";
	system("touch FAILED");
	exit(1);
}


print "Results are:";
system("ls -l");

