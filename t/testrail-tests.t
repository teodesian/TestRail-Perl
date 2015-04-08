use strict;
use warnings;

use Test::More 'tests' => 18;

#check plan mode
my @args = ($^X,qw{bin/testrail-tests -j TestProject -p 'GosPlan' -r 'Executing the great plan' -m t --config testConfig --mock --no-recurse});
my $out = `@args`;
is($? >> 8, 0, "Exit code OK running plan mode, no recurse");
chomp $out;
like($out,qr/skipall\.test$/,"Gets test correctly in plan mode, no recurse");

@args = ($^X,qw{bin/testrail-tests -j TestProject -p 'GosPlan' -r 'Executing the great plan' --config testConfig -m t --mock});
$out = `@args`;
is($? >> 8, 0, "Exit code OK running plan mode, recurse");
chomp $out;
like($out,qr/skipall\.test$/,"Gets test correctly in plan mode, recurse");

#check non plan mode
@args = ($^X,qw{bin/testrail-tests -j TestProject -r 'TestingSuite' -m t --mock --no-recurse});
$out = `@args`;
is($? >> 8, 0, "Exit code OK running no plan mode, no recurse");
chomp $out;
like($out,qr/skipall\.test$/,"Gets test correctly in no plan mode, no recurse");

@args = ($^X,qw{bin/testrail-tests -j TestProject -r 'TestingSuite' -m t --mock});
$out = `@args`;
is($? >> 8, 0, "Exit code OK running no plan mode, recurse");
chomp $out;
like($out,qr/skipall\.test$/,"Gets test correctly in no plan mode, recurse");

#Negative case, filtering by config
@args = ($^X,qw{bin/testrail-tests -j TestProject -p 'GosPlan' -r 'Executing the great plan' -m t --mock --config testPlatform1});
$out = `@args`;
isnt($? >> 8, 0, "Exit code not OK when passing invalid configs for plan");
chomp $out;
like($out,qr/no such run/i,"Gets test correctly in plan mode, recurse");

#check assignedto filters
@args = ($^X,qw{bin/testrail-tests -j TestProject -p 'GosPlan' -r 'Executing the great plan' --mock --config 'testConfig' --assignedto teodesian});
$out = `@args`;
is($? >> 8, 0, "Exit code OK when filtering by assignment");
like($out,qr/skipall\.test$/,"Gets test correctly when filtering by assignment");

@args = ($^X,qw{bin/testrail-tests -j TestProject -p 'GosPlan' -r 'Executing the great plan' --mock --config 'testConfig' --assignedto billy});
$out = `@args`;
is($? >> 8, 0, "Exit code OK when filtering by assignement");
chomp $out;
is($out,'',"Gets no tests correctly when filtering by wrong assignment");

#check status filters
@args = ($^X,qw{bin/testrail-tests -j TestProject -p 'GosPlan' -r 'Executing the great plan' -m t --mock --config 'testConfig' --status 'passed'});
$out = `@args`;
is($? >> 8, 0, "Exit code OK when filtering by status");
like($out,qr/skipall\.test$/,"Gets test correctly when filtering by status");

@args = ($^X,qw{bin/testrail-tests -j TestProject -p 'GosPlan' -r 'Executing the great plan' --mock --config 'testConfig' --status 'failed'});
$out = `@args`;
is($? >> 8, 0, "Exit code OK when filtering by status");
chomp $out;
is($out,'',"Gets no tests correctly when filtering by wrong status");


