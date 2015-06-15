# ABSTRACT: Upload your TAP results to TestRail in realtime
# PODNAME: App::Prove::Plugin::TestRail

package App::Prove::Plugin::TestRail;

use strict;
use warnings;
use utf8;

use File::HomeDir qw{my_home};
use TestRail::Utils;

=head1 SYNOPSIS

`prove -PTestRail='apiurl=http://some.testlink.install/,user=someUser,password=somePassword,project=TestProject,run=TestRun,plan=TestPlan,configs=Config1:Config2:Config3,version=0.014' sometest.t`

=cut

=head1 DESCRIPTION

Prove plugin to upload test results to TestRail installations.

Accepts input in the standard Prove plugin fashion (-Ppluginname='key=value,key=value,key=value...'), but will also parse a config file.
When fed in prove plugin style, key=value input is expected.

If \$HOME/.testrailrc exists, it will be parsed for any of these values in a newline separated key=value list.  Example:

    apiurl=http://some.testrail.install
    user=someGuy
    password=superS3cret
    project=TestProject
    run=TestRun
    plan=GosPlan
    configs=config1:config2:config3: ... :configN
    version=xx.xx.xx.xx
    case_per_ok=0
    step_results=sr_sys_name
    spawn=123
    sections=section1:section2:section3: ... :sectionN
    autoclose=0

Note that passing configurations as filters for runs inside of plans are separated by colons.
Values passed in via query string will override values in \$HOME/.testrailrc.
If your system has no concept of user homes, it will look in the current directory for .testrailrc.

See the documentation for the constructor of L<Test::Rail::Parser> as to why you might want to pass the aforementioned options.

=head1 OVERRIDDEN METHODS

=head2 load(parser)

Shoves the arguments passed to the prove plugin into $ENV so that Test::Rail::Parser can get at them.
Not the most elegant solution, but I see no other clear path to get those variables downrange to it's constructor.

=cut

sub load {
    my ($class, $p) = @_;

    my $app = $p->{app_prove};
    my $args = $p->{'args'};

    my $params = {};

    #Only attempt parse if we aren't mocking and the homedir exists
    my $homedir = my_home() || '.';
    $params = TestRail::Utils::parseConfig($homedir) if -e $homedir && !$ENV{'TESTRAIL_MOCKED'};

    my @kvp = ();
    my ($key,$value);
    foreach my $arg (@$args) {
        @kvp = split(/=/,$arg);
        if (scalar(@kvp) < 2) {
            print "Unrecognized Argument '$arg' to App::Prove::Plugin::Testrail, ignoring\n";
            next;
        }
        $key = shift @kvp;
        $value = join('',@kvp);
        $params->{$key} = $value;
    }

    $app->harness('Test::Rail::Harness');
    $app->merge(1);

    #XXX I can't figure out for the life of me any other way to pass this data. #YOLO
    $ENV{'TESTRAIL_APIURL'}    = $params->{apiurl};
    $ENV{'TESTRAIL_USER'}      = $params->{user};
    $ENV{'TESTRAIL_PASS'}      = $params->{password};
    $ENV{'TESTRAIL_PROJ'}      = $params->{project};
    $ENV{'TESTRAIL_RUN'}       = $params->{run};
    $ENV{'TESTRAIL_PLAN'}      = $params->{plan};
    $ENV{'TESTRAIL_CONFIGS'}   = $params->{configs};
    $ENV{'TESTRAIL_VERSION'}   = $params->{version};
    $ENV{'TESTRAIL_CASEOK'}    = $params->{case_per_ok};
    $ENV{'TESTRAIL_STEPS'}     = $params->{step_results};
    $ENV{'TESTRAIL_SPAWN'}     = $params->{spawn};
    $ENV{'TESTRAIL_SECTIONS'}  = $params->{sections};
    $ENV{'TESTRAIL_AUTOCLOSE'} = $params->{autoclose};
    return $class;
}

1;

__END__

=head1 SEE ALSO

L<TestRail::API>

L<Test::Rail::Parser>

L<App::Prove>

L<File::HomeDir> for the finding of .testrailrc

=head1 SPECIAL THANKS

Thanks to cPanel Inc, for graciously funding the creation of this module.
