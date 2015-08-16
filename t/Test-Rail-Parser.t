#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use Scalar::Util qw{reftype};
use TestRail::API;
use Test::LWP::UserAgent::TestRailMock;
use Test::Rail::Parser;
use Test::More 'tests' => 78;
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
my $res = exception {
    $tap = Test::Rail::Parser->new({
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
    });
};
is($res,undef,"TR Parser doesn't explode on instantiation");
isa_ok($tap,"Test::Rail::Parser");

if (!$res) {
    $tap->run();
    is($tap->{'errors'},0,"No errors encountered uploading case results");
}

undef $tap;
$res = exception {
    $tap = Test::Rail::Parser->new({
        'source'              => 't/fake.test',
        'apiurl'              => $apiurl,
        'user'                => $login,
        'pass'                => $pw,
        'debug'               => $debug,
        'browser'             => $browser,
        'run'                 => 'TestingSuite',
        'project'             => 'TestProject',
        'merge'               => 1,
        'case_per_ok'         => 1
    });
};
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
is($tap->{'raw_output'},$fcontents,"Full raw content uploaded in non step results mode");

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
$res = exception {
    $tap = Test::Rail::Parser->new({
        'source'              => 't/faker.test',
        'apiurl'              => $apiurl,
        'user'                => $login,
        'pass'                => $pw,
        'debug'               => $debug,
        'browser'             => $browser,
        'run'                 => 'OtherOtherSuite',
        'project'             => 'TestProject',
        'merge'               => 1,
        'step_results'        => 'step_results'
    });
};
is($res,undef,"TR Parser doesn't explode on instantiation");
isa_ok($tap,"Test::Rail::Parser");

if (!$res) {
    $tap->run();
    is($tap->{'errors'},0,"No errors encountered uploading case results");
    is($tap->{'global_status'},5, "Test global result is FAIL when one subtest fails even if there are TODO passes");
}

#Default mode
undef $tap;
$res = exception {
    $tap = Test::Rail::Parser->new({
        'source'              => 't/faker.test',
        'apiurl'              => $apiurl,
        'user'                => $login,
        'pass'                => $pw,
        'debug'               => $debug,
        'browser'             => $browser,
        'run'                 => 'OtherOtherSuite',
        'project'             => 'TestProject',
        'merge'               => 1
    });
};
is($res,undef,"TR Parser doesn't explode on instantiation");
isa_ok($tap,"Test::Rail::Parser");

