use strict;
use warnings;

use Test::More "tests" => 4;

my @args = ($^X,qw{bin/testrail-bulk-mark-results --help});
my $out = `@args`;
is($? >> 8, 0, "Exit code OK asking for help");
like($out,qr/encoding of arguments/i,"Help output OK");

#check plan mode
@args = ($^X,qw{bin/testrail-bulk-mark-results --apiurl http://testrail.local --user "test@fake.fake" --password "fake" -j "CRUSH ALL HUMANS" -r "SEND T-1000 INFILTRATION UNITS BACK IN TIME" --mock blocked "Build was bad."});
$out = `@args`;
is($? >> 8, 0, "Exit code OK running against normal run");
chomp $out;
like($out,qr/set the status of 1 cases to blocked/,"Sets test correctly in single run mode");

#TODO more thorough testing
