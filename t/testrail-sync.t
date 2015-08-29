use strict;
use warnings;

use Test::More "tests" => 6;

#check plan mode
my @args = ($^X,qw{bin/testrail-sync -j "TestProject" -t "HAMBURGER-IZE HUMANITY" -d t/ -u -p --mock --test --extension .test});
my $out = `@args`;
is($? >> 8, 0, "Exit code OK running add, update, orphans");
chomp $out;
like($out,qr/Adding test t\/skipall\.test/,"Adds missing test");
like($out,qr/Deleting test nothere\.test/,"Deletes orphan test");
like($out,qr/Updating test fake\.test/,"Updates existing test");

#Verify no-match returns non path
@args = ($^X,qw{bin/testrail-sync --help});
$out = `@args`;
is($? >> 8, 0, "Exit code OK asking for help");
like($out,qr/encoding of arguments/i,"Help output OK");
