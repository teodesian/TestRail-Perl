#!/usr/bin/env perl

use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::Fatal;
use App::Prove;
use App::Prove::Plugin::TestRail;
use IO::Capture::Stdout;

my $capture_out = IO::Capture::Stdout->new();

#silence
sub do_run {
    my ($prove) = @_;
    $capture_out->start;
    $prove->run();
    $capture_out->stop;
}

#I'm the secret squirrel
$ENV{'TESTRAIL_MOCKED'} = 1;

#Test the same sort of data as would come from the Test::Rail::Parser case
my $prove = App::Prove->new();
$prove->process_args("-PTestRail=apiurl=http://some.testlink.install/,user=someUser,password=somePassword,project=TestProject,run=TestingSuite,version=0.014,case_per_ok=1",'t/fake.test');

is (exception {do_run($prove)},undef,"Running TR parser case via plugin functions");

#Check that plan, configs and version also make it through
$prove = App::Prove->new();
$prove->process_args("-PTestRail=apiurl=http://some.testlink.install/,user=someUser,password=somePassword,project=TestProject,run=Executing the great plan,version=0.014,case_per_ok=1,plan=GosPlan,configs=testConfig",'t/fake.test');

is (exception {do_run($prove)},undef,"Running TR parser case via plugin functions works with configs/plans");


