
BEGIN {
    unless ( $ENV{AUTHOR_TESTING} ) {
        require Test::More;
        Test::More::plan(
            skip_all => 'these tests are for testing by the author' );
    }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.18

use Test::More 0.88;
use Test::EOL;

my @files = (
    'bin/testrail-report',
    'bin/testrail-runs',
    'bin/testrail-tests',
    'lib/App/Prove/Plugin/TestRail.pm',
    'lib/Test/LWP/UserAgent/TestRailMock.pm',
    'lib/Test/Rail/Harness.pm',
    'lib/Test/Rail/Parser.pm',
    'lib/TestRail/API.pm',
    'lib/TestRail/Utils.pm',
    't/.testrailrc',
    't/00-compile.t',
    't/App-Prove-Plugin-Testrail.t',
    't/Test-Rail-Parser.t',
    't/TestRail-API-mockOnly.t',
    't/TestRail-API.t',
    't/TestRail-Utils.t',
    't/arg_types.t',
    't/author-classSafety.t',
    't/author-critic.t',
    't/author-eol.t',
    't/author-no-tabs.t',
    't/author-pod-spell.t',
    't/fake.tap',
    't/fake.test',
    't/faker.test',
    't/notests.test',
    't/pass.test',
    't/release-cpan-changes.t',
    't/release-kwalitee.t',
    't/release-minimum-version.t',
    't/release-mojibake.t',
    't/release-pod-linkcheck.t',
    't/release-pod-syntax.t',
    't/release-synopsis.t',
    't/release-test-version.t',
    't/release-unused-vars.t',
    't/server_dead.t',
    't/skip.test',
    't/skipall.test',
    't/test_multiple_files.tap',
    't/test_subtest.tap',
    't/testrail-report.t',
    't/testrail-runs.t',
    't/testrail-tests.t',
    't/todo_pass.test'
);

eol_unix_ok( $_, { trailing_whitespace => 1 } ) foreach @files;
done_testing;
