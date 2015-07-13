use strict;
use warnings;

use Test::More 'tests' => 2;

#help options
my @args = ($^X,qw{bin/testrail-runs --help});
my $out = `@args`;
is($? >> 8, 0, "Exit code OK looking for help");
like($out,qr/encoding of arguments/i,"Help output OK");
