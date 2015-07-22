# PODNAME: TestRail::Utils::Watcher
# ABSTRACT: Find and run tests in active runs according to user criteria and resources.

package TestRail::Utils::Watcher;

use strict;
use warnings;

=head1 DESCRIPTION

Allow distributed watching and running of automated tests in a TestRail install.
This is accomplished by discovering active runs in the project(s) specified, and running the cases we can find automated tests for in the provided directory.
Tests are locked so that only one host running this watcher will run any given test.

Runs are prioritized by their milestone's due date.  Similarly, cases are prioritized from most important to least important.
That said, less important cases in more important runs will be run before more important cases in less important runs, so be aware of this.
Prioritazion of runs may be configured to be LIFO (last-in, first-out) or FIFO (first-in, first-out).

Can be configured to run indefinitely, or terminate when testing jobs or resources are exhausted.

=head1 RATIONALE

Much like testrail-lock, the purpose of this is to facilitate automated testing by a number of hosts, each simultaneously watching testrail.
This is how one can have nonstop, scalable testing of a work product.

In my particular situation, I needed to interface with a custom build provisioning process, and a virtual machine infrastructure tied into said builds.
Creating a framework where subclassing to handle the resource constraints implied by such a situation seemed a straightforward solution to this problem.
Furthermore, providing success and failure callback mechanisms, and handling/recovery of unexpected termination is desirable in such a situation.

Nor is this a problem unique to my situation, practically every firm has some variant of this problem; ergo making a generic solution is desirable.

=head1 TIPS AND TRICKS

When running testrail-spawner, I set the milestone name to describe what build of my System Under Test to use;
this is used along with the configurations in the run to inform both my overrides of canRunTest and RunTest.
They must rebuild allocated virtual machines to precise specifications, and using such fields is a good way of doing so.

This is done primarily because I cannot add configurations automatically, while my builds are provisioned automatically.
Using milestones solves this problem, as they can be created via the API.
My available configurations to test these versions on does not change rapidly however, so leaving them as a manual process is acceptable.

Using case-per-ok mode is not recommended when configuring App::Prove::Plugin testrail in runTest overrides.

=head1 CONSTRUCTOR

=head2 new

Define the parameters for running the watcher, and make them available at any time by any of the methods.

=cut

sub new {

}

=head1 MAIN ROUTINE

=head2 watch

See if tests can be ran, and if so, Find and lock a case, and run it.
Roughly equivalent to plumbing together testrail-runs and testrail-lock, and piping the output to prove with App::Prove::Plugin::TestRail loaded.

=over 4

=item INTEGER C<WAIT> - Time in seconds to wait for tests to become available when no tests are outstanding, or no resources are free to perform testing.
A discrete unnatural number (-inf,0] for this value will make the waiter terminate when either condition occurs.
Defaults to 60 seconds.

=back

Returns the information obtained by pickAndLockTest, and the return value of runTest, whatever that is.

=cut

sub watch {

}

=head1 METHODS TO OVERRIDE

=head2 canRunTests

Default "Can I run tests" method.  Intended to be overridden by subclasses.
watch() calls this for every run it considers worth testing, and will skip the run until resources come available, or the run is completed.

Provides a Run, it's configurations and it's milestone as arguments to guide whether or not you have available resources to run tests in a given run.

Always returns that 1 test can be run, but subclass authors should make it return the number of tests that can be run using our available resources.

=cut

sub canRunTests {
    return 1;
}

=head2 runTest

Default "Run the test" method.  Intended to be overridden by subclasses.
Simply calls App::Prove with the relevant TestRail options provided by the caller (basically the output of TestRail::Utils::Lock::pickAndLockTest).

Called by watch() whenever canRunTests returns a natural number for a given run.

Provides the output of pickAndLockTest as arguments.

=cut

sub runTest {

}

1;
__END__

=head1 SPECIAL THANKS

Thanks to cPanel Inc, for graciously funding the creation of this module.
