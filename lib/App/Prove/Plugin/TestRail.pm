# ABSTRACT: Upload your TAP results to TestRail in realtime
# PODNAME: App::Prove::Plugin::TestRail

package App::Prove::Plugin::TestRail;
$App::Prove::Plugin::TestRail::VERSION = '0.012';
use strict;
use warnings;
use utf8;

sub load {
    my ( $class, $p ) = @_;

    my ( $apiurl, $password, $user, $project, $run, $case_per_ok,
        $step_results ) = _parseConfig();

    my $app  = $p->{app_prove};
    my $args = $p->{'args'};

    $apiurl   //= shift @$args;
    $user     //= shift @$args;
    $password //= shift @$args;
    $project  //= shift @$args;
    $run      //= shift @$args;

    $case_per_ok  //= shift @$args;
    $step_results //= shift @$args;

    $app->harness('Test::Rail::Harness');
    $app->merge(1);

    #XXX I can't figure out for the life of me any other way to pass this data. #YOLO
    $ENV{'TESTRAIL_APIURL'} = $apiurl;
    $ENV{'TESTRAIL_USER'}   = $user;
    $ENV{'TESTRAIL_PASS'}   = $password;
    $ENV{'TESTRAIL_PROJ'}   = $project;
    $ENV{'TESTRAIL_RUN'}    = $run;
    $ENV{'TESTRAIL_CASEOK'} = $case_per_ok;
    $ENV{'TESTRAIL_STEPS'}  = $step_results;
    return $class;
}

sub _parseConfig {
    my $results = {};
    my $arr     = [];

    open( my $fh, '<', $ENV{"HOME"} . '/.testrailrc' )
      or return ( undef, undef, undef );    #couldn't open!
    while (<$fh>) {
        chomp;
        @$arr = split( /=/, $_ );
        if ( scalar(@$arr) != 2 ) {
            warn("Could not parse $_ in tlreport config\n");
            next;
        }
        $results->{ lc( $arr->[0] ) } = $arr->[1];
    }
    close($fh);
    return (
        $results->{'apiurl'}, $results->{'password'},
        $results->{'user'},   $results->{'project'},
        $results->{'run'},    $results->{'case_per_ok'},
        $results->{'step_results'}
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Prove::Plugin::TestRail - Upload your TAP results to TestRail in realtime

=head1 VERSION

version 0.012

=head1 SYNOPSIS

`prove -PTestRail='http://some.testlink.install/,someUser,somePassword,TestProject,TestRun' sometest.t`

=head1 DESCRIPTION

Prove plugin to upload test results to TestRail installations.

Accepts input in the standard Prove plugin fashion (-Ppluginname=value,value,value...), but will also parse a config file.

If ~/.testrailrc exists, it will be parsed for any of these values in a newline separated key=value list.  Example:

    apiurl=http://some.testrail.install
    user=someGuy
    password=superS3cret
    project=TestProject
    run=TestRun
    case_per_ok=0
    step_results=sr_sys_name

Be aware that if you do so, it will look for any unsatisfied arguments in the order of their appearance above.

=head1 OVERRIDDEN METHODS

=head2 load(parser)

Shoves the arguments passed to the prove plugin into $ENV so that Test::Rail::Parser can get at them.
Not the most elegant solution, but I see no other clear path to get those variables downrange to it's constructor.

=head1 SEE ALSO

L<TestRail::API>

L<Test::Rail::Parser>

L<App::Prove>

=head1 SPECIAL THANKS

Thanks to cPanel Inc, for graciously funding the creation of this module.

=head1 AUTHOR

George S. Baugh <teodesian@cpan.org>

=head1 SOURCE

The development version is on github at L<http://github.com/teodesian/TestRail-Perl>
and may be cloned from L<git://github.com/teodesian/TestRail-Perl.git>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by George S. Baugh.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
