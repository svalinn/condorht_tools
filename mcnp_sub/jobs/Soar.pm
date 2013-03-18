
package Soar;

require 5.0;
use Cwd;
use strict;
use warnings;
use File::Copy;
use CondorUtils;

use base 'Exporter';

my $DEBUG = 0;
my $topdir = getcwd();
my @imageruns = ();
my @dagruns = ();
my @versions = ();
my %fscache = ();

our @EXPORT = qw(fsconfig FindDagNodes debug DebugOn DebugOff LookupFsConfig FsConfig FindLatestEnv FindLatestRun ReadSetEnv FindDagNodes SetDate SetTime MakeNewProject InstallNewType InstallDerivedVersion InstallNewVersion ProcessWhiteList FindImageRuns ReadRunning DropRunning FindRunning AppendToFile LOCK_SH LOCK_EX LOCK_NB LOCK_UN CutRunFromCron UpdateRunFile VMwareAddFile VMwareRemakeDataDisk sub VMwareCreateRawDisk sub VMwareCreateMTOOLSRC VMwareFetchByPattern UpdateProjectObjects DeriveNewVersion GetJobId);
my $softwareversion = "0.7.6";

sub LOCK_SH() {1}
sub LOCK_EX() {2}
sub LOCK_NB() {4}
sub LOCK_UN() {8}

# read this install's config files
my $fsconfigfile = "/local.hd/cnerg/users/cnerg-soar/SOAR/control/fsconfig";
my $jobidfile = "JOBIDSRC";
my $initdone = FsConfig($fsconfigfile);
my %updateoptions;
#DebugOn();

BEGIN
{
    $DEBUG = 1;

	$topdir = getcwd();
	@imageruns = ();
	@dagruns = ();
	@versions = ();
	%fscache = ();
}

sub Reset
{
	@imageruns = ();
	@dagruns = ();
	@versions = ();
	%fscache = ();
}

#####################################################
#
# FsConfig locates the various resources used by SOAR
# accross multiple file systems. We no longer expect
# a predefined location relative to TOPDIR.
#
# loads up hash %fscache
#####################################################

sub FsConfig
{
	my $configfile = shift;
	#debug("FsConfig for file $configfile\n");
	my $line = "";
	my @resources = ();
	open(FIG,"<$configfile") or die "Can not open config file<$configfile>\n";
	while(<FIG>) { 
		chomp();
		$line = $_;
		@resources = split /,/, $line;
		$fscache{$resources[0]} = $resources[1]
	}
	close(FIG);
	#DropConfig();
}

my %FsMainVars = (
	"SOAR" => "1",
	"CONTROL" => "1",
	"SOURCE" => "1",
	"RESULTS" => "1",
	"TARCACHELOC" => "1",
	"CONDORRUNS" => "1",
	"IMAGERUNS" => "1",
);

sub LookupFsConfig
{
	my $request = shift;
	if(exists $fscache{$request}) {
		return($fscache{$request});
	} else {
		if( !(exists $FsMainVars{$request})) {
			# must be looking for a project that is not called out
			return($fscache{"IMAGERUNS"});
		} else {
			return("");
		}
	}
}

sub DropConfig
{
	foreach my $key ( sort keys (%fscache) ) {
		print "FsConfig: $key - $fscache{$key}\n";
	}
}

#####################################################
#
# ReadSetEnv
# Sets DATE, TOPDIR, UNIQUE, RUNLOC, RESLOC into environment
# from settings file
#
#####################################################

sub ReadSetEnv
{
	my $envfile = shift;
	my $line = "";
	debug( "Want environment variables from $envfile\n" );
	open(SAV,"<$envfile") || die "Can not open SAVE file: $!\n";
	while(<SAV>) {
    	chomp;
    	$line = $_;
		debug( "$line\n" );

    	if($line =~ /^DATE:\s*(.*)\s*$/ ) {
        	debug( "Found date <$1>\n");
			$ENV{DATE} = $1;
    	} elsif($line =~ /^TARCACHE:\s*(.*)\s*$/ ) {
        	#debug( "Found tar cache directory <<$1>\n");
			$ENV{TARCACHE} = $1;
    	} elsif($line =~ /^UNIQUE:\s*(.*)\s*$/ ) {
        	debug( "Found unique run directory <<$1>\n");
			$ENV{UNIQUE} = $1;
    	} elsif($line =~ /^DATASETS:\s*(.*)\s*$/ ) {
        	#debug( "Found data set directory <<$1>\n");
			$ENV{DATASETS} = $1;
    	} elsif($line =~ /^TOPDIR:\s*(.*)\s*$/ ) {
        	#debug( "Found top directory <<$1>\n");
			$ENV{TOPDIR} = $1;
    	} elsif($line =~ /^RUNLOC:\s*(.*)\s*$/ ) {
        	debug( "Found run directory <<$1>\n");
			$ENV{RUNLOC} = $1;
    	} elsif($line =~ /^RESLOC:\s*(.*)\s*$/ ) {
        	#debug( "Found result directory <<$1>\n");
			$ENV{RESLOC} = $1;
    	} elsif($line =~ /^SRCLOC:\s*(.*)\s*$/ ) {
        	#debug( "Found source directory <<$1>\n");
			$ENV{SRCLOC} = $1;
    	} elsif($line =~ /^PROJECT:\s*(.*)\s*$/ ) {
        	debug( "Found project <<$1>\n");
			$ENV{PROJECT} = $1;
    	} elsif($line =~ /^VERSION:\s*(.*)\s*$/ ) {
        	debug( "Found version <<$1>\n");
			$ENV{VERSION} = $1;
    	} elsif($line =~ /^KIND:\s*(.*)\s*$/ ) {
        	debug( "Found kind <<$1>\n");
			$ENV{KIND} = $1;
    	} else {
        	die "Found unexpected save <$line> \n";
    	}
	}
	close(SAV);
}


