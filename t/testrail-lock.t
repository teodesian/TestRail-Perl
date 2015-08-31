use strict;
use warnings;

use Test::More "tests" => 2;
use FindBin;
use IO::CaptureOutput qw{capture};

use lib $FindBin::Bin.'/../bin';
require 'testrail-lock';

#VERY rudimentray checking
my @args = qw{--help};
$0 = $FindBin::Bin.'/../bin/testrail-lock';
my $out;
my (undef,$code) = capture {TestRail::Bin::Lock::run(@args)} \$out, \$out;
is($code, 0, "Exit code OK asking for help");
like($out,qr/encoding of arguments/i,"Help output OK");


