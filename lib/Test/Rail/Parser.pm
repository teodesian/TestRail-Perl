# ABSTRACT: Upload your TAP results to TestRail
# PODNAME: Test::Rail::Parser

package Test::Rail::Parser;

use strict;
use warnings;
use utf8;

use parent qw/TAP::Parser/;
use Carp qw{cluck confess};
use POSIX qw{floor};

use TestRail::API;
use Scalar::Util qw{reftype};

use File::Basename qw{basename};

our $self;

=head1 DESCRIPTION

A TAP parser which will upload your test results to a TestRail install.
Has several options as to how you might want to upload said results.

Subclass of L<TAP::Parser>, see that for usage past the constructor.

You should probably use L<App::Prove::Plugin::TestRail> or the bundled program testrail-report for day-to-day usage...
unless you need to subclass this.  In that case a couple of options have been exposed for your convenience.

=cut

=head1 CONSTRUCTOR

=head2 B<new(OPTIONS)>

Get the TAP Parser ready to talk to TestRail, and register a bunch of callbacks to upload test results.

=over 4

=item B<OPTIONS> - HASHREF -- Keys are as follows:

=over 4

=item B<apiurl> - STRING: Full URI to your TestRail installation.

=item B<user> - STRING: Name of your TestRail user.

=item B<pass> - STRING: Said user's password.

=item B<debug> - BOOLEAN: Print a bunch of extra messages

=item B<browser> - OBJECT: Something like an LWP::UserAgent.  Useful for mocking with L<Test::LWP::UserAgent::TestRailMock>.

=item B<run> - STRING (semi-optional): name of desired run. Required if run_id not passed.

=item B<run_id> - INTEGER (semi-optional): ID of desired run. Required if run not passed.

=item B<plan> - STRING (semi-optional): Name of test plan to use, if your run provided is a child of said plan.  Only relevant when run_id not passed.

=item B<configs> - ARRAYREF (optional): Configurations to filter runs in plan by.  Runs can have the same name, yet with differing configurations in a plan; this handles that odd case.

=item B<project> - STRING (optional): name of project containing your desired run.  Required if project_id not passed.

=item B<project_id> - INTEGER (optional): ID of project containing your desired run.  Required if project not passed.

=item B<step_results> - STRING (optional): 'internal name' of the 'step_results' type field available for your project.  Mutually exclusive with case_per_ok

=item B<case_per_ok> - BOOLEAN (optional): Consider test files to correspond to section names, and test steps (OKs) to correspond to tests in TestRail.  Mutually exclusive with step_results.

=item B<result_options> - HASHREF (optional): Extra options to set with your result.  See L<TestRail::API>'s createTestResults function for more information.

=item B<custom_options> - HASHREF (optional): Custom options to set with your result.  See L<TestRail::API>'s createTestResults function for more information.  step_results will be set here, if the option is passed.

=item B<spawn> - INTEGER (optional): Attempt to create a run based on the provided testsuite identified by the ID passed here.  If plan/configs is passed, create it as a child of said plan with the listed configs.  If the run exists, use it and disregard the provided testsuite ID.  If the plan does not exist, create it too.

=back

=back

It is worth noting that if neither step_results or case_per_ok is passed, that the test will be passed if it has no problems of any sort, failed otherwise.
In both this mode and step_results, the file name of the test is expected to correspond to the test name in TestRail.

This module also attempts to calculate the elapsed time to run each test if it is run by a prove plugin rather than on raw TAP.

=cut

