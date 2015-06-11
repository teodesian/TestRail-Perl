# ABSTRACT: Utilities for the testrail command line functions.
# PODNAME: TestRail::Utils

=head1 DESCRIPTION

Utilities for the testrail command line functions.

=cut

package TestRail::Utils;

use strict;
use warnings;

=head1 FUNCTIONS

=head2 userInput

Wait for user input and return it.

=cut

sub userInput {
 local $| = 1;
 my $rt = <STDIN>;
 chomp $rt;
 return $rt;
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

1;

__END__

=head1 SPECIAL THANKS

Thanks to cPanel Inc, for graciously funding the creation of this module.