if (!$res) {
    $tap->run();
    is($tap->{'errors'},0,"No errors encountered uploading case results");
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

$res = exception {
    $tap = Test::Rail::Parser->new({
        'tap'         => $fcontents,
        'apiurl'      => $apiurl,
        'user'        => $login,
        'pass'        => $pw,
        'debug'       => $debug,
        'browser'     => $browser,
        'run'         => 'TestingSuite',
        'project'     => 'TestProject',
        'case_per_ok' => 1,
        'merge'       => 1
    });
};
is($res,undef,"TR Parser doesn't explode on instantiation");
isa_ok($tap,"Test::Rail::Parser");

if (!$res) {
    $tap->run();
    is($tap->{'errors'},0,"No errors encountered uploading case results");
}

#skip/todo in case_per_ok
undef $tap;
$res = exception {
    $tap = Test::Rail::Parser->new({
        'source'              => 't/skip.test',
        'apiurl'              => $apiurl,
        'user'                => $login,
        'pass'                => $pw,
        'debug'               => $debug,
        'browser'             => $browser,
        'run'                 => 'TestingSuite',
        'project'             => 'TestProject',
        'case_per_ok'         => 1,
        'merge'               => 1
    });
};
is($res,undef,"TR Parser doesn't explode on instantiation");
isa_ok($tap,"Test::Rail::Parser");

if (!$res) {
    $tap->run();
    is($tap->{'errors'},0,"No errors encountered uploading case results");
}

#Default mode skip (skip_all)
undef $tap;
$res = exception {
    $tap = Test::Rail::Parser->new({
        'source'              => 't/skipall.test',
        'apiurl'              => $apiurl,
        'user'                => $login,
        'pass'                => $pw,
        'debug'               => $debug,
        'browser'             => $browser,
        'run'                 => 'TestingSuite',
        'project'             => 'TestProject',
        'merge'               => 1
    });
};
is($res,undef,"TR Parser doesn't explode on instantiation");
isa_ok($tap,"Test::Rail::Parser");

if (!$res) {
    $tap->run();
    is($tap->{'errors'},0,"No errors encountered uploading case results");
    is($tap->{'global_status'},6, "Test global result is SKIP on skip all");
}

#Ok, let's test the plan, config, and spawn bits.
undef $tap;
$res = exception {
    $tap = Test::Rail::Parser->new({
        'source'              => 't/skipall.test',
        'apiurl'              => $apiurl,
        'user'                => $login,
        'pass'                => $pw,
        'debug'               => $debug,
        'browser'             => $browser,
        'run'                 => 'hoo hoo I do not exist',
        'plan'                => 'mah dubz plan',
        'configs'             => ['testPlatform1'],
        'project'             => 'TestProject',
        'merge'               => 1
    });
};
isnt($res,undef,"TR Parser explodes on instantiation when asking for run not in plan");

undef $tap;
$res = exception {
    $tap = Test::Rail::Parser->new({
        'source'              => 't/skipall.test',
        'apiurl'              => $apiurl,
        'user'                => $login,
        'pass'                => $pw,
        'debug'               => $debug,
        'browser'             => $browser,
        'run'                 => 'TestingSuite',
        'plan'                => 'mah dubz plan',
        'configs'             => ['testConfig'],
        'project'             => 'TestProject',
        'merge'               => 1
    });
};
is($res,undef,"TR Parser doesn't explode on instantiation looking for existing run in plan");
isa_ok($tap,"Test::Rail::Parser");

if (!$res) {
    $tap->run();
    is($tap->{'errors'},0,"No errors encountered uploading case results");
}

#Now, test spawning.
undef $tap;
$res = exception {
    $tap = Test::Rail::Parser->new({
        'source'              => 't/skipall.test',
        'apiurl'              => $apiurl,
        'user'                => $login,
        'pass'                => $pw,
        'debug'               => $debug,
        'browser'             => $browser,
        'run'                 => 'TestingSuite2',
        'plan'                => 'mah dubz plan',
        'configs'             => ['testPlatform1'],
        'project'             => 'TestProject',
        'testsuite_id'        => 9,
        'merge'               => 1
    });
};
is($res,undef,"TR Parser doesn't explode on instantiation when spawning run in plan");
isa_ok($tap,"Test::Rail::Parser");

if (!$res) {
    $tap->run();
    is($tap->{'errors'},0,"No errors encountered uploading case results");
}

#Test spawning of builds not in plans.
#Now, test spawning.
undef $tap;
$res = exception {
    $tap = Test::Rail::Parser->new({
        'source'              => 't/skipall.test',
        'apiurl'              => $apiurl,
        'user'                => $login,
        'pass'                => $pw,
        'debug'               => $debug,
        'browser'             => $browser,
        'run'                 => 'TestingSuite2',
        'project'             => 'TestProject',
        'testsuite'           => 'HAMBURGER-IZE HUMANITY',
        'merge'               => 1
    });
};
is($res,undef,"TR Parser doesn't explode on instantiation when spawning run in plan");
isa_ok($tap,"Test::Rail::Parser");

if (!$res) {
    $tap->run();
    is($tap->{'errors'},0,"No errors encountered uploading case results");
}

#Test spawning of plans and runs.
undef $tap;
$res = exception {
    $tap = Test::Rail::Parser->new({
        'source'              => 't/skipall.test',
        'apiurl'              => $apiurl,
        'user'                => $login,
        'pass'                => $pw,
        'debug'               => $debug,
        'browser'             => $browser,
        'run'                 => 'BogoRun',
        'plan'                => 'BogoPlan',
        'project'             => 'TestProject',
        'testsuite_id'        => 9,
        'merge'               => 1
    });
};
is($res,undef,"TR Parser doesn't explode on instantiation when spawning run in plan");
isa_ok($tap,"Test::Rail::Parser");

if (!$res) {
    $tap->run();
    is($tap->{'errors'},0,"No errors encountered uploading case results");
}

#Verify that case_per_ok and step_results are mutually exclusive, and die.
undef $tap;
$res = exception {
    $tap = Test::Rail::Parser->new({
        'source'              => 't/skipall.test',
        'apiurl'              => $apiurl,
        'user'                => $login,
        'pass'                => $pw,
        'debug'               => $debug,
        'browser'             => $browser,
        'run'                 => 'BogoRun',
        'plan'                => 'BogoPlan',
        'project'             => 'TestProject',
        'testsuite_id'        => 9,
        'merge'               => 1,
        'case_per_ok'         => 1,
        'step_results'        => 'sr_step_results'
    });
};
isnt($res,undef,"TR Parser explodes on instantiation when mutually exclusive options are passed");

#Check that per-section spawn works
undef $tap;
$res = exception {
    $tap = Test::Rail::Parser->new({
        'source'              => 't/fake.test',
        'apiurl'              => $apiurl,
        'user'                => $login,
        'pass'                => $pw,
        'debug'               => $debug,
        'browser'             => $browser,
        'run'                 => 'BogoRun',
        'project'             => 'TestProject',
        'merge'               => 1,
        'testsuite_id'        => 9,
        'sections'            => ['fake.test'],
        'case_per_ok'         => 1
    });
};
is($res,undef,"TR Parser doesn't explode on instantiation");
isa_ok($tap,"Test::Rail::Parser");

if (!$res) {
    $tap->run();
    is($tap->{'errors'},0,"No errors encountered uploading case results");
}

#Check that per-section spawn works
undef $tap;
$res = exception {
    $tap = Test::Rail::Parser->new({
        'source'              => 't/fake.test',
        'apiurl'              => $apiurl,
        'user'                => $login,
        'pass'                => $pw,
        'debug'               => $debug,
        'browser'             => $browser,
        'run'                 => 'BogoRun',
        'plan'                => 'BogoPlan',
        'project'             => 'TestProject',
        'merge'               => 1,
        'testsuite_id'        => 9,
        'sections'            => ['fake.test'],
        'case_per_ok'         => 1
    });
};
is($res,undef,"TR Parser doesn't explode on instantiation");
isa_ok($tap,"Test::Rail::Parser");

if (!$res) {
    $tap->run();
    is($tap->{'errors'},0,"No errors encountered uploading case results");
}

undef $tap;
$res = exception {
    $tap = Test::Rail::Parser->new({
        'source'              => 't/fake.test',
        'apiurl'              => $apiurl,
        'user'                => $login,
        'pass'                => $pw,
        'debug'               => $debug,
        'browser'             => $browser,
        'run'                 => 'BogoRun',
        'project'             => 'TestProject',
        'merge'               => 1,
        'testsuite_id'        => 9,
        'sections'            => ['potzrebie'],
        'case_per_ok'         => 1
    });
};
isnt($res,undef,"TR Parser explodes on instantiation with invalid section");

undef $tap;
$res = exception {
    $tap = Test::Rail::Parser->new({
        'source'              => 't/notests.test',
        'apiurl'              => $apiurl,
        'user'                => $login,
        'pass'                => $pw,
        'debug'               => $debug,
        'browser'             => $browser,
        'run'                 => 'BogoRun',
        'project'             => 'TestProject',
        'merge'               => 1,
        'testsuite_id'        => 9,
    });
};
is($res,undef,"TR Parser doesn't explode on instantiation");
isa_ok($tap,"Test::Rail::Parser");

if (!$res) {
    $tap->run();
    is($tap->{'errors'},0,"No errors encountered uploading case results");
    is($tap->{'global_status'},4, "Test global result is RETEST on env fail");
}

undef $tap;
$res = exception {
    $tap = Test::Rail::Parser->new({
        'source'              => 't/pass.test',
        'apiurl'              => $apiurl,
        'user'                => $login,
        'pass'                => $pw,
        'debug'               => $debug,
        'browser'             => $browser,
        'run'                 => 'BogoRun',
        'project'             => 'TestProject',
        'merge'               => 1,
        'testsuite_id'        => 9,
    });
};
is($res,undef,"TR Parser doesn't explode on instantiation");
isa_ok($tap,"Test::Rail::Parser");

if (!$res) {
    $tap->run();
    is($tap->{'errors'},0,"No errors encountered uploading case results");
    is($tap->{'global_status'},1, "Test global result is PASS on ok test");
}

undef $tap;
$res = exception {
    $tap = Test::Rail::Parser->new({
        'source'              => 't/todo_pass.test',
        'apiurl'              => $apiurl,
        'user'                => $login,
        'pass'                => $pw,
        'debug'               => $debug,
        'browser'             => $browser,
        'run'                 => 'BogoRun',
        'project'             => 'TestProject',
        'merge'               => 1,
        'testsuite_id'        => 9,
    });
};
is($res,undef,"TR Parser doesn't explode on instantiation");
isa_ok($tap,"Test::Rail::Parser");

if (!$res) {
    $tap->run();
    is($tap->{'errors'},0,"No errors encountered uploading case results");
    is($tap->{'global_status'},8, "Test global result is TODO PASS on todo pass test");
}

#Check autoclose functionality against Run with all tests in run status.
undef $tap;
$res = exception {
    $tap = Test::Rail::Parser->new({
        'source'              => 't/skip.test',
        'apiurl'              => $apiurl,
        'user'                => $login,
        'pass'                => $pw,
        'debug'               => $debug,
        'browser'             => $browser,
        'run'                 => 'FinalRun',
        'project'             => 'TestProject',
        'merge'               => 1,
        'autoclose'           => 1,
        'testsuite_id'        => 9,
    });
};
is($res,undef,"TR Parser doesn't explode on instantiation");
isa_ok($tap,"Test::Rail::Parser");

if (!$res) {
    $tap->run();
    is($tap->{'errors'},0,"No errors encountered uploading case results");
    is($tap->{'run_closed'},1, "Run closed by parser when all tests done");
}

#Check autoclose functionality against Run with not all tests in run status.
undef $tap;
$res = exception {
    $tap = Test::Rail::Parser->new({
        'source'              => 't/todo_pass.test',
        'apiurl'              => $apiurl,
        'user'                => $login,
        'pass'                => $pw,
        'debug'               => $debug,
        'browser'             => $browser,
        'run'                 => 'BogoRun',
        'project'             => 'TestProject',
        'merge'               => 1,
        'autoclose'           => 1,
        'testsuite_id'        => 9,
    });
};
is($res,undef,"TR Parser doesn't explode on instantiation");
isa_ok($tap,"Test::Rail::Parser");

if (!$res) {
    $tap->run();
    is($tap->{'errors'},0,"No errors encountered uploading case results");
    is($tap->{'run_closed'},undef, "Run not closed by parser when results are outstanding");
}

#Check that autoclose works against plan wiht all tests in run status
undef $tap;
$res = exception {
    $tap = Test::Rail::Parser->new({
        'source'              => 't/fake.test',
        'apiurl'              => $apiurl,
        'user'                => $login,
        'pass'                => $pw,
        'debug'               => $debug,
        'browser'             => $browser,
        'run'                 => 'FinalRun',
        'plan'                => 'FinalPlan',
        'project'             => 'TestProject',
        'configs'             => ['testConfig'],
        'merge'               => 1,
        'autoclose'           => 1,
        'case_per_ok'         => 1
    });
};
is($res,undef,"TR Parser doesn't explode on instantiation");
isa_ok($tap,"Test::Rail::Parser");

if (!$res) {
    $tap->run();
    is($tap->{'errors'},0,"No errors encountered uploading case results");
    is($tap->{'plan_closed'},1, "Plan closed by parser when all tests done");
}

#Check that autoclose works against plan wiht all tests not in run status
undef $tap;
$res = exception {
    $tap = Test::Rail::Parser->new({
        'source'              => 't/fake.test',
        'apiurl'              => $apiurl,
        'user'                => $login,
        'pass'                => $pw,
        'debug'               => $debug,
        'browser'             => $browser,
        'run'                 => 'BogoRun',
        'plan'                => 'BogoPlan',
        'project'             => 'TestProject',
        'testsuite_id'        => 9,
        'merge'               => 1,
        'autoclose'           => 1,
        'case_per_ok'         => 1
    });
};
is($res,undef,"TR Parser doesn't explode on instantiation");
isa_ok($tap,"Test::Rail::Parser");

if (!$res) {
    $tap->run();
    is($tap->{'errors'},0,"No errors encountered uploading case results");
    is($tap->{'plan_closed'},undef, "Plan not closed by parser when results are outstanding");
}