#####################################################
#
# ProcessWhiteList($imagedir, $white)
# If the file exists then check each request
# against an available data set. Return a ":"
# separated list. It is assumed for now that there is 
# one data set request per line
#
#####################################################

sub ProcessWhiteList
{
	
	my $imagedir = shift;
	my $white = shift;
	my @whiteruns;
	my $list = "";

	#DebugOn();
	debug("Setting up whitelist for data here <$imagedir> from this file <$white>\n");
	if(!(-f $white)) {
		print "White list does not exist!<$white>\n";
		exit(1);
	}

	my $line = "";
	open(WHITE,"<$white") || die "Can not open white list<$white>:$!\n";
	while(<WHITE>) {
		chomp();
		$line = $_;
		if($line =~ /^(dataset.*?)-(.*)$/) {
			debug("Testing for data dir<$imagedir/$1/$2>\n");
			if( -d "$imagedir/$1/$2") {
				push @whiteruns, "$1-$2";
			} else {
				debug("skip missing data set from dataset<$1><$imagedir/$1>\n");
			}
		} elsif($line =~ /^\s*(.*)$/) {
			debug("Look to see if $1 is a dataset\n");
			if( -d "$imagedir/$1") {
				debug("Good data set request\n");
				push @whiteruns, $1;
			} else {
				debug("skip missing data set<$imagedir/$1>\n");
			}
		}
	}
	close(WHITE);
	$list = join ":", @whiteruns;
	return($list);
}

#####################################################
#
# FindImageRuns
#
#####################################################

sub FindImageRuns
{
	my $location = shift;
	my $datasets = shift;

	#DebugOn();
	# what if we wish to run one or more specific
	# data sets?????

	debug("Looking for images here: $location\n");
	print "Looking for images here: $location\n";

	if( defined $datasets ) {
		my @datasets = split /,/, $datasets;
		debug("Datasets defined\n");
		foreach my $dataset (@datasets) {
			debug("dataset <$dataset>\n");
			if($dataset =~ /^(dataset.*)$/) {
				# handle collections of jobs
				my $subdata = "$location/$1";
				debug("My $subdata <$subdata>\n");
				my $collection = $1;
				opendir DS, $subdata or die "Can not open dataset<$1>\n";
				foreach my $subfile (readdir DS)
				{
    				next if $subfile =~ /^\.\.?$/;
					my $newname = "$collection-$subfile";
					debug("$subfile\n");
					if(-d "$subdata/$subfile") {
						push @imageruns, $newname;
					} else {
						debug("$subfile not a directory\n");
					}
				}
				closedir(DS);
			} else {
				die "Datasets must start with <dataset>. Your name <$dataset>.\n";
			}
		}
	} else {
		debug("Datasets NOT defined\n");
		opendir CH, $location or die "Can not open $location:$!\n";
		foreach my $file (readdir CH)
		{
			debug("file: <$file> \n");
			my $fullpath = "$location/$file";
    		next if $file =~ /^\.\.?$/;
			#print "Consider $fullpath\n";
			if( -d $fullpath ) {
				debug("full path <$fullpath>\n");
				if ($file =~ /^(dataset.*)$/) {
					# handle collections of jobs
					debug("folder is a dataset\n");
					my $subdata = "$location/$1";
					my $collection = $1;
					debug("Open dataset <$subdata>\n");
					opendir DS, $subdata or die "Can not open dataset<$1>\n";
					foreach my $subfile (readdir DS)
					{
    					next if $subfile =~ /^\.\.?$/;
						my $newname = "$collection-$subfile";
						debug("$subfile\n");
						if(-d "$subdata/$subfile") {
							debug("Keep <$subfile> its a dir\n");
							push @imageruns, $newname;
						} else {
							debug("skip plain file <$subfile>\n");
						}
							
					}
					closedir(DS);
				} elsif ($file =~ /^.*$/) {
					debug("$file\n");
					push @imageruns, $file;
				}
			} else {
				debug("FindImageRuns: skip plain file<$file>\n");
				next;
			}
		}
		closedir(CH);
	}
	my $list = join ":", @imageruns;
	return($list);
}

#####################################################
#
# FindDagNodes returns a list of node runtime
# directories.
#
#####################################################

