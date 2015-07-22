# PODNAME: TestRail::Utils::Spawner
# ABSTRACT: Spawn Test Plans and Runs when user-defined criteria are met.

package TestRail::Utils::Spawner;

use strict;
use warnings;

=head1 DESCRIPTION

Automatically create plans/runs whenever you deem necesary, so they might be run by L<TestRail::Utils::Watcher>.

Can run indefinitely or terminate whenever no runs need to be spawned anymore.

=head1 CAVEAT

Not intended to be run on multiple hosts, like TestRail::Utils::Watcher,
as there is no simple way of having a distributed lock without a separate central database.

However, nothing is stopping you from overriding spawnRun to coordinate such locking through some mechanism.

=cut

=head1 CONSTRUCTOR

=head2 new

Define the parameters for running the spawner, and make them available at any time by any of the methods.

=cut

sub new {

}

=head1 MAIN ROUTINE

=head2 spawn()

If getNeededRuns returns any run specifications, then call spawnRun over each of the aforementioned runs.

=over 4

=item INTEGER C<WAIT> - Time in seconds to wait for new runs to be needed when none remain to put into TestRail.
A discrete unnatural number (-inf,0] for this value will make the waiter terminate when either condition occurs.
Defaults to 180 seconds.

=back

=cut

sub getNeededRuns {

}

=head1 METHODS TO OVERRIDE

=head2 spawnRun

Spawns a run based on a run definition returned by getNeededRuns.

Default method is basically an alias of TestRail::Utils::spawnRun.

=cut

sub spawnRun {
    return TestRail::Utils::spawnRun(shift);
}

=head2 getNeededRuns

Return an array of needed runs.

Default method will alway return an empty array.

=cut

sub getNeededRuns {
    return ();
}

1;
__END__

=head1 SPECIAL THANKS

Thanks to cPanel Inc, for graciously funding the creation of this module.
