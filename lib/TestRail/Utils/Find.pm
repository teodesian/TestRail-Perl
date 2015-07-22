# PODNAME: TestRail::Utils::Find
# ABSTRACT: Find runs and tests according to user specifications.

package TestRail::Utils::Find;

use strict;
use warnings;

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
    my ($status_ids,$user_ids);

    #Process statuses
    if ($opts->{'statuses'}) {
        @$status_ids = $tr->statusNamesToIds(@{$opts->{'statuses'}});
    }

    my $project = $tr->getProjectByName($opts->{'project'});
    confess("No such project '$opts->{project}'.\n") if !$project;

    my @pconfigs = ();
    @pconfigs = $tr->translateConfigNamesToIds($project->{'id'},$opts->{configs}) if $opts->{'configs'};

    my ($runs,$plans,$planRuns,$cruns,$found) = ([],[],[],[],0);
    $runs = $tr->getRuns($project->{'id'}) if (!$opts->{'configs'}); # If configs are passed, global runs are not in consideration.
    $plans = $tr->getPlans($project->{'id'});
    foreach my $plan (@$plans) {
        $cruns = $tr->getChildRuns($plan);
        next if !$cruns;
        foreach my $run (@$cruns) {
            next if scalar(@pconfigs) != scalar(@{$run->{'config_ids'}});

            #Compare run config IDs against desired, invalidate run if all conditions not satisfied
            $found = 0;
            foreach my $cid (@{$run->{'config_ids'}}) {
                $found++ if grep {$_ == $cid} @pconfigs;
            }

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

=head2 findTests

Find tests based on the options HASHREF provided.
See the documentation for L<testrail-tests>, as the long argument names there correspond to hash keys.

The primary routine of testrail-tests.

=over 4

=item HASHREF C<OPTIONS> - flags acceptable by testrail-tests

=item TestRail::API C<HANDLE> - TestRail::API object

=back

=cut

sub findTests {
    my ($opts,$tr) = @_;
}

1;

__END__

=head1 SPECIAL THANKS

Thanks to cPanel Inc, for graciously funding the creation of this module.