sub new {
    my ($class,$opts) = @_;
    our $self;

    #Load our callbacks
    $opts->{'callbacks'} = {
        'test'    => \&testCallback,
        'comment' => \&commentCallback,
        'unknown' => \&unknownCallback,
        'EOF'     => \&EOFCallback
    };

    my $tropts = {
        'apiurl'       => delete $opts->{'apiurl'},
        'user'         => delete $opts->{'user'},
        'pass'         => delete $opts->{'pass'},
        'debug'        => delete $opts->{'debug'},
        'browser'      => delete $opts->{'browser'},
        'run'          => delete $opts->{'run'},
        'run_id'       => delete $opts->{'run_id'},
        'project'      => delete $opts->{'project'},
        'project_id'   => delete $opts->{'project_id'},
        'step_results' => delete $opts->{'step_results'},
        'case_per_ok'  => delete $opts->{'case_per_ok'},
        'plan'         => delete $opts->{'plan'},
        'configs'      => delete $opts->{'configs'} // [],
        'spawn'        => delete $opts->{'spawn'},
        #Stubs for extension by subclassers
        'result_options'        => delete $opts->{'result_options'},
        'result_custom_options' => delete $opts->{'result_custom_options'}
    };

    confess("case_per_ok and step_results options are mutually exclusive") if ($tropts->{'case_per_ok'} && $tropts->{'step_results'});

    #Allow natural confessing from constructor
    my $tr = TestRail::API->new($tropts->{'apiurl'},$tropts->{'user'},$tropts->{'pass'},$tropts->{'debug'});
    $tropts->{'testrail'} = $tr;
    $tr->{'browser'} = $tropts->{'browser'} if defined($tropts->{'browser'}); #allow mocks
    $tr->{'debug'} = 0; #Always suppress in production

    #Get project ID from name, if not provided
    if (!defined($tropts->{'project_id'})) {
        my $pname = $tropts->{'project'};
        $tropts->{'project'} = $tr->getProjectByName($pname);
        confess("Could not list projects! Shutting down.") if ($tropts->{'project'} == -500);
        if (!$tropts->{'project'}) {
            confess("No project (or project_id) provided, or that which was provided was invalid!");
        }
    } else {
        $tropts->{'project'} = $tr->getProjectByID($tropts->{'project_id'});
        confess("No such project with ID $tropts->{project_id}!") if !$tropts->{'project'};
    }
    $tropts->{'project_id'} = $tropts->{'project'}->{'id'};

    #Discover possible test statuses
    $tropts->{'statuses'} = $tr->getPossibleTestStatuses();
    my @ok = grep {$_->{'name'} eq 'passed'} @{$tropts->{'statuses'}};
    my @not_ok = grep {$_->{'name'} eq 'failed'} @{$tropts->{'statuses'}};
    my @skip = grep {$_->{'name'} eq 'skip'} @{$tropts->{'statuses'}};
    my @todof = grep {$_->{'name'} eq 'todo_fail'} @{$tropts->{'statuses'}};
    my @todop = grep {$_->{'name'} eq 'todo_pass'} @{$tropts->{'statuses'}};
    confess("No status with internal name 'passed' in TestRail!") unless scalar(@ok);
    confess("No status with internal name 'failed' in TestRail!") unless scalar(@not_ok);
    confess("No status with internal name 'skip' in TestRail!") unless scalar(@skip);
    confess("No status with internal name 'todo_fail' in TestRail!") unless scalar(@todof);
    confess("No status with internal name 'todo_pass' in TestRail!") unless scalar(@todop);
    $tropts->{'ok'} = $ok[0];
    $tropts->{'not_ok'} = $not_ok[0];
    $tropts->{'skip'} = $skip[0];
    $tropts->{'todo_fail'} = $todof[0];
    $tropts->{'todo_pass'} = $todop[0];

    #Grab run
    my $run_id = $tropts->{'run_id'};
    my ($run,$plan,$config_ids);

    #check if configs passed are defined for project.  If we can't get all the IDs, something's hinky
    $config_ids = $tr->translateConfigNamesToIds($tropts->{'project_id'},$tropts->{'configs'});
    confess("Could not retrieve list of valid configurations for your project.") unless (reftype($config_ids) || 'undef') eq 'ARRAY';
    my @bogus_configs = grep {!defined($_)} @$config_ids;
    my $num_bogus = scalar(@bogus_configs);
    confess("Detected $num_bogus bad config names passed.  Check available configurations for your project.") if $num_bogus;

    if ($tropts->{'run'}) {
        if ($tropts->{'plan'}) {
            #Attempt to find run, filtered by configurations
            $plan = $tr->getPlanByName($tropts->{'project_id'},$tropts->{'plan'});
            if ($plan) {
                $tropts->{'plan'} = $plan;
                $run = $tr->getChildRunByName($plan,$tropts->{'run'},$tropts->{'configs'}); #Find plan filtered by configs
                if (defined($run) && (reftype($run) || 'undef') eq 'HASH') {
                    $tropts->{'run'} = $run;
                    $tropts->{'run_id'} = $run->{'id'};
                }
            } else {
                #Try to make it if spawn is passed
                $tropts->{'plan'} = $tr->createPlan($tropts->{'project_id'},$tropts->{'plan'},"Test plan created by TestRail::API");
                confess("Could not find plan ".$tropts->{'plan'}." in provided project, and spawning failed!") if !$tropts->{'plan'};
            }
        } else {
            $run = $tr->getRunByName($tropts->{'project_id'},$tropts->{'run'});
            if (defined($run) && (reftype($run) || 'undef') eq 'HASH') {
                $tropts->{'run'} = $run;
                $tropts->{'run_id'} = $run->{'id'};
            }
        }
    } else {
        $tropts->{'run'} = $tr->getRunByID($run_id);
    }

    #If spawn was passed and we don't have a Run ID yet, go ahead and make it
    if ($tropts->{'spawn'} && !$tropts->{'run_id'}) {
        if ($tropts->{'plan'}) {
            $plan = $tr->createRunInPlan( $tropts->{'plan'}->{'id'}, $tropts->{'spawn'}, $tropts->{'run'}, undef, $config_ids );
            $run = $plan->{'runs'}->[0] if exists($plan->{'runs'}) && (reftype($plan->{'runs'}) || 'undef') eq 'ARRAY' && scalar(@{$plan->{'runs'}});
            if (defined($run) && (reftype($run) || 'undef') eq 'HASH') {
                $tropts->{'run'} = $run;
                $tropts->{'run_id'} = $run->{'id'};
            }
        } else {
            $run = $tr->createRun( $tropts->{'project_id'}, $tropts->{'spawn'}, $tropts->{'run'}, "Automatically created Run from TestRail::API" );
            if (defined($run) && (reftype($run) || 'undef') eq 'HASH') {
                $tropts->{'run'} = $run;
                $tropts->{'run_id'} = $run->{'id'};
            }
        }
        confess("Could not spawn run with requested parameters!") if !$tropts->{'run_id'};
    }

    confess("No run ID provided, and no run with specified name exists in provided project/plan!") if !$tropts->{'run_id'};

    $self = $class->SUPER::new($opts);
    if (defined($self->{'_iterator'}->{'command'}) && reftype($self->{'_iterator'}->{'command'}) eq 'ARRAY' ) {
        $self->{'file'} = $self->{'_iterator'}->{'command'}->[-1];
        print "PROCESSING RESULTS FROM TEST FILE: $self->{'file'}\n";
        $self->{'track_time'} = 1;
    } else {
        #Not running inside of prove in real-time, don't bother with tracking elapsed times.
        $self->{'track_time'} = 0;
    }

    #Make sure the step results field passed exists on the system
    $tropts->{'step_results'} = $tr->getTestResultFieldByName($tropts->{'step_results'},$tropts->{'project_id'}) if defined $tropts->{'step_results'};

    $self->{'tr_opts'} = $tropts;
    $self->{'errors'}  = 0;
    #Start the shot clock
    $self->{'starttime'} = time();
    $self->{'raw_output'} = "";

    return $self;
}

