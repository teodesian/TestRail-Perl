
BEGIN {
    unless ( $ENV{AUTHOR_TESTING} ) {
        require Test::More;
        Test::More::plan(
            skip_all => 'these tests are for testing by the author' );
    }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.09

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'bin/testrail-report',
    'lib/App/Prove/Plugin/TestRail.pm',
    'lib/Test/LWP/UserAgent/TestRailMock.pm',
    'lib/Test/Rail/Harness.pm',
    'lib/Test/Rail/Parser.pm',
    'lib/TestRail/API.pm',
    't/00-compile.t',
    't/Test-Rail-Parser.t',
    't/TestRail-API.t',
    't/arg_types.t',
    't/author-classSafety.t',
    't/author-critic.t',
    't/author-eol.t',
    't/author-no-tabs.t',
    't/author-pod-spell.t',
    't/fake.test',
    't/faker.test',
    't/release-cpan-changes.t',
    't/release-kwalitee.t',
    't/release-minimum-version.t',
    't/release-mojibake.t',
    't/release-pod-coverage.t',
    't/release-pod-linkcheck.t',
    't/release-pod-syntax.t',
    't/release-synopsis.t',
    't/release-test-version.t',
    't/release-unused-vars.t',
    't/server_dead.t'
);

notabs_ok($_) foreach @files;
done_testing;
