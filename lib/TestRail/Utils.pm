# ABSTRACT: Utilities for the testrail command line functions.
# PODNAME: TestRail::Utils

package TestRail::Utils;
$TestRail::Utils::VERSION = '0.023';
use strict;
use warnings;

sub userInput {
    local $| = 1;
    my $rt = <STDIN>;
    chomp $rt;
    return $rt;
}

sub parseConfig {
    my $homedir = shift;
    my $results = {};
    my $arr     = [];

    open( my $fh, '<', $homedir . '/.testrailrc' )
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
    return ( $results->{'apiurl'}, $results->{'password'}, $results->{'user'} );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

TestRail::Utils - Utilities for the testrail command line functions.

=head1 VERSION

version 0.023

=head1 DESCRIPTION

Utilities for the testrail command line functions.

=head1 FUNCTIONS

=head2 userInput

Wait for user input and return it.

=head2 parseConfig(homedir)

Parse .testrailrc in the provided home directory.

Returns:

ARRAY - (apiurl,password,user)

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
