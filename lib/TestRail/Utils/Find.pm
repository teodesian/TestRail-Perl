# PODNAME: TestRail::Utils::Find
# ABSTRACT: Find runs and tests according to user specifications.

package TestRail::Utils::Find;

use strict;
use warnings;

use Carp qw{confess cluck};
use Scalar::Util qw{blessed};

use File::Find;
use Cwd qw{abs_path};
use File::Basename qw{basename};

use TestRail::Utils;

=head1 DESCRIPTION

=head1 FUNCTIONS

=head2 findRuns

Find runs based on the options HASHREF provided.
See the documentation for L<testrail-runs>, as the long argument names there correspond to hash keys.

The primary routine of testrail-runs.

=over 4

=item HASHREF C<OPTIONS> - flags acceptable by testrail-tests

=item TestRail::API C<HANDLE> - TestRail::API object

=back

Returns ARRAYREF of run definition HASHREFs.

=cut

sub findRuns {
    my ($opts,$tr) = @_;
    confess("TestRail handle must be provided as argument 2") unless blessed($tr) eq 'TestRail::API';

    my ($status_ids);

    #Process statuses
    if ($opts->{'statuses'}) {
        @$status_ids = $tr->statusNamesToIds(@{$opts->{'statuses'}});
    }

    my $project = $tr->getProjectByName($opts->{'project'});
    confess("No such project '$opts->{project}'.\n") if !$project;

    my $pconfigs = [];
    $pconfigs = $tr->translateConfigNamesToIds($project->{'id'},$opts->{configs}) if $opts->{'configs'};

    my ($runs,$plans,$planRuns,$cruns,$found) = ([],[],[],[],0);
    $runs = $tr->getRuns($project->{'id'}) if (!$opts->{'configs'}); # If configs are passed, global runs are not in consideration.
    $plans = $tr->getPlans($project->{'id'});
    @$plans = map {$tr->getPlanByID($_->{'id'})} @$plans;
    foreach my $plan (@$plans) {
        $cruns = $tr->getChildRuns($plan);
        next if !$cruns;
        foreach my $run (@$cruns) {
            next if scalar(@$pconfigs) != scalar(@{$run->{'config_ids'}});

            #Compare run config IDs against desired, invalidate run if all conditions not satisfied
            $found = 0;
            foreach my $cid (@{$run->{'config_ids'}}) {
                $found++ if grep {$_ == $cid} @$pconfigs;
            }
            $run->{'created_on'}   = $plan->{'created_on'};
            $run->{'milestone_id'} = $plan->{'milestone_id'};
            push(@$planRuns, $run) if $found == scalar(@{$run->{'config_ids'}});
        }
    }

    push(@$runs,@$planRuns);

    if ($opts->{'statuses'}) {
        @$runs =  $tr->getRunSummary(@$runs);
        @$runs = grep { defined($_->{'run_status'}) } @$runs; #Filter stuff with no results
        foreach my $status (@{$opts->{'statuses'}}) {
            @$runs = grep { $_->{'run_status'}->{$status} } @$runs; #If it's positive, keep it.  Otherwise forget it.
        }
    }

    #Sort FIFO/LIFO by milestone or creation date of run
    my $sortkey = 'created_on';
    if ($opts->{'milesort'}) {
        @$runs = map {
            my $run = $_;
            $run->{'milestone'} = $tr->getMilestoneByID($run->{'milestone_id'}) if $run->{'milestone_id'};
            my $milestone = $run->{'milestone'} ? $run->{'milestone'}->{'due_on'} : 0;
            $run->{'due_on'} = $milestone;
            $run
        } @$runs;
        $sortkey = 'due_on';
    }

    if ($opts->{'lifo'}) {
        @$runs = sort { $b->{$sortkey} <=> $a->{$sortkey} } @$runs;
    } else {
        @$runs = sort { $a->{$sortkey} <=> $b->{$sortkey} } @$runs;
    }

    return $runs;
}

=head2 getTests(opts,testrail)

Get the tests specified by the options passed.

=over 4

=item HASHREF C<OPTS> - Options for getting the tests

=over 4

=item STRING C<PROJECT> - name of Project to look for tests in

=item STRING C<RUN> - name of Run to get tests from