=head1 PARSER CALLBACKS

=head2 unknownCallback

Called whenever we encounter an unknown line in TAP.  Only useful for prove output, as we might pick a filename out of there.
Stores said filename for future use if encountered.

=cut

# Look for file boundaries, etc.
sub unknownCallback {
    my (@args) = @_;
    our $self;
    my $line = $args[0]->as_string;
    $self->{'raw_output'} .= "$line\n" if !$self->{'tr_opts'}->{'step_results'};

    #try to pick out the filename if we are running this on TAP in files

    #old prove
    if ($line =~ /^Running\s(.*)/) {
        #TODO figure out which testsuite this implies
        $self->{'file'} = $1;
        print "PROCESSING RESULTS FROM TEST FILE: $self->{'file'}\n";
    }
    #RAW tap #XXX this regex could be improved
    if ($line =~ /(.*)\s\.\.\s*$/) {
        $self->{'file'} = $1 unless $line =~ /^[ok|not ok] - /; #a little more careful
    }
    print "$line\n" if ($line =~ /^error/i);
}

=head2 commentCallback

Grabs comments preceding a test so that we can include that as the test's notes.
Especially useful when merge=1 is passed to the constructor.

=cut

# Register the current suite or test desc for use by test callback, if the line begins with the special magic words
sub commentCallback {
    my (@args) = @_;
    our $self;
    my $line = $args[0]->as_string;
    $self->{'raw_output'} .= "$line\n" if !$self->{'tr_opts'}->{'step_results'};

    if ($line =~ m/^#TESTDESC:\s*/) {
        $self->{'tr_opts'}->{'test_desc'} = $line;
        $self->{'tr_opts'}->{'test_desc'} =~ s/^#TESTDESC:\s*//g;
        return;
    }

    #keep all comments before a test that aren't these special directives to save in NOTES field of reportTCResult
    $self->{'tr_opts'}->{'test_notes'} .= "$line\n";
}

=head2 testCallback

If we are using step_results, append it to the step results array for use at EOF.
If we are using case_per_ok, update TestRail per case.
Otherwise, do nothing.

=cut

