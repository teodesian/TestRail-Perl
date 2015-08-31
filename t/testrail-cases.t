use strict;
use warnings;

use FindBin;

use lib $FindBin::Bin.'/../bin';
require 'testrail-cases';

use lib $FindBin::Bin.'/lib';
use Test::LWP::UserAgent::TestRailMock;

use Test::More "tests" => 6;
use IO::CaptureOutput qw{capture};

#check plan mode
my @args = (qw{--apiurl http://testrail.local --user test@fake.fake --password fake -j TestProject -t}, 'HAMBURGER-IZE HUMANITY', qw{-d t --test --extension .test});
my ($out,$code) = TestRail::Bin::Cases::run('browser' => $Test::LWP::UserAgent::TestRailMock::mockObject, 'args' => \@args);
is($code, 0, "Exit code OK running add, update, orphans");
chomp $out;
like($out,qr/fake\.test/,"Shows existing tests by default");

@args = (qw{--apiurl http://testrail.local --user test@fake.fake --password fake -j TestProject -t}, 'HAMBURGER-IZE HUMANITY', qw{-d t -o --extension .test});
($out,$code) = TestRail::Bin::Cases::run('browser' => $Test::LWP::UserAgent::TestRailMock::mockObject, 'args' => \@args);
chomp $out;
like($out,qr/nothere\.test/,"Shows orphan tests");

@args = (qw{--apiurl http://testrail.local --user test@fake.fake --password fake -j TestProject -t}, 'HAMBURGER-IZE HUMANITY', qw{-d t -m --extension .test});
($out,$code) = TestRail::Bin::Cases::run('browser' => $Test::LWP::UserAgent::TestRailMock::mockObject, 'args' => \@args);
chomp $out;
like($out,qr/t\/skipall\.test/,"Shows missing tests");

#Verify no-match returns non path
@args = qw{--help};
$0 = $FindBin::Bin.'/../bin/testrail-cases';
(undef,$code) = capture {TestRail::Bin::Cases::run('args' => \@args)} \$out, \$out;
is($code, 0, "Exit code OK asking for help");
like($out,qr/encoding of arguments/i,"Help output OK");
