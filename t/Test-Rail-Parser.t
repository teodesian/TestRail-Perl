#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use Scalar::Util qw{reftype};
use TestRail::API;
use Test::LWP::UserAgent::TestRailMock;
use Test::Rail::Parser;
use Test::More 'tests' => 99;
use Test::Fatal qw{exception};

#Same song and dance as in TestRail-API.t
my $apiurl = $ENV{'TESTRAIL_API_URL'};
my $login  = $ENV{'TESTRAIL_USER'};
my $pw     = $ENV{'TESTRAIL_PASSWORD'};
my $is_mock = (!$apiurl && !$login && !$pw);

($apiurl,$login,$pw) = ('http://testrail.local','teodesian@cpan.org','fake') if $is_mock;
my ($debug,$browser);

$debug = 1;
if ($is_mock) {
    $browser = $Test::LWP::UserAgent::TestRailMock::mockObject;
}

#test exceptions...
#TODO

#case_per_ok mode
my $fcontents = "
fake.test ..
1..2
ok 1 - STORAGE TANKS SEARED
#goo
not ok 2 - NOT SO SEARED AFTER ARR
";
my $tap;

my $opts = {
    'tap'                 => $fcontents,
    'apiurl'              => $apiurl,
    'user'                => $login,
    'pass'                => $pw,
    'debug'               => $debug,
    'browser'             => $browser,
    'run'                 => 'TestingSuite',
    'project'             => 'TestProject',
    'merge'               => 1,
    'case_per_ok'         => 1
};

my $res = exception { $tap = Test::Rail::Parser->new($opts) };
is($res,undef,"TR Parser doesn't explode on instantiation");
isa_ok($tap,"Test::Rail::Parser");

if (!$res) {
    $tap->run();
    is($tap->{'errors'},0,"No errors encountered uploading case results");
}

undef $tap;
delete $opts->{'tap'};
$opts->{'source'} = 't/fake.test';
$res = exception { $tap = Test::Rail::Parser->new($opts) };
is($res,undef,"TR Parser doesn't explode on instantiation");
isa_ok($tap,"Test::Rail::Parser");

if (!$res) {
    $tap->run();
    is($tap->{'errors'},0,"No errors encountered uploading case results");
}

$fcontents = "ok 1 - STORAGE TANKS SEARED
# whee
not ok 2 - NOT SO SEARED AFTER ARR

