# ABSTRACT: Pick high priority cases for execution and lock them via the test results mechanism.
# PODNAME: TestRail::Utils::Lock

package TestRail::Utils::Lock;

use strict;
use warnings;

use Carp qw{confess cluck};

use Types::Standard qw( slurpy ClassName Object Str Int Bool HashRef ArrayRef Maybe Optional);
use Type::Params qw( compile );

use TestRail::API;
use TestRail::Utils;

=head1 DESCRIPTION

Lock a test case via usage of the test result field.
Has a hard limit of looking for 250 results, which is the only weakness of this locking approach.
If you have other test runners that result in such tremendous numbers of lock collisions,
it will result in 'hard-locked' cases, where manual intervention will be required to free the case.

However in that case, one would assume you could afford to write a reaper script to detect and
correct this condition, or consider altering your run strategy to reduce the probability of lock collisions.

=head2 pickAndLockTest(options,[handle])

Pick and lock a test case in a TestRail Run, and return it if successful, confess() on failure.

testrail-lock's primary routine.

=over 4

=item HASHREF C<OPTIONS> - valid keys/values correspond to the longnames of arguments taken by L<testrail-lock>.

=item TestRail::API C<HANDLE> - Instance of TestRail::API, in the case where the caller already has a valid object.

There are two special keys, 'mock' and 'simulate_race_condition' in the HASHREF that are used for testing.

=back

=cut

sub pickAndLockTest {
    my ($opts, $tr) = @_;

    if ($opts->{mock}) {
        require Test::LWP::UserAgent::TestRailMock; #LazyLoad
        $opts->{browser} = $Test::LWP::UserAgent::TestRailMock::mockObject;
        $opts->{debug} = 1;
    }

    $tr //= TestRail::API->new($opts->{apiurl},$opts->{user},$opts->{password},$opts->{'encoding'},$opts->{'debug'});
    $tr->{'browser'} = $opts->{'browser'} if $opts->{'browser'};
    $tr->{'debug'} = 0;

    my ($project,$plan,$run) = TestRail::Utils::getRunInformation($tr,$opts);

    my $status_ids;

    # Process statuses
    @$status_ids = $tr->statusNamesToIds($opts->{'lockname'},'untested','retest');
    my ($lock_status_id,$untested_id,$retest_id) = @$status_ids;

    my $cases = $tr->getTests($run->{'id'});
    my @statuses_to_check_for = ($untested_id,$retest_id);
    @statuses_to_check_for = ($lock_status_id) if $opts->{'simulate_race_condition'}; #Unit test stuff

    # Limit to only non-locked and open cases
    @$cases = grep { my $tstatus = $_->{'status_id'}; scalar(grep { $tstatus eq $_ } @statuses_to_check_for) } @$cases;
    @$cases = sort { $a->{'priority_id'} <=> $b->{'priority_id'} } @$cases; #Sort by priority

    my $test = shift @$cases;

    confess "No outstanding cases in the provided run.\n" if !$test;

    my $title;
    foreach my $test (@$cases) {
        $title = lockTest($test,$lock_status_id,$tr);
        last if $title;
    }

    confess "Failed to lock case!" if !$title;

    return $title;
}

=head2 lockTest(test,lock_status_id,handle)

Lock the specified test.

=over 4

=item HASHREF C<TEST> - Test object returned by getTest, or a similar method.

=item INTEGER C<LOCK_STATUS_ID> - Status used to denote locking of test

=item TestRail::API C<HANDLE> - Instance of TestRail::API

=back

Returns undef in the event a lock could not occur, and warns on lock collisions.

=cut

sub lockTest {
    state $check = compile(HashRef, Int, Object);
    my ($test,$lock_status_id,$handle) = $check->(@_);

    my $res = $tr->createTestResults(
        $test->{id},
        $lock_status_id,
        "Test Locked by $opts->{hostname}.\n
        If this result is preceded immediately by another lock statement like this, please disregard it;
        a lock collision occurred."
    );

    #If we've got more than 100 lock conflicts, we have big-time problems
    my $results = $tr->getTestResults($test->{id},100);

    #Remember, we're returned results from newest to oldest...
    my $next_one = 0;
    foreach my $result (@$results) {
        unless ($result->{'status_id'} == $lock_status_id) {
            #Clearly no lock conflict going on here if next_one is true
            last if $next_one;
            #Otherwise just skip it until we get to the test we locked
            next;
        }

        if ($result->{id} == $res->{'id'}) {
            $next_one = 1;
            next;
        }

        if ($next_one) {
            #If we got this far, a lock conflict occurred. Try the next one.
            warn "Lock conflict detected.  Try again...\n";
            return undef;
        }
    }
    return $test->{'title'} if $next_one;
    return undef;
}

1;
