#!/usr/bin/env perl

my $dbinstalllog =  "pushdatascript.out";
print "Trying to open logfile... $dbinstalllog\n";
open(OLDOUT, ">&STDOUT");
open(OLDERR, ">&STDERR");
open(STDOUT, ">>$dbinstalllog") or die "Could not open $dbinstalllog: $!";
open(STDERR, ">&STDOUT");
select(STDERR);
 $| = 1;
select(STDOUT);
 $| = 1;

my $resultdir = shift;
my $project = shift;

print "Pushdata for project<$project> in directory<$resultdir>\n";
system("date");

if($resultdir =~ /^.*\/(\d+)\s*$/) {
    system("pwd");
    chdir($resultdir);
    system("pwd;ls");
    my $name = $resultdir . "/cnerg" . $1 . ".tar.gz";
    print "creating $name";
    system("tar -zcvf $name *");
} else {
    print "Bad format push target<$resultdir>\n";
}
system("date");


