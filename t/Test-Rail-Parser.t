#!/usr/bin/env perl

use strict;
use warnings;

use Scalar::Util qw{reftype};
use TestRail::API;
use Test::LWP::UserAgent::TestRailMock;
use Test::Rail::Parser;
use Test::More 'tests' => 36;
use Test::Fatal qw{exception};

#Same song and dance as in TestRail-API.t
my $apiurl  = $ENV{'TESTRAIL_API_URL'};
my $login   = $ENV{'TESTRAIL_USER'};
my $pw      = $ENV{'TESTRAIL_PASSWORD'};
my $is_mock = ( !$apiurl && !$login && !$pw );

( $apiurl, $login, $pw ) =
  ( 'http://testrail.local', 'teodesian@cpan.org', 'fake' )
  if $is_mock;
my ( $debug, $browser );

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
    $tap = Test::Rail::Parser->new(
        {
            'tap'         => $fcontents,
            'apiurl'      => $apiurl,
            'user'        => $login,
            'pass'        => $pw,
            'debug'       => $debug,
            'browser'     => $browser,
            'run'         => 'TestingSuite',
            'project'     => 'TestProject',
            'merge'       => 1,
            'case_per_ok' => 1
        }
    );
};
is( $res, undef, "TR Parser doesn't explode on instantiation" );
isa_ok( $tap, "Test::Rail::Parser" );

if ( !$res ) {
    $tap->run();
    is( $tap->{'errors'}, 0, "No errors encountered uploading case results" );
}

undef $tap;
$res = exception {
    $tap = Test::Rail::Parser->new(
        {
            'source'      => 't/fake.test',
            'apiurl'      => $apiurl,
            'user'        => $login,
            'pass'        => $pw,
            'debug'       => $debug,
            'browser'     => $browser,
            'run'         => 'TestingSuite',
            'project'     => 'TestProject',
            'merge'       => 1,
            'case_per_ok' => 1
        }
    );
};
is( $res, undef, "TR Parser doesn't explode on instantiation" );
isa_ok( $tap, "Test::Rail::Parser" );

if ( !$res ) {
    $tap->run();
    is( $tap->{'errors'}, 0, "No errors encountered uploading case results" );
}

#Check that time run is being uploaded
my $timeResults = $tap->{'tr_opts'}->{'testrail'}->getTestResults(1);
if ( ( reftype($timeResults) || 'undef' ) eq 'ARRAY' ) {
    is( $timeResults->[0]->{'elapsed'},
        '2s', "Plugin correctly sets elapsed time" );
}
else {
    fail("Could not get test results to check elapsed time!");
}

#Check the time formatting routine.
is( Test::Rail::Parser::_compute_elapsed( 0, 0 ),
    undef, "Elapsed computation correct at second boundary" );
is( Test::Rail::Parser::_compute_elapsed( 0, 61 ),
    '1m 1s', "Elapsed computation correct at minute boundary" );
is( Test::Rail::Parser::_compute_elapsed( 0, 3661 ),
    '1h 1m 1s', "Elapsed computation correct at hour boundary" );
is( Test::Rail::Parser::_compute_elapsed( 0, 86461 ),
    '24h 1m 1s', "Elapsed computation correct at day boundary" );

#Time for non case_per_ok mode
undef $tap;
$res = exception {
    $tap = Test::Rail::Parser->new(
        {
            'source'       => 't/faker.test',
            'apiurl'       => $apiurl,
            'user'         => $login,
            'pass'         => $pw,
            'debug'        => $debug,
            'browser'      => $browser,
            'run'          => 'OtherOtherSuite',
            'project'      => 'TestProject',
            'merge'        => 1,
            'step_results' => 'step_results'
        }
    );
};
is( $res, undef, "TR Parser doesn't explode on instantiation" );
isa_ok( $tap, "Test::Rail::Parser" );

if ( !$res ) {
    $tap->run();
    is( $tap->{'errors'}, 0, "No errors encountered uploading case results" );
}

#Default mode
undef $tap;
$res = exception {
    $tap = Test::Rail::Parser->new(
        {
            'source'  => 't/faker.test',
            'apiurl'  => $apiurl,
            'user'    => $login,
            'pass'    => $pw,
            'debug'   => $debug,
            'browser' => $browser,
            'run'     => 'OtherOtherSuite',
            'project' => 'TestProject',
            'merge'   => 1
        }
    );
};
is( $res, undef, "TR Parser doesn't explode on instantiation" );
isa_ok( $tap, "Test::Rail::Parser" );

if ( !$res ) {
    $tap->run();
    is( $tap->{'errors'}, 0, "No errors encountered uploading case results" );
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
    $tap = Test::Rail::Parser->new(
        {
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
        }
    );
};
is( $res, undef, "TR Parser doesn't explode on instantiation" );
isa_ok( $tap, "Test::Rail::Parser" );

