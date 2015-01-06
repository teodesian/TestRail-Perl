use strict;
use warnings;

use Test::More 'tests' => 4;

my @args = qw{bin/testrail-report --apiurl http://testrail.local --user "test@fake.fake" --password "fake" --project "CRUSH ALL HUMANS" --run "SEND T-1000 INFILTRATION UNITS BACK IN TIME" --mock t/test_multiple_files.tap};
my $out = `@args`;
is($? >> 8, 0, "Exit code OK reported with multiple files");
my $matches = () = $out =~ m/Reporting result of case/ig;
is($matches,2,"Attempts to upload multiple times");

@args = qw{bin/testrail-report --apiurl http://testrail.local --user "test@fake.fake" --password "fake" --project "CRUSH ALL HUMANS" --run "SEND T-1000 INFILTRATION UNITS BACK IN TIME" --case-ok --mock t/test_multiple_files.tap};
$out = `@args`;
is($? >> 8, 0, "Exit code OK reported with multiple files (case-ok mode)");
$matches = () = $out =~ m/Reporting result of case/ig;
is($matches,4,"Attempts to upload multiple times (case-ok mode)");