sub FindDagNodes
{
	my $location = shift;
	debug("Looking for dag nodes here: $location\n");

	opendir DH, $location or die "Can not open $location:$!\n";
	foreach my $file (readdir DH)
	{
    	my $line = "";
    	next if $file =~ /^\.\.?$/;
    	#if($file =~ /^(\d+)$/) {
    	if(-d $file) {
		} else {
			next;
		}

		debug("$file\n");
		push @dagruns, $file;
	}
	closedir(DH);
	my $list = join ":", @dagruns;
	return($list);
}	


#####################################################
#
# FindVersions returns a list of versions for
# the requested project.
#
#####################################################

sub FindVersions
{
	my $location = shift;
	debug("Looking for project versions here: $location\n");

	opendir VH, $location or die "Can not open $location:$!\n";
	foreach my $file (readdir VH)
	{
    	my $line = "";
    	next if $file =~ /^\.\.?$/;

		debug("$file\n");
		push @versions, $file;
	}
	closedir(VH);
	my $list = join ":", @versions;
	return($list);
}

# =================================
# Set a time string
# =================================

sub SetTime
{
    my $time = "";
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
	# Add date to return to allow future time out of known running jobs
	# now tracked in this version. "0.7.6"
    my $date = "";
    $mon = $mon + 1; 
    $year = $year + 1900;
	$date = "$mon/$mday/$year";
    $time = "$hour:$min:$sec";
    print "Time is <$time>\n";
    return("$date-$time");
}

# =================================
# Set a date string 
# =================================     
        
sub SetDate
{       
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
    my $date = "";
    $mon = $mon + 1; 
    $year = $year + 1900;
    $date = $mon . "_" . $mday . "_" . $year;
    return($date);
}

#
# Update Run File
#

sub UpdateRunFile
{
	my $runstore = shift;
	my $rundir = shift;
	my $kind = shift;
	my $projversion =shift;
	my $currenttime = shift;
	my $runfile = $runstore . "RUNS";
	my $runfileold = $runstore . "RUNS.old";
	my $runfilenew = $runstore . "RUNS.NEW";

	if( -f $runfile ) {
    	open(OLD,"<$runfile") || die "Can not open current runs<$runfile>:$!\n";
    	open(NEW,">$runfilenew") || die "Can not open new run file<$runfilenew>:$!\n";
	
    	# newest always first in list
    	print NEW "$rundir | $kind | $projversion | $currenttime \n";
    	while(<OLD>){
        	print NEW "$_";
    	}    
    	close(NEW);
    	close(OLD);
    	copy("$runfile", "$runfileold");
    	copy("$runfilenew", "$runfile");
	} else {
    	open(OLD,">$runfile") || die "Can not open current runs<$runfile>:$!\n";
	
    	# newest always first in list
    	print OLD "$rundir | $kind | $projversion | $currenttime \n";
    	close(OLD);
	}
}


# =================================
# We currently have two crons.
#	checkprogress.cron
#		periodically runs a report and makes 
#		a profile of the last run for the project
#	continuous.cron
#		starts a repeat oneoff run of all 
#		current data sets
# =================================     

my $statcron = "checkprogress.cron";
my $continuous = "continuous.cron";

sub AddToContinuousCron
{
}

sub AddToStatCron
{
	my $topdir = shift; # no longer used
	my $project = shift;
	my $control = LookupFsConfig("CONTROL");
	my $file = $control . "/" . $statcron;
	my $appendtext = "./status.pl --project=" . $project . " --kind=profile --period=300 --last";
	AppendToFile( $appendtext, $file, "$control/CRON" );
	$appendtext = "./status.pl --project=" . $project . " --kind=summary --last";
	AppendToFile( $appendtext, $file, "$control/CRON" );
}

sub AppendToFile
{
	# assume these are cron executables and make the new files 755
	my $text = shift;
	my $file = shift;
	my $lockfile = shift;
	my $tmpfile = $file . ".tmp";

	print "About to lock<$lockfile> to change<$file>\n";
	# Lock operations on append to file
	open( APPLOCK, ">$lockfile") or die "Failed to open<$lockfile>:$!\n";
	while(! flock(APPLOCK, LOCK_EX)) {
		print "Waiting to lock profile and report file\n";
		sleep 1;
	}

	debug("Locked $lockfile\n");

	# copy existing data to new file
	open( TAR, "<$file") or die "Failed to open<$file>:$!\n";
	open( NEWTAR, ">$tmpfile") or die "Failed to open<$tmpfile>:$!\n";
	while(<TAR>) {
		print NEWTAR "$_";
	}
	close(TAR);

	# append new data to file
	print NEWTAR "$text\n";
	close(NEWTAR);
	copy("$file", "$file.old") or die "copy $file to $file.old failed:$!\n";
	copy("$tmpfile", "$file") or die "copy $tmpfile to $file failed:$!\n";
	runcmd("chmod 755 $file",{emit_output=>0});
	runcmd("rm $tmpfile",{emit_output=>0});

	#free lock
	flock(APPLOCK, LOCK_UN) or die "WARNING: Failed to unlock<$lockfile>:$!\n";
	debug( "UN-Locked $lockfile\n" );
	close(APPLOCK);
}

