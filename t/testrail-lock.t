use strict;
use warnings;

use Test::More "tests" => 2;

#VERY rudimentray checking
my @args = ($^X,qw{bin/testrail-lock --help});
my $out = `@args`;
is($? >> 8, 0, "Can get help output OK");
chomp $out;
like($out,qr/useful to lock the test/,"Help Output looks as expected");

