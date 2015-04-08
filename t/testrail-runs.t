use strict;
use warnings;

use Test::More 'tests' => 8;

#check status filters
my @args = ( $^X, qw{bin/testrail-runs -j 'TestProject' --mock} );
my $out = `@args`;
is( $? >> 8, 0, "Exit code OK looking for runs with passes" );
chomp $out;
like(
    $out,
    qr/^TestingSuite\nOtherOtherSuite$/,
    "Gets run correctly looking for passes"
);

#check status filters
@args = ( $^X, qw{bin/testrail-runs -j 'TestProject' --mock --status passed} );
$out = `@args`;
is(
    $? >> 8,
    0,
    "Exit code OK looking for runs with passes, which should fail to return results"
);
chomp $out;
is( $out, '', "Gets no runs correctly looking for passes" );

@args =
  ( $^X, qw{bin/testrail-runs -j 'CRUSH ALL HUMANS' --mock --status passed} );
$out = `@args`;
is( $? >> 8, 0, "Exit code OK looking for runs with passes" );
chomp $out;
like(
    $out,
    qr/SEND T-1000 INFILTRATION UNITS BACK IN TIME$/,
    "Gets run correctly looking for passes"
);

#TODO check configs for real next time
@args =
  ( $^X, qw{bin/testrail-runs -j 'TestProject' --mock --config testConfig} );
$out = `@args`;
is( $? >> 8, 0, "Exit code OK looking for runs with passes" );
chomp $out;
is( $out, '', "Gets no run correctly when filtering by unassigned config" );
