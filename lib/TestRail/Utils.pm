# ABSTRACT: Utilities for the testrail commandline functions.
# PODNAME: TestRail::Utils

package TestRail::Utils;

=head1 DESCRIPTION

Utilities for the testrail commandline functions.

=cut

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

=head2 parseConfig($homedir)

Parse .testrailrc in the provided homedir.

Returns:

ARRAY - (apiurl,password,user)

=cut

sub parseConfig {
    my $homedir = shift;
    my $results = {};
    my $arr =[];

    open(my $fh, '<', $homedir . '/.testrailrc') or return (undef,undef,undef);#couldn't open!
    while (<$fh>) {
        chomp;
        @$arr = split(/=/,$_);
        if (scalar(@$arr) != 2) {
            warn("Could not parse $_ in tlreport config\n");
            next;
        }
        $results->{lc($arr->[0])} = $arr->[1];
    }
    close($fh);
    return ($results->{'apiurl'},$results->{'password'},$results->{'user'});
}

1;

__END__

=head1 SPECIAL THANKS

Thanks to cPanel Inc, for graciously funding the creation of this module.
