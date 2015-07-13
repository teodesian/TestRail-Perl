use strict;
use warnings;

use Test::More 'tests' => 2;

#Test that help works
my @args = ($^X,qw{bin/testrail-report --help});
my $out = `@args`;
is($? >> 8, 0, "Exit code OK reported with help");
my $matches = () = $out =~ m/encoding of arguments/ig;
is($matches,1,"Help output OK");
