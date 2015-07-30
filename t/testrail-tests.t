use strict;
use warnings;

use Test::More "tests" => 30;

@args = ($^X,qw{bin/testrail-tests --help});
$out = `@args`;
is($? >> 8, 0, "Exit code OK asking for help");
like($out,qr/encoding of arguments/i,"Help output OK");