sub testCallback {
    my (@args) = @_;
    my $test = $args[0];
    our $self;

    if ( $self->{'track_time'} ) {
        #Test done.  Record elapsed time.
        $self->{'tr_opts'}->{'result_options'}->{'elapsed'} = _compute_elapsed($self->{'starttime'},time());
    }

    #Don't do anything if we don't want to map TR case => ok or use step-by-step results
    if ( !($self->{'tr_opts'}->{'step_results'} || $self->{'tr_opts'}->{'case_per_ok'}) ) {
        print "Neither step_results of case_per_ok set.  No action to be taken, except on a whole test basis.\n" if $self->{'tr_opts'}->{'debug'};
        return 1;
    }
    if ($self->{'tr_opts'}->{'step_results'} && $self->{'tr_opts'}->{'case_per_ok'}) {
        cluck("ERROR: step_options and case_per_ok options are mutually exclusive!");
        $self->{'errors'}++;
        return 0;
    }
    #Fail on unplanned tests
    if ($test->is_unplanned()) {
        cluck("ERROR: Unplanned test detected.  Will not attempt to upload results.");
        $self->{'errors'}++;
        return 0;
    }

    #Default assumption is that case name is step text (case_per_ok), unless...
    my $line = $test->as_string;
    $self->{'raw_output'} .= "$line\n" if !$self->{'tr_opts'}->{'step_results'};

    $line =~ s/^(ok|not ok)\s[0-9]*\s-\s//g;
    my $test_name  = $line;
    my $run_id     = $self->{'tr_opts'}->{'run_id'};

    print "Assuming test name is '$test_name'...\n" if $self->{'tr_opts'}->{'debug'} && !$self->{'tr_opts'}->{'step_results'};

    my $todo_reason;
    #Setup args to pass to function
    my $status = $self->{'tr_opts'}->{'not_ok'}->{'id'};
    if ($test->is_actual_ok()) {
        $status = $self->{'tr_opts'}->{'ok'}->{'id'};
        if ($test->has_skip()) {
            $status = $self->{'tr_opts'}->{'skip'}->{'id'};
            $test_name =~ s/^(ok|not ok)\s[0-9]*\s//g;
            $test_name =~ s/^# skip //gi;
        }
        if ($test->has_todo()) {
            $status = $self->{'tr_opts'}->{'todo_pass'}->{'id'};
            $test_name =~ s/^(ok|not ok)\s[0-9]*\s//g;
            $test_name =~ s/(^# todo & skip )//gi; #handle todo_skip
            $test_name =~ s/ # todo\s(.*)$//gi;
            $todo_reason = $1;
        }
    } else {
        if ($test->has_todo()) {
            $status = $self->{'tr_opts'}->{'todo_pass'}->{'id'};
            $test_name =~ s/^(ok|not ok)\s[0-9]*\s//g;
            $test_name =~ s/^# todo & skip //gi; #handle todo_skip
            $test_name =~ s/# todo\s(.*)$//gi;
            $todo_reason = $1;
        }
    }

    #If this is a TODO, set the reason in the notes
    $self->{'tr_opts'}->{'test_notes'} .= "\nTODO reason: $todo_reason\n" if $todo_reason;

    #Setup step options and exit if that's the mode we be rollin'
    if ($self->{'tr_opts'}->{'step_results'}) {
        $self->{'tr_opts'}->{'result_custom_options'} = {} if !defined $self->{'tr_opts'}->{'result_custom_options'};
        $self->{'tr_opts'}->{'result_custom_options'}->{'step_results'} = [] if !defined $self->{'tr_opts'}->{'result_custom_options'}->{'step_results'};
        #XXX Obviously getting the 'expected' and 'actual' from the tap DIAGs would be ideal
        push(
            @{$self->{'tr_opts'}->{'result_custom_options'}->{'step_results'}},
            TestRail::API::buildStepResults($line,"Good result","Bad Result",$status)
        );
        print "Appended step results.\n" if $self->{'tr_opts'}->{'debug'};
        return 1;
    }

    #Optional args
    my $notes          = $self->{'tr_opts'}->{'test_notes'};
    my $options        = $self->{'tr_opts'}->{'result_options'};
    my $custom_options = $self->{'tr_opts'}->{'result_custom_options'};

    _set_result($run_id,$test_name,$status,$notes,$options,$custom_options);
    #Re-start the shot clock
    $self->{'starttime'} = time();

    #Blank out test description in anticipation of next test
    # also blank out notes
    $self->{'tr_opts'}->{'test_notes'} = undef;
    $self->{'tr_opts'}->{'test_desc'} = undef;
}

=head2 EOFCallback

If we are running in step_results mode, send over all the step results to TestRail.
If we are running in case_per_ok mode, do nothing.
Otherwise, upload the overall results of the test to TestRail.

=cut

sub EOFCallback {
    our $self;

    if ( $self->{'track_time'} ) {
        #Test done.  Record elapsed time.
        $self->{'tr_opts'}->{'result_options'}->{'elapsed'} = _compute_elapsed($self->{'starttime'},time());
    }

    if ($self->{'tr_opts'}->{'case_per_ok'}) {
        print "Nothing left to do.\n";
        undef $self->{'tr_opts'} unless $self->{'tr_opts'}->{'debug'};
        return 1;
    }

    #Fail if the file is not set
    if (!defined($self->{'file'})) {
        cluck("ERROR: Cannot detect filename, will not be able to find a Test Case with that name");
        $self->{'errors'}++;
        return 0;
    }

    my $run_id     = $self->{'tr_opts'}->{'run_id'};
    my $test_name  = basename($self->{'file'});

    my $status = $self->{'tr_opts'}->{'ok'}->{'id'};
    $status = $self->{'tr_opts'}->{'not_ok'}->{'id'} if $self->has_problems();
    $status = $self->{'tr_opts'}->{'skip'}->{'id'} if $self->skip_all();

    #Optional args
    my $notes          = $self->{'tr_opts'}->{'test_notes'};
    $notes = $self->{'raw_output'} if !$self->{'tr_opts'}->{'step_results'};
    my $options        = $self->{'tr_opts'}->{'result_options'};
    my $custom_options = $self->{'tr_opts'}->{'result_custom_options'};


    print "Setting results...\n";
    my $cres = _set_result($run_id,$test_name,$status,$notes,$options,$custom_options);

    undef $self->{'tr_opts'} unless $self->{'tr_opts'}->{'debug'};

    return $cres;
}

sub _set_result {
    my ($run_id,$test_name,$status,$notes,$options,$custom_options) = @_;
    our $self;
    my $tc;

    print "Test elapsed: ".$options->{'elapsed'}."\n" if $options->{'elapsed'};

    print "Attempting to find case by title '".$test_name."'...\n";
    $tc = $self->{'tr_opts'}->{'testrail'}->getTestByName($run_id,$test_name);
    if (!defined($tc) || (reftype($tc) || 'undef') ne 'HASH') {
        cluck("ERROR: Could not find test case: $tc");
        $self->{'errors'}++;
        return 0;
    }
    my $xid = $tc ? $tc->{'id'} : '???';

    my $cres;

    #Set test result
    if ($tc) {
        print "Reporting result of case $xid in run $self->{'tr_opts'}->{'run_id'} as status '$status'...";
        # createTestResults(test_id,status_id,comment,options,custom_options)
        $cres = $self->{'tr_opts'}->{'testrail'}->createTestResults($tc->{'id'},$status, $notes, $options, $custom_options);
        print "OK! (set to $status)\n" if (reftype($cres) || 'undef') eq 'HASH';
    }
    if (!$tc || ((reftype($cres) || 'undef') ne 'HASH') ) {
        print "Failed!\n";
        print "No Such test case in TestRail ($xid).\n";
        $self->{'errors'}++;
    }

}

#Compute the expected testrail date interval from 2 unix timestamps.
sub _compute_elapsed {
    my ($begin,$end)  = @_;
    my $secs_elapsed  = $end - $begin;
    my $mins_elapsed  = floor($secs_elapsed / 60);
    my $secs_remain   = $secs_elapsed % 60;
    my $hours_elapsed = floor($mins_elapsed / 60);
    my $mins_remain   = $mins_elapsed % 60;

    my $datestr = "";

    #You have bigger problems if your test takes days
    if ($hours_elapsed) {
        $datestr .= "$hours_elapsed"."h $mins_remain"."m";
    } else {
        $datestr .= "$mins_elapsed"."m";
    }
    if ($mins_elapsed) {
        $datestr .= " $secs_remain"."s";
    } else {
        $datestr .= " $secs_elapsed"."s";
    }
    undef $datestr if $datestr eq "0m 0s";
    return $datestr;
}

1;

__END__

=head1 NOTES

When using SKIP: {} (or TODO skip) blocks, you may want to consider naming your skip reasons the same as your test names when running in test_per_ok mode.

=head1 SEE ALSO

L<TestRail::API>

L<TAP::Parser>

=head1 SPECIAL THANKS

Thanks to cPanel Inc, for graciously funding the creation of this module.