sub CutRunFromCron
{
	# assume these are cron executables and make the new files 755
	my $run = shift;
	my $file = shift;
	my $lockfile = shift;
	my $tmpfile = $file . ".tmp";

	debug( "About to lock<$lockfile> to change<$file> for run<$run>\n" );
	# Lock operations on append to file
	open( LOCK, ">$lockfile") or die "Failed to open<$lockfile>:$!\n";
	while(! flock(LOCK, LOCK_EX)) {
		print "Waiting to lock profile and report file\n";
		sleep 2;
	}
	debug( "Locked $lockfile\n" );

	# copy existing data to new file
	open( TAR, "<$file") or die "Failed to open<$file>:$!\n";
	open( NEWTAR, ">$tmpfile") or die "Failed to open<$tmpfile>:$!\n";
	my $line = "";
	while(<TAR>) {
		chomp();
		$line = $_;
		if($line =~ /^.*$run.*$/) {
			# don't copy lines for this run
		} else {
			print NEWTAR "$line\n";
		}
	}
	close(TAR);

	close(NEWTAR);
	copy("$file", "$file.old") or die "copy $file to $file.old failed:$!\n";
	copy("$tmpfile", "$file") or die "copy $tmpfile to $file failed:$!\n";
	runcmd("chmod 755 $file",{emit_output=>0});
	runcmd("rm -f $tmpfile",{emit_output=>0});

	#free lock
	flock(LOCK, LOCK_UN) or die "WARNING: Failed to unlock<$lockfile>:$!\n";
	debug( "UN-Locked $lockfile\n" );
	close(LOCK);
}

        
#####################################################

#
# InstallDerivedVersion($srcloc,$codedir,$version,$preversion,$topdir,$newproject);
#
#####################################################

sub InstallDerivedVersion
{
	my $srcloc = shift;
	my $codedir = shift;
	my $newversion = shift;
	my $srcversion = shift;
	my $newproject = shift;
	my $homedir = getcwd();

	print "Home in InstallDerivedVersion<$homedir>\n";

	# ensure all the key directories exist for a project

	print "Calling  MakeNewProject ($newproject)\n";

	MakeNewProject($newproject);
	
	my $sourceloc = LookupFsConfig("SOURCE");
	my $newloc = "$sourceloc/$newproject/$newversion";
	my $newcode = "$newloc/code";
	my $newjobs = "$newloc/jobs";
	my $oldjobs = "$srcloc/$srcversion/jobs";
	my $oldcode = "$srcloc/$srcversion/code";

	# Make sure reference version exists
	# and the code to install
	debug("Installing: create project <$newproject> from <$srcloc> vs <$srcversion >\n");

	if( -d $newloc) {
		print "Requested new version <$newversion> already exists. Die\n";
		exit(1);
	}

	if(!( -d $oldjobs)) {
		print "Source for job scripts<$oldjobs> does not exist!!!!!!... Die\n";
		exit(1);
	}

	if(!( -d $oldcode)) {
		print "Source for job scripts<$oldcode> does not exist!!!!!!... Die\n";
		exit(1);
	}

	debug("Create: $newloc $newcode $newjobs\n");
	runcmd("mkdir -p $newloc",{emit_output=>0});
	runcmd("mkdir -p $newcode",{emit_output=>0});
	runcmd("mkdir -p $newjobs",{emit_output=>0});

	# get new code in place
	runcmd("cp $oldcode/* $newcode",{emit_output=>0});

	# copy job scripts to new version
	runcmd("cp $oldjobs/* $newjobs",{emit_output=>0});
	#AddToStatCron( $topdir, $newproject);
}

#####################################################
#
# InstallNewType($srcloc,$projversion,$topdir,$type,$datasets);
#
#####################################################

sub InstallNewType
{
	my $srcloc = shift;
	my $projversion = shift;
	my $type = shift;
	my $datasets = shift;

	print "In InstallNewType with srcloc<$srcloc> and datasets<$datasets>\n";
	print "Type = $type\n";

	my $target = "";
	my $destination = "";

	if($type == "param.dat") {
		$target = $datasets . "/param.dat";
		$destination = $srcloc . "/" . $projversion . "/code";
		copy("$target", "$destination") or die "copy $target to $destination failed:$!\n";
	} else {
		die "Not a supported type<$type>\n";
		exit(0);
	}
}

#####################################################
#
# InstallNewVersion($srcloc,$codedir,$version,$preversion); 
#
#####################################################

