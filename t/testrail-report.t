use strict;
use warnings;

use Test::More 'tests' => 16;

my @args = (
    $^X,
    qw{bin/testrail-report --apiurl http://testrail.local --user "test@fake.fake" --password "fake" --project "CRUSH ALL HUMANS" --run "SEND T-1000 INFILTRATION UNITS BACK IN TIME" --mock t/test_multiple_files.tap}
);
my $out = `@args`;
is( $? >> 8, 0, "Exit code OK reported with multiple files" );
my $matches = () = $out =~ m/Reporting result of case/ig;
is( $matches, 2, "Attempts to upload multiple times" );

@args = (
    $^X,
    qw{bin/testrail-report --apiurl http://testrail.local --user "test@fake.fake" --password "fake" --project "CRUSH ALL HUMANS" --run "SEND T-1000 INFILTRATION UNITS BACK IN TIME" --case-ok --mock t/test_multiple_files.tap}
);
$out = `@args`;
is( $? >> 8, 0, "Exit code OK reported with multiple files (case-ok mode)" );
$matches = () = $out =~ m/Reporting result of case/ig;
is( $matches, 4, "Attempts to upload multiple times (case-ok mode)" );

#Test version, case-ok
@args = (
    $^X,
    qw{bin/testrail-report --apiurl http://testrail.local --user "test@fake.fake" --password "fake" --project "TestProject" --run "TestingSuite" --case-ok --version '1.0.14' --mock t/test_subtest.tap}
);
$out = `@args`;
is( $? >> 8, 0, "Exit code OK reported with subtests (case-ok mode)" );
$matches = () = $out =~ m/Reporting result of case/ig;
is( $matches, 2, "Attempts to upload do not do subtests (case-ok mode)" );

#Test plans/configs
@args = (
    $^X,
    qw{bin/testrail-report --apiurl http://testrail.local --user "test@fake.fake" --password "fake" --project "TestProject" --run "Executing the great plan" --plan "GosPlan" --config "testConfig"  --case-ok --mock t/test_subtest.tap}
);
$out = `@args`;
is( $? >> 8, 0, "Exit code OK reported with plans" );
$matches = () = $out =~ m/Reporting result of case.*OK/ig;
is( $matches, 2, "Attempts to to plans work" );

#Test that spawn works
@args = (
    $^X,
    qw{bin/testrail-report --apiurl http://testrail.local --user "test@fake.fake" --password "fake" --project "TestProject" --run "TestingSuite2" --spawn 9 --case-ok --mock t/test_subtest.tap}
);
$out = `@args`;
is( $? >> 8, 0, "Exit code OK reported with spawn" );
$matches = () = $out =~ m/Reporting result of case.*OK/ig;
is( $matches, 2, "Attempts to spawn work" );

#Test that spawn works w/sections
@args = (
    $^X,
    qw{bin/testrail-report --apiurl http://testrail.local --user "test@fake.fake" --password "fake" --project "TestProject" --run "TestingSuite2" --spawn 9 --case-ok --section "CARBON LIQUEFACTION" --mock t/test_subtest.tap}
);
$out = `@args`;
is( $? >> 8, 0, "Exit code OK reported with spawn" );
$matches = () = $out =~ m/with specified sections/ig;
is( $matches, 1, "Attempts to spawn work" );

#Test that the autoclose option works
@args = (
    $^X,
    qw{bin/testrail-report --apiurl http://testrail.local --user "test@fake.fake" --password "fake" --project "TestProject" --run "FinalRun" --plan "FinalPlan" --config "testConfig" --case-ok --autoclose --mock t/fake.tap}
);
$out = `@args`;
is( $? >> 8, 0, "Exit code OK when doing autoclose" );
like( $out, qr/closing plan/i, "Run closure reported to user" );

#Test that help works
@args = ( $^X, qw{bin/testrail-report --help} );
$out = `@args`;
is( $? >> 8, 0, "Exit code OK reported with help" );
$matches = () = $out =~ m/usage/ig;
is( $matches, 1, "Help output OK" );

