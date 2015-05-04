use strict;
use warnings;

use Test::More "tests" => 32;

#check plan mode
my @args = ($^X,qw{bin/testrail-tests --apiurl http://testrail.local --user "test@fake.fake" --password "fake" -j TestProject -p "GosPlan" -r "Executing the great plan" -m t --config testConfig --mock --no-recurse});
my $out = `@args`;
is($? >> 8, 0, "Exit code OK running plan mode, no recurse");
chomp $out;
like($out,qr/skipall\.test$/,"Gets test correctly in plan mode, no recurse");

#check no-match
@args = ($^X,qw{bin/testrail-tests --apiurl http://testrail.local --user "test@fake.fake" --password "fake" -j TestProject -p "GosPlan" -r "Executing the great plan" --no-match t --config testConfig --mock});
$out = `@args`;
is($? >> 8, 0, "Exit code OK running plan mode, no match");
chomp $out;
unlike($out,qr/skipall\.test/,"Omits test correctly in plan mode, recurse, no-match");
unlike($out,qr/NOT SO SEARED AFTER ARR/,"Omits non-file test correctly in plan mode, recurse, no-match");
like($out,qr/faker\.test/,"Omits non-file test correctly in plan mode, recurse, no-match");

#check no-match, no recurse
@args = ($^X,qw{bin/testrail-tests --apiurl http://testrail.local --user "test@fake.fake" --password "fake" -j TestProject -p "GosPlan" -r "Executing the great plan" --no-match t --config testConfig --mock --no-recurse});
$out = `@args`;
is($? >> 8, 0, "Exit code OK running plan mode, no match, no recurse");
chomp $out;
unlike($out,qr/skipall\.test/,"Omits test correctly in plan mode, no recurse, no-match");
unlike($out,qr/NOT SO SEARED AFTER ARR/,"Omits non-file test correctly in plan mode, no recurse, no-match");
like($out,qr/faker\.test/,"Omits non-file test correctly in plan mode, no recurse, no-match");


@args = ($^X,qw{bin/testrail-tests --apiurl http://testrail.local --user "test@fake.fake" --password "fake" -j TestProject -p "GosPlan" -r "Executing the great plan" --config testConfig -m t --mock});
$out = `@args`;
is($? >> 8, 0, "Exit code OK running plan mode, recurse");
chomp $out;
like($out,qr/skipall\.test$/,"Gets test correctly in plan mode, recurse");

#check non plan mode
@args = ($^X,qw{bin/testrail-tests --apiurl http://testrail.local --user "test@fake.fake" --password "fake" -j TestProject -r "TestingSuite" -m t --mock --no-recurse});
$out = `@args`;
is($? >> 8, 0, "Exit code OK running no plan mode, no recurse");
chomp $out;
like($out,qr/skipall\.test$/,"Gets test correctly in no plan mode, no recurse");

@args = ($^X,qw{bin/testrail-tests --apiurl http://testrail.local --user "test@fake.fake" --password "fake" -j TestProject -r "TestingSuite" -m t --mock});
$out = `@args`;
is($? >> 8, 0, "Exit code OK running no plan mode, recurse");
chomp $out;
like($out,qr/skipall\.test$/,"Gets test correctly in no plan mode, recurse");

#Negative case, filtering by config
@args = ($^X,qw{bin/testrail-tests --apiurl http://testrail.local --user "test@fake.fake" --password "fake" -j TestProject -p "GosPlan" -r "Executing the great plan" -m t --mock --config testPlatform1});
$out = `@args`;
isnt($? >> 8, 0, "Exit code not OK when passing invalid configs for plan");
chomp $out;
like($out,qr/no such run/i,"Gets test correctly in plan mode, recurse");

#check assignedto filters
@args = ($^X,qw{bin/testrail-tests --apiurl http://testrail.local --user "test@fake.fake" --password "fake" -j TestProject -p "GosPlan" -r "Executing the great plan" --mock --config "testConfig" --assignedto teodesian});
$out = `@args`;
is($? >> 8, 0, "Exit code OK when filtering by assignment");
like($out,qr/skipall\.test$/,"Gets test correctly when filtering by assignment");

@args = ($^X,qw{bin/testrail-tests --apiurl http://testrail.local --user "test@fake.fake" --password "fake" -j TestProject -p "GosPlan" -r "Executing the great plan" --mock --config "testConfig" --assignedto billy});
$out = `@args`;
is($? >> 8, 0, "Exit code OK when filtering by assignement");
chomp $out;
is($out,"","Gets no tests correctly when filtering by wrong assignment");

#check status filters
@args = ($^X,qw{bin/testrail-tests --apiurl http://testrail.local --user "test@fake.fake" --password "fake" -j TestProject -p "GosPlan" -r "Executing the great plan" -m t --mock --config "testConfig" --status "passed"});
$out = `@args`;
is($? >> 8, 0, "Exit code OK when filtering by status");
like($out,qr/skipall\.test$/,"Gets test correctly when filtering by status");

@args = ($^X,qw{bin/testrail-tests --apiurl http://testrail.local --user "test@fake.fake" --password "fake" -j TestProject -p "GosPlan" -r "Executing the great plan" --mock --config "testConfig" --status "failed"});
$out = `@args`;
is($? >> 8, 0, "Exit code OK when filtering by status");
chomp $out;
is($out,"","Gets no tests correctly when filtering by wrong status");

#Verify no-match returns non path
@args = ($^X,qw{bin/testrail-tests --apiurl http://testrail.local --user "test@fake.fake" --password "fake" -j TestProject -r "TestingSuite" --mock});
$out = `@args`;
is($? >> 8, 0, "Exit code OK running no plan mode, no recurse");
chomp $out;
like($out,qr/\nskipall\.test$/,"Gets test correctly in no plan mode, no recurse");

#Verify no-match returns non path
@args = ($^X,qw{bin/testrail-tests --help});
$out = `@args`;
is($? >> 8, 0, "Exit code OK asking for help");
like($out,qr/usage/i,"Help output OK");

#Verify no-match and match are mutually exclusive
@args = ($^X,qw{bin/testrail-tests --no-match t/ --match t/qa });
$out = `@args`;
isnt($? >> 8, 0, "Exit code not OK asking for mutually exclusive match options");
like($out,qr/mutually exclusive/i,"Death message OK");


