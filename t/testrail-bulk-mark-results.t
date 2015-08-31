use strict;
use warnings;

use Test::More "tests" => 4;
use FindBin;
use IO::CaptureOutput qw{capture};

use lib $FindBin::Bin.'/../bin';
require 'testrail-bulk-mark-results';

#check plan mode
my @args = (qw{--apiurl http://testrail.local --user test@fake.fake --password fake -j },"CRUSH ALL HUMANS", '-r', "SEND T-1000 INFILTRATION UNITS BACK IN TIME", qw{--mock blocked}, "Build was bad.");
my ($out,$code) = TestRail::Bin::BulkMarkResults::run(@args);
is($code, 0, "Exit code OK running against normal run");
chomp $out;
like($out,qr/set the status of 1 cases to blocked/,"Sets test correctly in single run mode");

@args = qw{--help};
$0 = $FindBin::Bin.'/../bin/testrail-bulk-mark-results';
(undef,$code) = capture {TestRail::Bin::BulkMarkResults::run(@args)} \$out, \$out;
is($code, 0, "Exit code OK asking for help");
like($out,qr/encoding of arguments/i,"Help output OK");

#TODO more thorough testing
