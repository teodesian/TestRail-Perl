use strict;
use warnings;

use Test::Pod 'tests' => 2;
use Test::Pod::Coverage;
use TestRail::API;

my @pobjfiles = map { $INC{$_} } ('TestRail/API.pm');
foreach my $pm (@pobjfiles) {
    pod_file_ok($pm);
}

my @modules = ('TestRail::API');
foreach my $mod (@modules) {
    pod_coverage_ok($mod);
}