#   Failed test 'NOT SO SEARED AFTER ARR'
#   at t/fake.test line 10.
# Looks like you failed 1 test of 2.
";
like($tap->{'raw_output'},qr/SEARED\n# whee.*\n.*AFTER ARR\n\n.*Failed/msxi,"Full raw content uploaded in non step results mode");

#Check that time run is being uploaded
my $timeResults = $tap->{'tr_opts'}->{'testrail'}->getTestResults(1);
if ( ( reftype($timeResults) || 'undef') eq 'ARRAY') {
    is( $timeResults->[0]->{'elapsed'}, '2s', "Plugin correctly sets elapsed time");
} else {
    fail("Could not get test results to check elapsed time!");
}

#Check the time formatting routine.
is(Test::Rail::Parser::_compute_elapsed(0,0),undef,"Elapsed computation correct at second boundary");
is(Test::Rail::Parser::_compute_elapsed(0,61),'1m 1s',"Elapsed computation correct at minute boundary");
is(Test::Rail::Parser::_compute_elapsed(0,3661),'1h 1m 1s',"Elapsed computation correct at hour boundary");
is(Test::Rail::Parser::_compute_elapsed(0,86461),'24h 1m 1s',"Elapsed computation correct at day boundary");

#Time for non case_per_ok mode
undef $tap;
$opts->{'source'} = 't/faker.test';
$opts->{'run'} = 'OtherOtherSuite';
delete $opts->{'case_per_ok'};
$opts->{'step_results'} = 'step_results';

$res = exception { $tap = Test::Rail::Parser->new($opts) };
is($res,undef,"TR Parser doesn't explode on instantiation");
isa_ok($tap,"Test::Rail::Parser");

if (!$res) {
    $tap->run();
    is($tap->{'errors'},0,"No errors encountered uploading case results");
    is($tap->{'global_status'},5, "Test global result is FAIL when one subtest fails even if there are TODO passes");
    subtest 'Timestamp/elapsed printed in step results' => sub {
        foreach my $result (@{$tap->{'tr_opts'}->{'result_custom_options'}->{'step_results'}}) {
            like($result->{'content'}, qr/^\[.*\(.*\)\]/i, "Timestamp printed in step results");
        }
    };
}

#Default mode
undef $tap;
delete $opts->{'step_results'};
$res = exception { $tap = Test::Rail::Parser->new($opts) };
is($res,undef,"TR Parser doesn't explode on instantiation");
isa_ok($tap,"Test::Rail::Parser");

if (!$res) {
    $tap->run();
    is($tap->{'errors'},0,"No errors encountered uploading case results");
    my @matches = $tap->{'raw_output'} =~ m/^(\[.*\(.*\)\])/msgi;
    ok(scalar(@matches),"Timestamps present in raw TAP");
}

#Default mode
undef $tap;
$fcontents = "
fake.test ..
1..2
ok 1 - STORAGE TANKS SEARED
    #Subtest NOT SO SEARED AFTER ARR
    ok 1 - STROGGIFY POPULATION CENTERS
    not ok 2 - STROGGIFY POPULATION CENTERS
#goo
not ok 2 - NOT SO SEARED AFTER ARR
";
$opts->{'tap'} = $fcontents;
delete $opts->{'source'};
delete $opts->{'step_results'};
$opts->{'run'} = 'TestingSuite';
$opts->{'case_per_ok'} = 1;
$res = exception { $tap = Test::Rail::Parser->new($opts) };
is($res,undef,"TR Parser doesn't explode on instantiation");
isa_ok($tap,"Test::Rail::Parser");

if (!$res) {
    $tap->run();
    is($tap->{'errors'},0,"No errors encountered uploading case results");
}

#skip/todo in case_per_ok
undef $tap;
delete $opts->{'tap'};
$opts->{'source'} = 't/skip.test';
$res = exception { $tap = Test::Rail::Parser->new($opts) };
is($res,undef,"TR Parser doesn't explode on instantiation");
isa_ok($tap,"Test::Rail::Parser");

if (!$res) {
    $tap->run();
    is($tap->{'errors'},0,"No errors encountered uploading case results");
}

#Default mode skip (skip_all)
undef $tap;
$opts->{'source'} = 't/skipall.test';
delete $opts->{'case_per_ok'};
$res = exception { $tap = Test::Rail::Parser->new($opts) };
is($res,undef,"TR Parser doesn't explode on instantiation");
isa_ok($tap,"Test::Rail::Parser");

if (!$res) {
    $tap->run();
    is($tap->{'errors'},0,"No errors encountered uploading case results");
    is($tap->{'global_status'},6, "Test global result is SKIP on skip all");
}

#Ok, let's test the plan, config, and spawn bits.
undef $tap;
$opts->{'run'} = 'hoo hoo I do not exist';
$opts->{'plan'} = 'mah dubz plan';
$opts->{'configs'} = ['testPlatform1'];
$res = exception { $tap = Test::Rail::Parser->new($opts) };
isnt($res,undef,"TR Parser explodes on instantiation when asking for run not in plan");

undef $tap;
$opts->{'run'} = 'TestingSuite';
$opts->{'configs'} = ['testConfig'];
$res = exception { $tap = Test::Rail::Parser->new($opts) };
is($res,undef,"TR Parser doesn't explode on instantiation looking for existing run in plan");
isa_ok($tap,"Test::Rail::Parser");

if (!$res) {
    $tap->run();
    is($tap->{'errors'},0,"No errors encountered uploading case results");
}

#Now, test spawning.
undef $tap;
$opts->{'run'} = 'TestingSuite2';
$opts->{'configs'} = ['testPlatform1'];
$opts->{'testsuite_id'} = 9;
$res = exception { $tap = Test::Rail::Parser->new($opts) };
is($res,undef,"TR Parser doesn't explode on instantiation when spawning run in plan");
isa_ok($tap,"Test::Rail::Parser");

if (!$res) {
    $tap->run();
    is($tap->{'errors'},0,"No errors encountered uploading case results");
}

#Test spawning of builds not in plans.
#Now, test spawning.
undef $tap;
delete $opts->{'testsuite_id'};
delete $opts->{'plan'};
delete $opts->{'configs'};
$opts->{'testsuite'} = 'HAMBURGER-IZE HUMANITY';
$res = exception { $tap = Test::Rail::Parser->new($opts) };
is($res,undef,"TR Parser doesn't explode on instantiation when spawning run in plan");
isa_ok($tap,"Test::Rail::Parser");

if (!$res) {
    $tap->run();
    is($tap->{'errors'},0,"No errors encountered uploading case results");
}

#Test spawning of plans and runs.
undef $tap;
$opts->{'run'} = 'BogoRun';
$opts->{'plan'} = 'BogoPlan';
$opts->{'testsuite_id'} = 9;
delete $opts->{'testsuite'};
$res = exception { $tap = Test::Rail::Parser->new($opts) };
is($res,undef,"TR Parser doesn't explode on instantiation when spawning run in plan");
isa_ok($tap,"Test::Rail::Parser");

if (!$res) {
    $tap->run();
    is($tap->{'errors'},0,"No errors encountered uploading case results");
}

#Verify that case_per_ok and step_results are mutually exclusive, and die.
undef $tap;
$opts->{'case_per_ok'} = 1;
$opts->{'step_results'} = 'sr_step_results';
$res = exception { $tap = Test::Rail::Parser->new($opts) };
isnt($res,undef,"TR Parser explodes on instantiation when mutually exclusive options are passed");

#Check that per-section spawn works
undef $tap;
$opts->{'source'} = 't/fake.test';
delete $opts->{'plan'};
$opts->{'sections'} = ['fake.test'];
delete $opts->{'step_results'};
$res = exception { $tap = Test::Rail::Parser->new($opts) };
is($res,undef,"TR Parser doesn't explode on instantiation");
isa_ok($tap,"Test::Rail::Parser");

if (!$res) {
    $tap->run();
    is($tap->{'errors'},0,"No errors encountered uploading case results");
}

#Check that per-section spawn works
undef $tap;
$opts->{'plan'} = 'BogoPlan';
$res = exception { $tap = Test::Rail::Parser->new($opts) };
is($res,undef,"TR Parser doesn't explode on instantiation");
isa_ok($tap,"Test::Rail::Parser");

if (!$res) {
    $tap->run();
    is($tap->{'errors'},0,"No errors encountered uploading case results");
}

undef $tap;
$opts->{'sections'} = ['potzrebie'];
delete $opts->{'plan'};
$res = exception { $tap = Test::Rail::Parser->new($opts) };
isnt($res,undef,"TR Parser explodes on instantiation with invalid section");

undef $tap;
$opts->{'source'} = 't/notests.test';
delete $opts->{'sections'};
delete $opts->{'case_per_ok'};
$res = exception { $tap = Test::Rail::Parser->new($opts) };
is($res,undef,"TR Parser doesn't explode on instantiation");
isa_ok($tap,"Test::Rail::Parser");

if (!$res) {
    $tap->run();
    is($tap->{'errors'},0,"No errors encountered uploading case results");
    is($tap->{'global_status'},4, "Test global result is RETEST on env fail");
}

undef $tap;
$opts->{'source'} = 't/pass.test';
$res = exception { $tap = Test::Rail::Parser->new($opts) };
is($res,undef,"TR Parser doesn't explode on instantiation");
isa_ok($tap,"Test::Rail::Parser");

if (!$res) {
    $tap->run();
    is($tap->{'errors'},0,"No errors encountered uploading case results");
    is($tap->{'global_status'},1, "Test global result is PASS on ok test");
}

undef $tap;
$opts->{'source'} = 't/todo_pass.test';
$res = exception { $tap = Test::Rail::Parser->new($opts) };
is($res,undef,"TR Parser doesn't explode on instantiation");
isa_ok($tap,"Test::Rail::Parser");

if (!$res) {
    $tap->run();
    is($tap->{'errors'},0,"No errors encountered uploading case results");
    is($tap->{'global_status'},8, "Test global result is TODO PASS on todo pass test");
}

undef $tap;
#Check bad plan w/ todo pass logic
$fcontents = "
todo_pass.test ..
1..2
ok 1 - STORAGE TANKS SEARED #TODO todo pass
# goo
";
undef $opts->{'source'};
$opts->{'tap'} = $fcontents;
$opts->{'step_results'} = 'step_results';
$res = exception { $tap = Test::Rail::Parser->new($opts) };
is($res,undef,"TR Parser doesn't explode on instantiation");
isa_ok($tap,"Test::Rail::Parser");

if (!$res) {
    $tap->run();
    is($tap->{'errors'},0,"No errors encountered uploading case results");
    is($tap->{'global_status'},5, "Test global result is FAIL on todo pass test w/ bad plan");
    my $srs = $tap->{'tr_opts'}->{'result_custom_options'}->{'step_results'};
    is($srs->[-1]->{'content'},"Bad Plan.","Bad plan noted in step results");
}
undef $opts->{'step_results'};

#Check instant pizza
$fcontents = "
todo_pass.test ..
1..2
";
undef $opts->{'source'};
$opts->{'tap'} = $fcontents;
$opts->{'step_results'} = 'step_results';
$res = exception { $tap = Test::Rail::Parser->new($opts) };
is($res,undef,"TR Parser doesn't explode on instantiation");
isa_ok($tap,"Test::Rail::Parser");

if (!$res) {
    $tap->run();
    is($tap->{'errors'},0,"No errors encountered uploading case results");
    is($tap->{'global_status'},4, "Test global result is FAIL on todo pass test w/ bad plan");
    my $srs = $tap->{'tr_opts'}->{'result_custom_options'}->{'step_results'};
    is($srs->[-1]->{'content'},"Bad Plan.","Bad plan noted in step results");
}
undef $opts->{'step_results'};


undef $tap;
#Check bad plan w/ todo pass logic
$fcontents = "
todo_pass.test ..
1..2
ok 1 - STORAGE TANKS SEARED #TODO todo pass
# goo
% mark_status=todo_fail #Appears tanks weren't so sealed after all
";
undef $opts->{'source'};
$opts->{'tap'} = $fcontents;
$res = exception { $tap = Test::Rail::Parser->new($opts) };
is($res,undef,"TR Parser doesn't explode on instantiation");
isa_ok($tap,"Test::Rail::Parser");

if (!$res) {
    $tap->run();
    is($tap->{'errors'},0,"No errors encountered uploading case results");
    is($tap->{'global_status'},7, "Test global result is FAIL on todo pass test w/ bad plan");
}
undef $opts->{'tap'};

#Check autoclose functionality against Run with all tests in run status.
undef $tap;
$opts->{'source'} = 't/skip.test';
$opts->{'run'} = 'FinalRun';
$opts->{'autoclose'} = 1;
$res = exception { $tap = Test::Rail::Parser->new($opts) };
is($res,undef,"TR Parser doesn't explode on instantiation");
isa_ok($tap,"Test::Rail::Parser");

if (!$res) {
    $tap->run();
    is($tap->{'errors'},0,"No errors encountered uploading case results");
    is($tap->{'run_closed'},1, "Run closed by parser when all tests done");
}

#Check autoclose functionality against Run with not all tests in run status.
undef $tap;
$opts->{'source'} = 't/todo_pass.test';
$opts->{'run'} = 'BogoRun';
$res = exception { $tap = Test::Rail::Parser->new($opts) };
is($res,undef,"TR Parser doesn't explode on instantiation");
isa_ok($tap,"Test::Rail::Parser");

if (!$res) {
    $tap->run();
    is($tap->{'errors'},0,"No errors encountered uploading case results");
    is($tap->{'run_closed'},undef, "Run not closed by parser when results are outstanding");
}

#Check that autoclose works against plan wiht all tests in run status
undef $tap;
$opts->{'source'} = 't/fake.test';
$opts->{'run'} = 'FinalRun';
$opts->{'plan'} = 'FinalPlan';
$opts->{'configs'} = ['testConfig'];
$opts->{'case_per_ok'} = 1;
$res = exception { $tap = Test::Rail::Parser->new($opts) };
is($res,undef,"TR Parser doesn't explode on instantiation");
isa_ok($tap,"Test::Rail::Parser");

if (!$res) {
    $tap->run();
    is($tap->{'errors'},0,"No errors encountered uploading case results");
    is($tap->{'plan_closed'},1, "Plan closed by parser when all tests done");
}

#Check that autoclose works against plan with all tests not in run status
undef $tap;
$opts->{'run'} = 'BogoRun';
$opts->{'plan'} = 'BogoPlan';
$res = exception { $tap = Test::Rail::Parser->new($opts) };
is($res,undef,"TR Parser doesn't explode on instantiation");
isa_ok($tap,"Test::Rail::Parser");

if (!$res) {
    $tap->run();
    is($tap->{'errors'},0,"No errors encountered uploading case results");
    is($tap->{'plan_closed'},undef, "Plan not closed by parser when results are outstanding");
}

#Plan but no run 'splodes
undef $tap;
$opts->{'plan'} = 'CompletePlan';
delete $opts->{'run'};
delete $opts->{'configs'};
$res = exception { $tap = Test::Rail::Parser->new($opts) };
like($res,qr/but no run passed/i,"TR Parser explodes on instantiation due to passing plan with no run");

#Check that trying without spawn opts, using completed plan fails
undef $tap;
$opts->{'plan'} = 'ClosedPlan';
$opts->{'run'} = 'BogoRun';
delete $opts->{'testsuite_id'};
$res = exception { $tap = Test::Rail::Parser->new($opts) };
like($res,qr/plan provided is completed/i,"TR Parser explodes on instantiation due to passing closed plan");

#Check that the above two will just spawn a new plan in these cases
$opts->{'testsuite_id'} = 9;
$res = exception { $tap = Test::Rail::Parser->new($opts) };
is($res,undef,"TR Parser runs all the way through on completed run when spawning");

#Check that trying without spawn opts, using completed run fails
undef $tap;
delete $opts->{'testsuite_id'};
delete $opts->{'plan'};
$opts->{'run'} = 'ClosedRun';
$res = exception { $tap = Test::Rail::Parser->new($opts) };
like($res,qr/run provided is completed/i,"TR Parser explodes on instantiation due to passing closed run");

#Check that the above two will just spawn a new run in these cases
$opts->{'testsuite_id'} = 9;
$res = exception { $tap = Test::Rail::Parser->new($opts) };
is($res,undef,"TR Parser runs all the way through on completed run when spawning");
