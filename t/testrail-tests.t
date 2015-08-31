use strict;
use warnings;

use Test::More "tests" => 31;
use Test::Fatal;
use FindBin;
use IO::CaptureOutput qw{capture};

use lib $FindBin::Bin.'/../bin';
require 'testrail-tests';

#check plan mode
my @args = (qw{--apiurl http://testrail.local --user test@fake.fake --password fake -j TestProject -p GosPlan -r}, "Executing the great plan", qw{-m t --config testConfig --mock --no-recurse});
my ($out,$code) = TestRail::Bin::Tests::run(@args);
is($code, 0, "Exit code OK running plan mode, no recurse");
chomp $out;
like($out,qr/skipall\.test$/,"Gets test correctly in plan mode, no recurse");

#check no-match
@args = (qw{--apiurl http://testrail.local --user test@fake.fake --password fake -j TestProject -p GosPlan -r}, "Executing the great plan", qw{--no-match t --config testConfig --mock});
($out,$code) = TestRail::Bin::Tests::run(@args);
is($code, 0, "Exit code OK running plan mode, no match");
chomp $out;
unlike($out,qr/skipall\.test/,"Omits test correctly in plan mode, recurse, no-match");
unlike($out,qr/NOT SO SEARED AFTER ARR/,"Omits non-file test correctly in plan mode, recurse, no-match");
like($out,qr/faker\.test/,"Omits non-file test correctly in plan mode, recurse, no-match");

#check no-match, no recurse
@args = (qw{--apiurl http://testrail.local --user test@fake.fake --password fake -j TestProject -p GosPlan -r}, "Executing the great plan", qw{--no-match t --config testConfig --mock --no-recurse});
($out,$code) = TestRail::Bin::Tests::run(@args);
is($code, 0, "Exit code OK running plan mode, no match, no recurse");
chomp $out;
unlike($out,qr/skipall\.test/,"Omits test correctly in plan mode, no recurse, no-match");
unlike($out,qr/NOT SO SEARED AFTER ARR/,"Omits non-file test correctly in plan mode, no recurse, no-match");
like($out,qr/faker\.test/,"Omits non-file test correctly in plan mode, no recurse, no-match");

@args = (qw{--apiurl http://testrail.local --user test@fake.fake --password fake -j TestProject -p GosPlan -r}, "Executing the great plan", qw{--config testConfig -m t --mock});
($out,$code) = TestRail::Bin::Tests::run(@args);
is($code, 0, "Exit code OK running plan mode, recurse");
chomp $out;
like($out,qr/skipall\.test$/,"Gets test correctly in plan mode, recurse");

#check non plan mode
@args = (qw{--apiurl http://testrail.local --user test@fake.fake --password fake -j TestProject  -r TestingSuite -m t --mock --no-recurse});
($out,$code) = TestRail::Bin::Tests::run(@args);
is($code, 0, "Exit code OK running no plan mode, no recurse");
chomp $out;
like($out,qr/skipall\.test$/,"Gets test correctly in no plan mode, no recurse");

@args = (qw{--apiurl http://testrail.local --user test@fake.fake --password fake -j TestProject  -r TestingSuite -m t --mock});
($out,$code) = TestRail::Bin::Tests::run(@args);
is($code, 0, "Exit code OK running no plan mode, recurse");
chomp $out;
like($out,qr/skipall\.test$/,"Gets test correctly in no plan mode, recurse");

#Negative case, filtering by config
@args = (qw{--apiurl http://testrail.local --user test@fake.fake --password fake -j TestProject -p GosPlan -r}, "Executing the great plan", qw{-m t --mock --config testPlatform1});
isnt(exception {TestRail::Bin::Tests::run(@args)}, undef, "Exit code not OK when passing invalid configs for plan");

#check assignedto filters
@args = (qw{--apiurl http://testrail.local --user test@fake.fake --password fake -j TestProject -p GosPlan -r}, "Executing the great plan", qw{--mock --config testConfig --assignedto teodesian});
($out,$code) = TestRail::Bin::Tests::run(@args);
is($code, 0, "Exit code OK when filtering by assignment");
like($out,qr/skipall\.test$/,"Gets test correctly when filtering by assignment");

@args = (qw{--apiurl http://testrail.local --user test@fake.fake --password fake -j TestProject -p GosPlan -r}, "Executing the great plan", qw{--mock --config testConfig --assignedto billy});
($out,$code) = TestRail::Bin::Tests::run(@args);
is($code, 255, "Exit code OK when filtering by assignment");
chomp $out;
is($out,"","Gets no tests correctly when filtering by wrong assignment");

#check status filters
@args = (qw{--apiurl http://testrail.local --user test@fake.fake --password fake -j TestProject -p GosPlan -r}, "Executing the great plan", qw{-m t --mock --config testConfig --status passed});
($out,$code) = TestRail::Bin::Tests::run(@args);
is($code, 0, "Exit code OK when filtering by status");
like($out,qr/skipall\.test$/,"Gets test correctly when filtering by status");

@args = (qw{--apiurl http://testrail.local --user test@fake.fake --password fake -j TestProject -p GosPlan -r}, "Executing the great plan", qw{--mock --config testConfig --status failed});
($out,$code) = TestRail::Bin::Tests::run(@args);
is($code, 255, "Exit code OK when filtering by status");
chomp $out;
is($out,"","Gets no tests correctly when filtering by wrong status");

#Verify no-match returns non path
@args = (qw{--apiurl http://testrail.local --user test@fake.fake --password fake -j TestProject  -r TestingSuite --mock});
($out,$code) = TestRail::Bin::Tests::run(@args);
is($code, 0, "Exit code OK running no plan mode, no-match");
chomp $out;
like($out,qr/\nskipall\.test$/,"Gets test correctly in no plan mode, no-match");

#Verify no-match returns non path
@args = (qw{--apiurl http://testrail.local --user test@fake.fake --password fake -j TestProject  -r TestingSuite --orphans t --mock});
($out,$code) = TestRail::Bin::Tests::run(@args);
is($code, 0, "Exit code OK running no plan mode, no recurse");
chomp $out;
like($out,qr/NOT SO SEARED AFTER ARR/,"Gets test correctly in orphan mode");

#Verify no-match returns non path
@args = qw{--help};
$0 = $FindBin::Bin.'/../bin/testrail-tests';
(undef,$code) = capture {TestRail::Bin::Tests::run(@args)} \$out, \$out;
is($code, 0, "Exit code OK asking for help");
like($out,qr/encoding of arguments/i,"Help output OK");