if ( !$res ) {
    $tap->run();
    is( $tap->{'errors'}, 0, "No errors encountered uploading case results" );
}

#skip/todo in case_per_ok
undef $tap;
$res = exception {
    $tap = Test::Rail::Parser->new(
        {
            'source'      => 't/skip.test',
            'apiurl'      => $apiurl,
            'user'        => $login,
            'pass'        => $pw,
            'debug'       => $debug,
            'browser'     => $browser,
            'run'         => 'TestingSuite',
            'project'     => 'TestProject',
            'case_per_ok' => 1,
            'merge'       => 1
        }
    );
};
is( $res, undef, "TR Parser doesn't explode on instantiation" );
isa_ok( $tap, "Test::Rail::Parser" );

if ( !$res ) {
    $tap->run();
    is( $tap->{'errors'}, 0, "No errors encountered uploading case results" );
}

#Default mode skip (skip_all)
undef $tap;
$res = exception {
    $tap = Test::Rail::Parser->new(
        {
            'source'  => 't/skipall.test',
            'apiurl'  => $apiurl,
            'user'    => $login,
            'pass'    => $pw,
            'debug'   => $debug,
            'browser' => $browser,
            'run'     => 'TestingSuite',
            'project' => 'TestProject',
            'merge'   => 1
        }
    );
};
is( $res, undef, "TR Parser doesn't explode on instantiation" );
isa_ok( $tap, "Test::Rail::Parser" );

if ( !$res ) {
    $tap->run();
    is( $tap->{'errors'}, 0, "No errors encountered uploading case results" );
}

#Ok, let's test the plan, config, and spawn bits.
undef $tap;
$res = exception {
    $tap = Test::Rail::Parser->new(
        {
            'source'  => 't/skipall.test',
            'apiurl'  => $apiurl,
            'user'    => $login,
            'pass'    => $pw,
            'debug'   => $debug,
            'browser' => $browser,
            'run'     => 'hoo hoo I do not exist',
            'plan'    => 'mah dubz plan',
            'configs' => ['testPlatform1'],
            'project' => 'TestProject',
            'merge'   => 1
        }
    );
};
isnt( $res, undef,
    "TR Parser explodes on instantiation when asking for run not in plan" );

undef $tap;
$res = exception {
    $tap = Test::Rail::Parser->new(
        {
            'source'  => 't/skipall.test',
            'apiurl'  => $apiurl,
            'user'    => $login,
            'pass'    => $pw,
            'debug'   => $debug,
            'browser' => $browser,
            'run'     => 'TestingSuite',
            'plan'    => 'mah dubz plan',
            'configs' => ['testPlatform1'],
            'project' => 'TestProject',
            'merge'   => 1
        }
    );
};
is( $res, undef,
    "TR Parser doesn't explode on instantiation looking for existing run in plan"
);
isa_ok( $tap, "Test::Rail::Parser" );

if ( !$res ) {
    $tap->run();
    is( $tap->{'errors'}, 0, "No errors encountered uploading case results" );
}

#Now, test spawning.
undef $tap;
$res = exception {
    $tap = Test::Rail::Parser->new(
        {
            'source'  => 't/skipall.test',
            'apiurl'  => $apiurl,
            'user'    => $login,
            'pass'    => $pw,
            'debug'   => $debug,
            'browser' => $browser,
            'run'     => 'TestingSuite2',
            'plan'    => 'mah dubz plan',
            'configs' => ['testPlatform1'],
            'project' => 'TestProject',
            'spawn'   => 9,
            'merge'   => 1
        }
    );
};
is( $res, undef,
    "TR Parser doesn't explode on instantiation when spawning run in plan" );
isa_ok( $tap, "Test::Rail::Parser" );

if ( !$res ) {
    $tap->run();
    is( $tap->{'errors'}, 0, "No errors encountered uploading case results" );
}

#Test spawning of builds not in plans.
#Now, test spawning.
undef $tap;
$res = exception {
    $tap = Test::Rail::Parser->new(
        {
            'source'  => 't/skipall.test',
            'apiurl'  => $apiurl,
            'user'    => $login,
            'pass'    => $pw,
            'debug'   => $debug,
            'browser' => $browser,
            'run'     => 'TestingSuite2',
            'project' => 'TestProject',
            'spawn'   => 9,
            'merge'   => 1
        }
    );
};
is( $res, undef,
    "TR Parser doesn't explode on instantiation when spawning run in plan" );
isa_ok( $tap, "Test::Rail::Parser" );

if ( !$res ) {
    $tap->run();
    is( $tap->{'errors'}, 0, "No errors encountered uploading case results" );
}

0;
