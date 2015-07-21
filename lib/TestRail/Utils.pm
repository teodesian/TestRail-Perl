# ABSTRACT: Utilities for the testrail command line functions, and their main loops.
# PODNAME: TestRail::Utils

package TestRail::Utils;

use strict;
use warnings;

use Carp qw{confess cluck};
use Pod::Perldoc 3.10;

use Scalar::Util qw{blessed};
use File::Find;
use Cwd qw{abs_path};
use File::Basename qw{basename};

=head1 SCRIPT HELPER FUNCTIONS

=head2 help

Print the perldoc for $0 and exit.

=cut

sub help {
    @ARGV = ($0);
    Pod::Perldoc->run();
    exit 0;
}

=head2 userInput

Wait for user input and return it.

=cut

sub userInput {
 local $| = 1;
 my $rt = <STDIN>;
 chomp $rt;
 return $rt;
}

=head2 interrogateUser($options,@keys)

Wait for specified keys via userInput, and put them into $options HASHREF, if they are not already defined.
Returns modified $options HASHREF.
Dies if the user provides no value.

=cut

sub interrogateUser {
    my ($options,@keys) = @_;
    foreach my $key (@keys) {
        if (!$options->{$key}) {
            print "Type the $key for your testLink install below:\n";
            $options->{$key} = TestRail::Utils::userInput();
            die "$key cannot be blank!" unless $options->{$key};
        }
    }
    return $options;
}

=head2 parseConfig(homedir)

Parse .testrailrc in the provided home directory.

Returns:

ARRAY - (apiurl,password,user)

=cut

sub parseConfig {
    my ($homedir,$login_only) = @_;
    my $results = {};
    my $arr =[];

    open(my $fh, '<', $homedir . '/.testrailrc') or return (undef,undef,undef);#couldn't open!
    while (<$fh>) {
        chomp;
        @$arr = split(/=/,$_);
        if (scalar(@$arr) != 2) {
            warn("Could not parse $_ in '$homedir/.testrailrc'!\n");
            next;
        }
        $results->{lc($arr->[0])} = $arr->[1];
    }
    close($fh);
    return ($results->{'apiurl'},$results->{'password'},$results->{'user'}) if $login_only;
    return $results;
}

=head2 getFilenameFromTAPLine($line)

Analyze TAP output by prove and look for filename boundaries (no other way to figure out what file is run).
Long story short: don't end 'unknown' TAP lines with any number of dots if you don't want it interpreted as a test name.
Apparently this is the TAP way of specifying the file that's run...which is highly inadequate.

Inputs:

STRING LINE - some line of TAP

Returns:

STRING filename of the test that output the TAP.

=cut

sub getFilenameFromTapLine {
    my $orig = shift;

    $orig =~ s/ *$//g; # Strip all trailing whitespace

    #Special case
    my ($is_skipall) = $orig =~ /(.*)\.+ skipped:/;
    return $is_skipall if $is_skipall;

    my @process_split = split(/ /,$orig);
    return 0 unless scalar(@process_split);
    my $dotty = pop @process_split; #remove the ........ (may repeat a number of times)
    return 0 if $dotty =~ /\d/; #Apparently looking for literal dots returns numbers too. who knew?
    chomp $dotty;
    my $line = join(' ',@process_split);

    #IF it ends in a bunch of dots
    #AND it isn't an ok/not ok
    #AND it isn't a comment
    #AND it isn't blank
    #THEN it's a test name

    return $line if ($dotty =~ /^\.+$/ && !($line =~ /^ok|not ok/) && !($line =~ /^# /) && $line);
    return 0;
}

=head2 getRunInformation

Return the relevant project definition, plan, run and milestone definition HASHREFs for the provided options.

Dies in the event the project/plan/run could not be found.

=cut

sub getRunInformation {
    my ($tr,$opts) = @_;
    confess("First argument must be instance of TestRail::API") unless blessed($tr) eq 'TestRail::API';

    my $project = $tr->getProjectByName($opts->{'project'});
    confess "No such project '$opts->{project}'.\n" if !$project;

    my ($run,$plan);

    if ($opts->{'plan'}) {
        $plan = $tr->getPlanByName($project->{'id'},$opts->{'plan'});
        confess "No such plan '$opts->{plan}'!\n" if !$plan;
        $run = $tr->getChildRunByName($plan,$opts->{'run'}, $opts->{'configs'});
    } else {
        $run = $tr->getRunByName($project->{'id'},$opts->{'run'});
    }

    confess "No such run '$opts->{run}' matching the provided configs (if any).\n" if !$run;

    #If the run/plan has a milestone set, then return it too
    my $milestone;
    my $mid = $plan ? $plan->{'milestone_id'} : $run->{'milestone_id'};
    if ($mid) {
        $milestone = $tr->getMilestoneByID($mid);
        confess "Could not fetch run milestone!" unless $milestone; #hope this doesn't happen
    }

    return ($project, $plan, $run, $milestone);
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

    if ($opts->{'match'} || $opts->{'no-match'}) {
        my $dir = $opts->{'match'} ? $opts->{'match'} : $opts->{'no-match'};
        if (!$opts->{'no-recurse'}) {
            File::Find::find( sub { push(@realtests,$File::Find::name) if -f }, $dir );
            @tests = grep {my $real = $_->{'title'}; grep { $real eq basename($_) } @realtests} @cases; #XXX if you have dups in your tree, be-ware
        } else {
            #Handle special windows case -- glob doesn't prepend abspath
            @realtests = glob("$dir/*");
            @tests = map {
                $_->{'title'} = "$dir/".$_->{'title'} if( $^O eq 'MSWin32' );
                $_
            } grep {my $fname = $_->{'title'}; grep { basename($_) eq $fname} @realtests } @cases;
        }
        @tests = map {{'title' => $_}} grep {my $otest = basename($_); scalar(grep {basename($_->{'title'}) eq $otest} @tests) == 0} @realtests if $opts->{'no-match'}; #invert the list in this case.
    }

    @tests = map { abs_path($_->{'title'}) } @tests if $opts->{'match'} && $opts->{'names-only'};
    @tests = map { $_->{'full_title'} = abs_path($_->{'title'}); $_ } @tests if $opts->{'match'} && !$opts->{'names-only'};
    @tests = map { $_->{'title'} } @tests if !$opts->{'match'} && $opts->{'names-only'};

    return @tests;
}

1;

__END__

=head1 SPECIAL THANKS

Thanks to cPanel Inc, for graciously funding the creation of this module.
