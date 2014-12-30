#!/usr/bin/env perl

use strict;
use warnings;

use TestRail::API;
use Test::LWP::UserAgent::TestRailMock;
use Test::Rail::Parser;
use Test::More 'tests' => 12;
use Test::Fatal qw{exception};

#Same song and dance as in TestRail-API.t
my $apiurl = $ENV{'TESTRAIL_API_URL'};
my $login  = $ENV{'TESTRAIL_USER'};
my $pw     = $ENV{'TESTRAIL_PASSWORD'};
my $is_mock = (!$apiurl && !$login && !$pw);

($apiurl,$login,$pw) = ('http://testrail.local','teodesian@cpan.org','fake') if $is_mock;
my ($debug,$browser);

if ($is_mock) {
    $debug = 1;
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
        'source'              => 'fake.test',
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

#Time for non case_per_ok mode
undef $tap;
$res = exception {
    $tap = Test::Rail::Parser->new({
        'source'              => 'faker.test',
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
}

#Default mode
undef $tap;
$res = exception {
    $tap = Test::Rail::Parser->new({
        'source'              => 'faker.test',
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

0;
