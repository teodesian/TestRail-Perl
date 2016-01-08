use strict;
use warnings;
use FindBin;

use lib $FindBin::Bin.'/../bin';
require 'testrail-report';

use Test::More 'tests' => 16;
use Capture::Tiny qw{capture_merged};

use lib $FindBin::Bin.'/lib';
use Test::LWP::UserAgent::TestRailMock;

my @args = (qw{--apiurl http://testrail.local --user test@fake.fake --password fake --project}, "CRUSH ALL HUMANS", '--run', "SEND T-1000 INFILTRATION UNITS BACK IN TIME", qw{ t/test_multiple_files.tap});
my ($out,(undef,$code)) = capture_merged {TestRail::Bin::Report::run('browser' => $Test::LWP::UserAgent::TestRailMock::mockObject, 'args' => \@args)};
is($code, 0, "Exit code OK reported with multiple files");
my $matches = () = $out =~ m/Reporting result of case/ig;
is($matches,2,"Attempts to upload multiple times");

@args = (qw{--apiurl http://testrail.local --user test@fake.fake --password fake --project}, "CRUSH ALL HUMANS", '--run', "SEND T-1000 INFILTRATION UNITS BACK IN TIME", qw{--case-ok  t/test_multiple_files.tap});
($out,(undef,$code)) = capture_merged {TestRail::Bin::Report::run('browser' => $Test::LWP::UserAgent::TestRailMock::mockObject, 'args' => \@args)};
is($code, 0, "Exit code OK reported with multiple files (case-ok mode)");
$matches = () = $out =~ m/Reporting result of case/ig;
is($matches,4,"Attempts to upload multiple times (case-ok mode)");

#Test version, case-ok
@args = (qw{--apiurl http://testrail.local --user test@fake.fake --password fake --project TestProject --run TestingSuite --case-ok --version 1.0.14  t/test_subtest.tap});
($out,(undef,$code)) = capture_merged {TestRail::Bin::Report::run('browser' => $Test::LWP::UserAgent::TestRailMock::mockObject, 'args' => \@args)};
is($code, 0, "Exit code OK reported with subtests (case-ok mode)");
$matches = () = $out =~ m/Reporting result of case/ig;
is($matches,2,"Attempts to upload do not do subtests (case-ok mode)");

#Test plans/configs
@args = (qw{--apiurl http://testrail.local --user test@fake.fake --password fake --project TestProject --run}, "Executing the great plan", qw{--plan GosPlan --config testConfig --case-ok  t/test_subtest.tap});
($out,(undef,$code)) = capture_merged {TestRail::Bin::Report::run('browser' => $Test::LWP::UserAgent::TestRailMock::mockObject, 'args' => \@args)};
is($code, 0, "Exit code OK reported with plans");
$matches = () = $out =~ m/Reporting result of case.*OK/ig;
is($matches,2,"Attempts to to plans work");

#Test that spawn works
@args = (qw{--apiurl http://testrail.local --user test@fake.fake --password fake --project TestProject --run TestingSuite2 --testsuite_id 9 --case-ok  t/test_subtest.tap});
($out,(undef,$code)) = capture_merged {TestRail::Bin::Report::run('browser' => $Test::LWP::UserAgent::TestRailMock::mockObject, 'args' => \@args)};
is($code, 0, "Exit code OK reported with spawn");
$matches = () = $out =~ m/Reporting result of case.*OK/ig;
is($matches,2,"Attempts to spawn work: testsuite_id");

#Test that spawn works w/sections
@args = (qw{--apiurl http://testrail.local --user test@fake.fake --password fake --project TestProject --run TestingSuite2 --testsuite}, "HAMBURGER-IZE HUMANITY", qw{--case-ok --section}, "CARBON LIQUEFACTION", qw{ t/test_subtest.tap});
($out,(undef,$code)) = capture_merged {TestRail::Bin::Report::run('browser' => $Test::LWP::UserAgent::TestRailMock::mockObject, 'args' => \@args)};
is($code, 0, "Exit code OK reported with spawn");
$matches = () = $out =~ m/with specified sections/ig;
is($matches,1,"Attempts to spawn work: testsuite name");

#Test that the autoclose option works
@args = (qw{--apiurl http://testrail.local --user test@fake.fake --password fake --project TestProject --run FinalRun --plan FinalPlan --config testConfig --case-ok --autoclose  t/fake.tap});
($out,(undef,$code)) = capture_merged {TestRail::Bin::Report::run('browser' => $Test::LWP::UserAgent::TestRailMock::mockObject, 'args' => \@args)};
is($code, 0, "Exit code OK when doing autoclose");
like($out,qr/closing plan/i,"Run closure reported to user");

#Test that help works
@args = qw{--help};
$0 = $FindBin::Bin.'/../bin/testrail-report';
($out,(undef,$code)) = capture_merged {TestRail::Bin::Report::run('args' => \@args)};
is($code, 0, "Exit code OK asking for help");
like($out,qr/encoding of arguments/i,"Help output OK");