=item STRING C<PLAN> (optional) - name of Plan to get run from

=item ARRAYREF[STRING] C<CONFIGS> (optional) - names of configs run must satisfy, if part of a plan

=item ARRAYREF[STRING] C<USERS> (optional) - names of users to filter cases by assignee

=item ARRAYREF[STRING] C<STATUSES> (optional) - names of statuses to filter cases by

=back

=back

Returns ARRAYREF of tests, and the run in which they belong.

=cut

sub getTests {
    my ($opts,$tr) = @_;
    confess("TestRail handle must be provided as argument 2") unless blessed($tr) eq 'TestRail::API';

    my (undef,undef,$run) = TestRail::Utils::getRunInformation($tr,$opts);
    my ($status_ids,$user_ids);

    #Process statuses
    @$status_ids = $tr->statusNamesToIds(@{$opts->{'statuses'}}) if $opts->{'statuses'};

    #Process assignedto ids
    @$user_ids = $tr->userNamesToIds(@{$opts->{'users'}}) if $opts->{'users'};

    my $cases = $tr->getTests($run->{'id'},$status_ids,$user_ids);
    return ($cases,$run);
}

=head2 findTests(opts,case1,...,caseN)

Given an ARRAY of tests, find tests meeting your criteria (or not) in the specified directory.

=over 4

=item HASHREF C<OPTS> - Options for finding tests:

=over 4

=item STRING C<MATCH> - Only return tests which exist in the path provided.  Mutually exclusive with no-match.

=item STRING C<NO-MATCH> - Only return tests which aren't in the path provided (orphan tests).  Mutually exclusive with match.

=item BOOL C<NO-RECURSE> - Do not do a recursive scan for files.

=item BOOL C<NAMES-ONLY> - Only return the names of the tests rather than the entire test objects.

=item STRING C<EXTENSION> (optional) - Only return files ending with the provided text (e.g. .t, .test, .pl, .pm)

=back

=item ARRAY C<CASES> - Array of cases to translate to pathnames based on above options.

=back

Returns tests found that meet the criteria laid out in the options.
Provides absolute path to tests if match is passed; this is the 'full_title' key if names-only is false/undef.
Dies if mutually exclusive options are passed.

=cut

sub findTests {
    my ($opts,@cases) = @_;

    confess "Error! match and no-match options are mutually exclusive.\n" if ($opts->{'match'} && $opts->{'no-match'});
    my @tests = @cases;
    my (@realtests);
    my $ext = $opts->{'extension'} // '';

    if ($opts->{'match'} || $opts->{'no-match'}) {
        my $dir = $opts->{'match'} ? $opts->{'match'} : $opts->{'no-match'};
        if (!$opts->{'no-recurse'}) {
            File::Find::find( sub { push(@realtests,$File::Find::name) if -f && m/\Q$ext\E$/ }, $dir );
            @tests = grep {my $real = $_->{'title'}; grep { $real eq basename($_) } @realtests} @cases; #XXX if you have dups in your tree, be-ware
        } else {
            #Handle special windows case -- glob doesn't prepend abspath
            @realtests = glob("$dir/*$ext");
            @tests = map {
                $_->{'title'} = "$dir/".$_->{'title'} if( $^O eq 'MSWin32' );
                $_
            } grep {my $fname = $_->{'title'}; grep { basename($_) eq $fname} @realtests } @cases;
        }
        @tests = map {{'title' => $_}} grep {my $otest = basename($_); scalar(grep {basename($_->{'title'}) eq $otest} @tests) == 0} @realtests if $opts->{'no-match'}; #invert the list in this case.
    }

    @tests = map { abs_path($opts->{'match'}.'/'.$_->{'title'}) } @tests if $opts->{'match'} && $opts->{'names-only'};
    @tests = map { $_->{'full_title'} = abs_path($opts->{'match'}.'/'.$_->{'title'}); $_ } @tests if $opts->{'match'} && !$opts->{'names-only'};
    @tests = map { $_->{'title'} } @tests if !$opts->{'match'} && $opts->{'names-only'};

    return @tests;
}

1;

__END__

=head1 SPECIAL THANKS

Thanks to cPanel Inc, for graciously funding the creation of this module.
