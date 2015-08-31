use strict;
use warnings;

use FindBin;

use lib $FindBin::Bin.'/../bin';
require 'testrail-cases';

use Test::More "tests" => 6;
use IO::CaptureOutput qw{capture};

#check plan mode
my @args = (qw{-j TestProject -t}, 'HAMBURGER-IZE HUMANITY', qw{-d t --mock --test --extension .test});
my ($out,$code) = TestRail::Bin::Cases::run(@args);
is($code, 0, "Exit code OK running add, update, orphans");
chomp $out;
like($out,qr/fake\.test/,"Shows existing tests by default");

@args = (qw{-j TestProject -t}, 'HAMBURGER-IZE HUMANITY', qw{-d t --mock  -o --extension .test});
($out,$code) = TestRail::Bin::Cases::run(@args);
chomp $out;
like($out,qr/nothere\.test/,"Shows orphan tests");

@args = (qw{-j TestProject -t}, 'HAMBURGER-IZE HUMANITY', qw{-d t --mock  -m --extension .test});
($out,$code) = TestRail::Bin::Cases::run(@args);
chomp $out;
like($out,qr/t\/skipall\.test/,"Shows missing tests");

#Verify no-match returns non path
@args = qw{--help};
$0 = $FindBin::Bin.'/../bin/testrail-cases';
(undef,$code) = capture {TestRail::Bin::Cases::run(@args)} \$out, \$out;
is($code, 0, "Exit code OK asking for help");
like($out,qr/encoding of arguments/i,"Help output OK");
