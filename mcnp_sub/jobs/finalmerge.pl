#! /usr/bin/env perl
use Getopt::Long;
use Cwd;

##########################################################################
#
# predivide will get the image to the run location
#
##########################################################################

my $dbinstalllog =  "finalmergecall.out";
print "Trying to open logfile... $dbinstalllog\n";
open(OLDOUT, ">&STDOUT");
open(OLDERR, ">&STDERR");
open(STDOUT, ">>$dbinstalllog") or die "Could not open $dbinstalllog: $!";
open(STDERR, ">&STDOUT");
select(STDERR);
 $| = 1;
select(STDOUT);
 $| = 1;

#########################################################
# number of mesh files and base name are passed
# we will eventually pull the mesh files from hadup
# so we wish to sum these in pairs.
# foo1 + foo2 => res1
# res1 + foo3 => res2
# res2 + foo4 => res3
# fes(N-2) + fooN = finalmesh
#########################################################

my $pieces = $ARGV[0];
my $mctalfilebase = $ARGV[1];
my $meshfilebase = $ARGV[2];
my $jobscripts = $ARGV[3];
$cwd = getcwd();

print "Starting final merge here<$cwd>\n";

my $mergemctal = "$jobscripts/merge_mctal";
my $mergemeshtal = "$jobscripts/merge_meshtal";
my $finalmesh = "final_mesh";
my $finalmctal = "final_mctal";
my $partialsum = "partial";

my $meshfiles = "";
my $count = 1;
my $result = "";
my $res = 0;

# merge mesh and mctal files
if($pieces eq "1") {
	print "$pieces mctal file\n";
	my $cmd = "mv $mctalfilebase" . ".$count $finalmctal";
	print "Executing <$cmd>\n";
	$res = system($cmd);
	if($res != 0) {
		print "Command <$cmd> returned <$res>\n";
	}
} elsif($pieces eq "2") {
	print "$pieces mctal files\n";
	my $cmd = "$mergemctal -o $finalmctal" . " -i $mctalfilebase" . ".$count";
	$count += 1;
	$cmd = $cmd . " $mctalfilebase" . ".$count";
	print "Executing <$cmd>\n";
	$res = system($cmd);
	if($res != 0) {
		print "Command <$cmd> returned <$res>\n";
	}
} else {
	print "$pieces mctal files\n";
	while($count < ($pieces + 1)) {
		if($count == 1) {
			# merge first two mesh files
			print "Trivial merge of single file\n";
			my $partial = "$partialsum" . ".$count";
			my $cmd = "$mergemctal -o $partial" . " -i $mctalfilebase" . ".$count";
			$count += 1;
			$cmd = $cmd . " $mctalfilebase" . ".$count";
			print "Executing <$cmd>\n";
			$res = system($cmd);
			if($res != 0) {
				print "Command <$cmd> returned <$res>\n";
			}
			$count += 1; # now at 3... we know we only get here for 3 or more mesh files.
			system("ls");
		} elsif($count == $pieces) {
			# merge last partial with last meshfile into final file
			print "Merge of last two files\n";
			my $pcount = ($count - 2);
			my $partial = "$partialsum" . ".$pcount";
			my $cmd = "$mergemctal -o $finalmctal" . " -i $mctalfilebase" . ".$count";
			$cmd = $cmd . " $partial";
			print "Executing <$cmd>\n";
			$res = system($cmd);
			if($res != 0) {
				print "Command <$cmd> returned <$res>\n";
			}
			system("rm $partial");
			system("ls");
			$count += 1;
		} else {
			# do an inbetween merge
			# result(N-2) merged with mctalN into result(N-1);
			print "Merge inbetween files..... \n";
			my $pcount = ($count - 2);
			my $partial = "$partialsum" . ".$pcount";
			my $tcount = ($count - 1);
			my $target = "$partialsum" . ".$tcount";
			my $cmd = "$mergemctal -o $target" . " -i $mctalfilebase" . ".$count";
			$cmd = $cmd . " $partial";
			print "Executing <$cmd>\n";
			$res = system($cmd);
			if($res != 0) {
				print "Command <$cmd> returned <$res>\n";
			}
			system("rm $partial");
			system("ls");
			$count += 1;
		}
	}
}

# reset for mesh files
$count = 1;

if($pieces eq "1") {
	print "$pieces mesh file\n";
	my $cmd = "mv $meshfilebase" . ".$count $finalmesh";
	print "Executing <$cmd>\n";
	$res = system($cmd);
	if($res != 0) {
		print "Command <$cmd> returned <$res>\n";
	}
} elsif($pieces eq "2") {
	print "$pieces mesh files\n";
	my $cmd = "$mergemeshtal -o $finalmesh" . " -i $meshfilebase" . ".$count";
	$count += 1;
	$cmd = $cmd . " $meshfilebase" . ".$count";
	print "Executing <$cmd>\n";
	$res = system($cmd);
	if($res != 0) {
		print "Command <$cmd> returned <$res>\n";
	}
} else {
	print "$pieces mesh files\n";
	while($count < ($pieces + 1)) {
		if($count == 1) {
			# merge first two mesh files
			print "Trivial merge of single file\n";
			my $partial = "$partialsum" . ".$count";
			my $cmd = "$mergemeshtal -o $partial" . " -i $meshfilebase" . ".$count";
			$count += 1;
			$cmd = $cmd . " $meshfilebase" . ".$count";
			print "Executing <$cmd>\n";
			$res = system($cmd);
			if($res != 0) {
				print "Command <$cmd> returned <$res>\n";
			}
			$count += 1; # now at 3... we know we only get here for 3 or more mesh files.
			system("ls");
		} elsif($count == $pieces) {
			# merge last partial with last meshfile into final file
			print "Merge of last two files\n";
			my $pcount = ($count - 2);
			my $partial = "$partialsum" . ".$pcount";
			my $cmd = "$mergemeshtal -o $finalmesh" . " -i $meshfilebase" . ".$count";
			$cmd = $cmd . " $partial";
			print "Executing <$cmd>\n";
			$res = system($cmd);
			if($res != 0) {
				print "Command <$cmd> returned <$res>\n";
			}
			system("rm $partial");
			system("ls");
			$count += 1;
		} else {
			# do an inbetween merge
			# result(N-2) merged with meshN into result(N-1);
			print "Merge inbetween files..... \n";
			my $pcount = ($count - 2);
			my $partial = "$partialsum" . ".$pcount";
			my $tcount = ($count - 1);
			my $target = "$partialsum" . ".$tcount";
			my $cmd = "$mergemeshtal -o $target" . " -i $meshfilebase" . ".$count";
			$cmd = $cmd . " $partial";
			print "Executing <$cmd>\n";
			$res = system($cmd);
			if($res != 0) {
				print "Command <$cmd> returned <$res>\n";
			}
			system("rm $partial");
			system("ls");
			$count += 1;
		}
	}
}

system("ls -l");

exit(0);

