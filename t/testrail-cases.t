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
my @args = (qw{-j TestProject -t}, 'HAMBURGER-IZE HUMANITY', qw{-d t --test --extension .test});
my ($out,$code) = TestRail::Bin::Cases::run('browser' => $Test::LWP::UserAgent::TestRailMock::mockObject, 'args' => \@args);
is($code, 0, "Exit code OK running add, update, orphans");
chomp $out;
like($out,qr/fake\.test/,"Shows existing tests by default");


