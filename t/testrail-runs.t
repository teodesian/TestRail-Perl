use strict;
use warnings;

use FindBin;

use lib $FindBin::Bin.'/../bin';
require 'testrail-runs';

use Test::More 'tests' => 12;
use IO::CaptureOutput qw{capture};

#check status filters
my @args = qw{--apiurl http://testrail.local --user test@fake.fake --password fake -j TestProject --mock};
my ($out,$code) = TestRail::Bin::Runs::run(@args);
is($code, 0, "Exit code OK looking for runs with passes");
chomp $out;
like($out,qr/^OtherOtherSuite\nTestingSuite\nFinalRun\nlockRun\nClosedRun$/,"Gets run correctly looking for passes");

#check LIFO sort
@args = qw{--apiurl http://testrail.local --user test@fake.fake --password fake -j TestProject --lifo --mock};
($out,$code) = TestRail::Bin::Runs::run(@args);
is($code, 0, "Exit code OK looking for runs with passes");
chomp $out;
like($out,qr/^lockRun\nClosedRun\nTestingSuite\nFinalRun\nOtherOtherSuite$/,"LIFO sort works");

#check milesort
@args = qw{--apiurl http://testrail.local --user test@fake.fake --password fake -j TestProject --milesort --mock};
($out,$code) = TestRail::Bin::Runs::run(@args);
is($code, 0, "Exit code OK looking for runs with passes");
chomp $out;
like($out,qr/^TestingSuite\nFinalRun\nlockRun\nClosedRun\nOtherOtherSuite$/,"milesort works");


#check status filters
@args = qw{--apiurl http://testrail.local --user test@fake.fake --password fake -j TestProject --mock --status passed};
($out,$code) = TestRail::Bin::Runs::run(@args);
is($code, 255, "Exit code OK looking for runs with passes, which should fail to return results");
chomp $out;
like($out,qr/no runs found/i,"Gets no runs correctly looking for passes");

#TODO check configs for real next time
@args = qw{--apiurl http://testrail.local --user test@fake.fake --password fake -j TestProject --mock --config testConfig --config eee};
($out,$code) = TestRail::Bin::Runs::run(@args);
is($code, 255, "Exit code OK looking for runs with passes");
chomp $out;
like($out,qr/no runs found/i,"Gets no run correctly when filtering by unassigned config");

#Verify no-match returns non path
@args = qw{--help};
$0 = $FindBin::Bin.'/../bin/testrail-runs';
(undef,$code) = capture {TestRail::Bin::Runs::run(@args)} \$out, \$out;
is($code, 0, "Exit code OK asking for help");
like($out,qr/encoding of arguments/i,"Help output OK");
