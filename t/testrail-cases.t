use strict;
use warnings;

use Test::More "tests" => 6;

#check plan mode
my @args = ($^X,qw{bin/testrail-cases -j "TestProject" -t "HAMBURGER-IZE HUMANITY" -d t --mock --test --extension ".test"});
my $out = `@args`;
is($? >> 8, 0, "Exit code OK running add, update, orphans");
chomp $out;
like($out,qr/fake\.test/,"Shows existing tests by default");

@args = ($^X,qw{bin/testrail-cases -j "TestProject" -t "HAMBURGER-IZE HUMANITY" -d t --mock  -o --extension ".test"});
$out = `@args`;
chomp $out;
like($out,qr/nothere\.test/,"Shows orphan tests");

@args = ($^X,qw{bin/testrail-cases -j "TestProject" -t "HAMBURGER-IZE HUMANITY" -d t --mock  -m --extension ".test"});
$out = `@args`;
chomp $out;
like($out,qr/t\/skipall\.test/,"Shows missing tests");

#Verify no-match returns non path
@args = ($^X,qw{bin/testrail-cases --help});
$out = `@args`;
is($? >> 8, 0, "Exit code OK asking for help");
like($out,qr/encoding of arguments/i,"Help output OK");