sub InstallNewVersion
{
	my $srcloc = shift;
	my $codedir = shift;
	my $newversion = shift;
	my $srcversion = shift;
	my $ref_mcctarget_array = shift;
	my $homedir = getcwd();

	print "Home in InstallNewVersion<$homedir>\n";

	my $newloc = "$srcloc/$newversion";
	my $newcode = "$srcloc/$newversion/code";
	my $newjobs = "$srcloc/$newversion/jobs";
	my $oldjobs = "$srcloc/$srcversion/jobs";

	# Make sure reference version exists
	# and the code to install
	debug("Installing: srcloc is $srcloc\n");
	if( -f "$codedir") {
		debug("Good tar ball exists\n");
	}

	if( -d $newloc) {
		print "Requested new version <$newversion> already exists. Die\n";
		exit(1);
	}

	if(!( -d $oldjobs)) {
		print "Source for job scripts<$oldjobs> does not exist!!!!!!... Die\n";
		exit(1);
	}

	debug("Create: $newloc $newcode $newjobs\n");
	runcmd("mkdir -p $newloc",{emit_output=>0});
	runcmd("mkdir -p $newcode",{emit_output=>0});
	runcmd("mkdir -p $newjobs",{emit_output=>0});

	# get new code in place
	copy("$codedir", "$newcode") 
		or die "Copy of $codedir to $newcode failed:$!\n";
	chdir("$newcode");
	runcmd("tar -zxvf $codedir",{emit_output=>0});
	chdir("$homedir");
	runcmd("pwd");

	# copy job scripts to new version
	runcmd("cp $oldjobs/* $newjobs",{emit_output=>0});

	#compile matlab code.

	foreach my $item (@{$ref_mcctarget_array}) {
		print "Compiling $item\n";
		RunMatlabCC($item,$newcode);
	}
}

#####################################################
#
# DeriveNewVersion($srcloc,$version,$preversion); 
#
# We have code updates but have been requested to make
# it a new version.
#
#####################################################

sub DeriveNewVersion
{
	my $srcloc = shift;
	my $srcversion = shift;
	my $newversion = shift;
	my $homedir = getcwd();

	print "Home in InstallNewVersion<$homedir>\n";

	chdir("$srcloc");
	my $newloc = "$srcloc/$newversion";
	my $oldloc = "$srcloc/$srcversion";

	my $derivecmd = "cp -r $oldloc $newloc"; 
	# Make sure reference version exists
	# and the code to install
	debug("Installing: srcloc is $srcloc\n");

	if( -d $newloc) {
		print "Requested new version <$newversion> already exists. Die\n";
		exit(1);
	}

	# Duplicate old version to new location
	runcmd($derivecmd);

	chdir("$homedir");
}

#####################################################
#
# Make New Project ensures all proper directories exist
# and it does not squawk if project exists.
#
#		MakeNewProject($topdir, $project);
#
#####################################################

sub MakeNewProject
{
	my $newproject = shift;

	print "topdir <$topdir> newproject <$newproject>\n";
	my $tmp = LookupFsConfig("CONDORRUNS");
	if( $tmp eq "" ) {
		die "MakeNewProject failed to lookup CONDORRUNS\n";
	}
	my $projrunloc = $tmp . "/" . $newproject;

	$tmp = LookupFsConfig("RESULTS");
	if( $tmp eq "" ) {
		die "MakeNewProject failed to lookup RESULTS\n";
	}
	my $projresultsloc = $tmp . "/" . $newproject;

	$tmp = LookupFsConfig("TARCACHELOC");
	if( $tmp eq "" ) {
		die "MakeNewProject failed to lookup TARCACHELOC\n";
	}
	my $projtarcache = $tmp . "/" . $newproject;

	$tmp = LookupFsConfig("SOURCE");
	if( $tmp eq "" ) {
		die "MakeNewProject failed to lookup SOURCE\n";
	}
	my $projsources = $tmp . "/" . $newproject;

	print "projrunloc <$projrunloc>\n";
	print "projresultsloc <$projresultsloc>\n";
	print "projtarcache <$projtarcache>\n";
	print "projsources <$projsources>\n";
	runcmd("mkdir -p $projrunloc",{emit_output=>0});
	runcmd("mkdir -p $projresultsloc",{emit_output=>0});
	runcmd("mkdir -p $projtarcache",{emit_output=>0});
	runcmd("mkdir -p $projsources",{emit_output=>0});

	if((!(-d $projrunloc)) || (!(-d $projresultsloc))) {
		die "Trouble establishing either $projrunloc or $projresultsloc\n";
	}
	if((!(-d $projtarcache)) || (!(-d $projsources))) {
		die "Trouble establishing either $projtarcache or $projsources\n";
	}
}

#####################################################
#
# Run Matlab Compiler on rundir
#
#####################################################

sub RunMatlabCC
{
	my $targetfile = shift;
	my $targetloc = shift;

	print "In RunMatlabCC - $targetfile $targetloc\n";
    my $here = getcwd();
    my $mcc_cmd = "mcc -m -R -nodisplay -R -nojvm $targetfile";
    chdir("$targetloc");
    runcmd("$mcc_cmd",{emit_output=>0});
    chdir("$here");
}

