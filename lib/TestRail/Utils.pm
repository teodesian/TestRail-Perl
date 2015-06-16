# ABSTRACT: Utilities for the testrail command line functions.
# PODNAME: TestRail::Utils

package TestRail::Utils;
$TestRail::Utils::VERSION = '0.028';
use strict;
use warnings;

sub userInput {
    local $| = 1;
    my $rt = <STDIN>;
    chomp $rt;
    return $rt;
}

sub parseConfig {
    my ( $homedir, $login_only ) = @_;
    my $results = {};
    my $arr     = [];

    open( my $fh, '<', $homedir . '/.testrailrc' )
      or return ( undef, undef, undef );    #couldn't open!
    while (<$fh>) {
        chomp;
        @$arr = split( /=/, $_ );
        if ( scalar(@$arr) != 2 ) {
            warn("Could not parse $_ in '$homedir/.testrailrc'!\n");
            next;
        }
        $results->{ lc( $arr->[0] ) } = $arr->[1];
    }
    close($fh);
    return ( $results->{'apiurl'}, $results->{'password'}, $results->{'user'} )
      if $login_only;
    return $results;
}

sub getFilenameFromTapLine {
    my $orig = shift;

    $orig =~ s/ *$//g;    # Strip all trailing whitespace

    #Special case
    my ($is_skipall) = $orig =~ /(.*)\.+ skipped:/;
    return $is_skipall if $is_skipall;

    my @process_split = split( / /, $orig );
    return 0 unless scalar(@process_split);
    my $dotty =
      pop @process_split;    #remove the ........ (may repeat a number of times)
    return 0
      if $dotty =~
      /\d/;  #Apparently looking for literal dots returns numbers too. who knew?
    chomp $dotty;
    my $line = join( ' ', @process_split );

    #IF it ends in a bunch of dots
    #AND it isn't an ok/not ok
    #AND it isn't a comment
    #AND it isn't blank
    #THEN it's a test name

    return $line
      if ( $dotty =~ /^\.+$/
        && !( $line =~ /^ok|not ok/ )
        && !( $line =~ /^# / )
        && $line );
    return 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

TestRail::Utils - Utilities for the testrail command line functions.

=head1 VERSION

version 0.028

=head1 DESCRIPTION

Utilities for the testrail command line functions.

=head1 FUNCTIONS

=head2 userInput

Wait for user input and return it.

=head2 parseConfig(homedir)

Parse .testrailrc in the provided home directory.

Returns:

ARRAY - (apiurl,password,user)

=head2 getFilenameFromTAPLine($line)

Analyze TAP output by prove and look for filename boundaries (no other way to figure out what file is run).
Long story short: don't end 'unknown' TAP lines with any number of dots if you don't want it interpreted as a test name.
Apparently this is the TAP way of specifying the file that's run...which is highly inadequate.

Inputs:

STRING LINE - some line of TAP

Returns:

STRING filename of the test that output the TAP.

=head1 SPECIAL THANKS

Thanks to cPanel Inc, for graciously funding the creation of this module.

=head1 AUTHOR

George S. Baugh <teodesian@cpan.org>

=head1 SOURCE

The development version is on github at L<http://github.com/teodesian/TestRail-Perl>
and may be cloned from L<git://github.com/teodesian/TestRail-Perl.git>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by George S. Baugh.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