#####################################################
#
# FindRunning
#
# If we are doing new jobs, we want to exclude currently 
# running jobs so collect all jobs in .running files.
# Find them by reading through the RUN file for run directories.
#
# Take care that jobs are removed with soar_rm(not written)
# so that jobs have a couple things done when they are removed.
# 1. The continuous report and profiling must be stopped
# 2. The .running file must be removed
# 
# Note an automatic pair of entries are created for each run
# such that a profile and a report will(not done yet)
# happen thus allowing a constant updating of the jobs
# currently running.
#####################################################

sub FindRunning
{
	my $location = shift;
	my $project = shift;
	my $version = shift;
	my $resultref = shift;
	my $lastrunfile = "";
	my @collectrunning;

	if(defined $version) {
		print "Looking for running jobs for <$project>/<$version>\n";
	}
	my $runfile = $location . "/" . $project . "/RUNS";
	my $runningfilebase = $location . "/" . $project . "/";
	my $runningfile = $location . "/" . $project . "/";
	open(RUN,"<$runfile") || die "Can not open run file<$runfile> for finding most recent run:$!\n";
	my $latest = "";
	my @runstuff = ();
	while(<RUN>) {
		chomp();
		$latest = $_;
		$latest =~ s/ //g;
		#print "<<<<<<<<< $latest >>>>>>>>>>>>>>\n";
		# current format  run, kind, version, time
		@runstuff = split /\|/, $latest;
		#print "<<<<<<<<<$runstuff[0],$runstuff[1],$runstuff[2],$runstuff[3]>>>>>>>>\n";
		if($runstuff[2] eq $version) {
			#print "$runstuff[0] matches version\n";
			$runningfile = "$runningfilebase$runstuff[0]/$runstuff[0].running";
			if(( -f $runningfile ) &&($runstuff[1] ne "oneoff")) {
				@collectrunning = ();
				print "Runnning file exists<$runningfile>\n";
				ReadRunning($runningfile,\@collectrunning);
				foreach my $job (@collectrunning) {
					push @{$resultref}, $job;
				}
			}
		}
	}
	close(RUN);
}

#####################################################
#
# Find the latest run of a project and return environment 
# file to use.
#
# This version uses the Project Wide RUNS file
# in the COBNDORRUNS/project directory
#
#####################################################

sub FindLatestRun
{
	my $location = shift;
	my $project = shift;
	my $version = shift;
	my $lastrunfile = "";

	if(defined $version) {
		print "Looking for last run for version <$version>\n";
	}
	my $runfile = $location . "/" . $project . "/RUNS";
	open(RUN,"<$runfile") || die "Can not open run file<$runfile> for finding most recent run:$!\n";
	my $latest = "";
	my @runstuff = ();
	while(<RUN>) {
		chomp();
		$latest = $_;
		$latest =~ s/ //g;
		print "<<<<<<<<< $latest >>>>>>>>>>>>>>\n";
		# current format  run, kind, version, time
		@runstuff = split /\|/, $latest;
		print "<<<<<<<<<$runstuff[0],$runstuff[1],$runstuff[2],$runstuff[3]>>>>>>>>\n";
		if(defined $version) {
			if($runstuff[2] eq $version) {
				$latest = $runstuff[0];
				print "Latest for version $version is $latest\n";
				last;
			}
		} else {
			$latest = $runstuff[0];
			last;
		}
	}
	close(RUN);
	$lastrunfile = $location . "/" . $project . "/ENVVARS$latest";
	print "Most recent run: $lastrunfile\n";
	return($lastrunfile);
}

sub DropRunning
{
	my $file = shift;
	my $dataref = shift;
	my @testarray;
	print "Dropping running file<$file>\n";
	open(RUN,">$file") or die "Can not open for W($file):$!\n";
	while(! flock(RUN, LOCK_EX)) {
		print "Waiting to lock running file\n";
		sleep 1;
	}
	foreach my $run (@{$dataref}) {
		print RUN "$run\n";
	}
	flock(RUN, LOCK_UN) or die "WARNING: Failed to unlock<$file>:$!\n";
	close(RUN);
}

sub ReadRunning
{
	my $file = shift;
	my $dataref = shift;
	print "Reading running file<$file>\n";
	open(RRUN,"<$file") or die "Can not open for R($file):$!\n";
	while(! flock(RRUN, LOCK_EX)) {
		print "Waiting to lock running file\n";
		sleep 1;
	}
	while(<RRUN>) {
		chomp();
		push @{$dataref}, $_;
		debug("$_ found still running\n");
	}
	flock(RRUN, LOCK_UN) or die "WARNING: Failed to unlock<$file>:$!\n";
	close(RRUN);
}

#####################################################
#
# locking code
#
# We are going to have the report writing also drop
# those jobs which we suspect are still running though
# they may have ended badly. But since the control script
# will be checking it when asked to do all the new jobs
# (--kind=new) we will lock(WaitForLock) the running file 
# before we write to it and then unlock it when we are done.
#
# The control script will always call the WaitForLock
# and then FileUnlock to keep it from being changed in 
# the middle.
#
#####################################################

#####################################################
#
#	VM Universe code for VmWare
#
#	Initializing the VM for a job and accessing the
#	results are done by including a suitable second
#	VmWare disk. This disk is created for dynamic
#	allocation and created in a VM which can use fdisk
#	to create a fat32 partition and must have an
#	mkfs which allows a "-t vfat" to complete creation
#	of the disk.
#
#	Once one has this disk it can be used as a template
#	second drive for any VmWare VM. Note keep the core
#   empty disk and copy it when needed as it gets
#	larger with every use.
#
#	We rely on "mtools" and "qemu" for the rest.
#	"qemu-img" is used to convert the disk back and forth
#	between vmdk and raw formats. "mcopy, mdir etc"
#	are used to place and fetch files off the raw
#	disk.
#
#####################################################

sub VMwareAddFile
{
    my $file = shift;
    runcmd("mcopy $file n:");
    runcmd("mdir n:");
}

sub VMwareFetchByPattern
{
    my $pattern = shift;
    runcmd("mcopy n:\*$pattern* .");
    runcmd("mdir n:");
}

sub VMwareRemakeDataDisk
{
    my $data = shift;
    my $raw = shift;

    my $cmd = "qemu-img convert -f raw $raw -O vmdk $data";
    runcmd($cmd);
}

sub VMwareCreateRawDisk
{
    my $empty = shift;
    my $raw = shift;

    my $cmd = "qemu-img convert -f vmdk $empty -O raw $raw";
    runcmd($cmd);
}

sub VMwareCreateMTOOLSRC
{
    my $rawdisk = shift;
    my $top = getcwd();
    my $baseentry = "drive n: file=\"$top/$rawdisk\" offset=32256 mtools_skip_check=1";
    print "Making MTOOLSRC here<$top>\n";
    open(MTRC,">$top/mtoolsrc") or die "Can not open mtoolsrc in <$top>:$!\n";
    print MTRC "$baseentry\n";
    close(MTRC);
    $ENV{MTOOLSRC} = "$top/mtoolsrc";
    runcmd("mdir n:");
}

#####################################################
#
# Code to allow projects to change out their analysis
# objects.
#
#####################################################


sub UpdateProjectObjects
{
	my $newobjloc = shift;
	my $projsrcloc = shift;
	my $projversion = shift;
	my $configfile = shift;
	my $codedir = "$projsrcloc/$projversion/code";
	my $cwd = getcwd();
	my %failreturn;
	my $didupdate = 0;


	#DebugOn();
	debug("Call ParseUpdateOptions on <$configfile>\n");
	ParseUpdateOptions($configfile);
	debug("Back from ParseUpdateOptions(update options now:\n");

	foreach my $key (keys %updateoptions) {
		print "key: $key value $updateoptions{\"$key\"}\n"
	}

	debug("Moving on in UpdateProjectObjects\n");
	debug("Checking for files in obj location<$newobjloc>\n");
	#runcmd("ls $newobjloc");
	debug("Compare against code location<$codedir>\n");
	#runcmd("ls $codedir");
	debug("Test for config file\n");
	if( -f $configfile ) {
		debug("Yeah. We have needed config file which follows\n");
		#runcmd("cat $configfile");
	} else {
		debug("Oops. no config file for project object updates\n");
	}

	chdir("$codedir");

	# can we get at new objects?
	if((-d $newobjloc) && (!(-R $newobjloc))) {
		print "Sorry, Code updates require more open permissions\n";
		$failreturn{"success"} = 0;
		return \%failreturn;
	}

	my $newM;
	my $oldM;
	my $tmppath;
	my $tmpnew;
	my $matlabseen = "no";
	my @movethese;

	opendir DS, $codedir or die "Can not open dataset<$1>\n";
	foreach my $subfile (readdir DS)
	{
    	next if $subfile =~ /^\.\.?$/;
		debug("examine: $subfile\n");
		if(-d "$subfile") {
			debug("skip directory <$subfile>\n");
		} else {
			debug("considering <$subfile>\n");
			$tmpnew = "$newobjloc/$subfile";
			next if (!(-f $tmpnew));
			$newM = -M "$newobjloc/$subfile";
			$tmppath = "$codedir/$subfile";
			debug("does old version <$tmppath> exist?");
			if(!(-f $tmppath)) {
				print "Nope.........\n";
			} else {
				$oldM = -M "$tmppath";
				print "New <$subfile> $newM old $oldM\n";
				if($newM < $oldM) {
					$didupdate += 1;
					debug("We should update <$subfile>\n");
					if($subfile =~ /^[\w\d_]+\.m$/) {
						$matlabseen = "yes";
						debug("Marking matlabseen!!!!!\n");
					}
					push @movethese, $tmpnew;
				}
			}
		}
	}
	closedir(DS);
	# the updte depends on what we have for a version
	# request. No version or different version or same
	# verson. Only for diferent do we create a new version
	# if and ony if it does not already exist.
	my $parsedversion = "";
	my $copytoversion = "";

	$parsedversion = $updateoptions{"version"};
	#print "Version in config file is<$parsedversion>\n";

	#foreach my $key (keys %updateoptions) {
		#print "key: $key value $updateoptions{\"$key\"}\n"
	#}

	if( exists $updateoptions{"version"}) {
		debug("Version mention in objconfig file <$parsedversion> project version <$projversion>\n");
		if($parsedversion ne $projversion) {
			# will be updating a derived version
			DeriveNewVersion($projsrcloc,$projversion,$parsedversion);
			$copytoversion = $parsedversion;
		} else {
			# updating the current version
			$copytoversion = $projversion;
		}
	}

	# Now copy replacement files
	my $copytocmd = "";
	foreach my $file (@movethese) {
		runcmd("cp $file $projsrcloc/$copytoversion/code");
	}

	# back where we started
	chdir("$cwd");

	# do we have to recompile??????

	if($matlabseen  eq "yes") {
		debug("about to process matlab re-compile directives\n");
		chdir("$projsrcloc/$copytoversion/code");
		#runcmd("pwd;ls -lt");

		my $mcccmd = "";
		if(exists $updateoptions{"matlabtarg"}) {
			my @mcctargets = split /,/, $updateoptions{"matlabtarg"};
			$ENV{PATH} = "/home/gcc423/bin:$ENV{PATH}";
			#runcmd("which gcc");
			foreach my $target (@mcctargets) {
				$mcccmd = "mcc -m -R -nodisplay -R -nojvm $target";
				debug("Compile $target with cmd <$mcccmd>\n");
				runcmd($mcccmd);
			}
		} else {
			die "New matlab code but \"matlabtarg\" not set on objconfig file\n";
		}
	} else {
		debug("No matlab files seen\n");
	}

	chdir("$cwd");

	print "UpdateProjectObjects updated $didupdate objects\n";
	if($didupdate == 0) {
		# we don't want to act on old options for an old update check
		$failreturn{"success"} = 1;
		return \%failreturn;
	}
	return \%updateoptions
}

# =================================
# ParseUpdateOptions will hash entries desired to tune automatic
# updates things like if a new version is wanted, what limit count
# for first run, run on existing(oneoff) or new only data sets,
# if matlab, which m files to compile..... etc
# =================================

sub ParseUpdateOptions
{
	my $options = shift;
	debug("ParseUpdateOptions on file <$options>\n");

	if(!(-f $options)) {
		print "No update configuration file present at <$options>\n";
		return(0);
	}

	open(NORUNS,"<$options") || die "Can not open <$options>: $!\n";
	while(<NORUNS>) {
		if($_ =~ /^(\w+)\s*=\s*(.*)\s*$/) {
			print "Option $1 = $2\n";
			$updateoptions{$1} = $2;
		} else {
			#print "no match: $_";
		}

	}
	close(NORUNS);
	$updateoptions{"success"} = 1;
	#print "After parseing options:\n";
	#foreach my $key (keys %updateoptions) {
		#print "$key yields $updateoptions{\"$key\"}\n";
	#}
	debug("Leaving ParseUpdateOptions\n");
}

sub GetJobId
{
	my $jobid = 1;
	my $line = "";

	#DebugOn();
	debug("About to lock<$jobidfile>\n");
	if(!(-f $jobidfile)) {
		# if file does not exist create for writing and insert
		# an prepare to write an initial job id into file
		open( JOBIDLOCK, ">$jobidfile") or die "Failed to open<$jobidfile>:$!\n";
		# Lock operations on append to file
		while(! flock(JOBIDLOCK, LOCK_EX)) {
			print "Waiting to lock profile and report file\n";
			sleep 1;
		}
		debug("Locked $jobidfile\n");
	} else {
		# Lock operations on append to file
		open( JOBIDLOCK, "<$jobidfile") or die "Failed to open<$jobidfile>:$!\n";
		while(! flock(JOBIDLOCK, LOCK_EX)) {
			print "Waiting to lock profile and report file\n";
			sleep 1;
		}
		debug("Locked $jobidfile\n");
		# get last issued job id and prepare job id to be re-entered
		# into job id file
		$line = "";
		while(<JOBIDLOCK>) {
			chomp();
			$line = $_;
			$jobid = $line + 1;
		}
		close(JOBIDLOCK);

		# now open the locked file for writing
		open( JOBIDLOCK, ">$jobidfile") or die "Failed to open<$jobidfile>:$!\n";
	}

	print JOBIDLOCK "$jobid\n";
	#free lock
	flock(JOBIDLOCK, LOCK_UN) or die "WARNING: Failed to unlock<$jobidfile>:$!\n";
	debug( "UN-Locked $jobidfile\n" );
	close(JOBIDLOCK);
	debug("GetJobId returning $jobid\n");
	DebugOff();

	return($jobid);
}



#####################################################
#
# Debug code
#
#####################################################

sub debug
{
    my $string = shift;
    print( "DEBUG ", timestamp(), ": $string" ) if $DEBUG;
}

sub DebugOn
{
    $DEBUG = 1;
}

sub DebugOff
{
    $DEBUG = 0;
}

sub timestamp {
    return scalar localtime();
}

1;
