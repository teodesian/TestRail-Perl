use strict;
use warnings;

use Test::More 'tests' => 4;
use Test::Fatal;
use TestRail::Utils;
use File::Basename qw{dirname};

my ( $apiurl, $user, $password );
is(
    exception {
        ( $apiurl, $password, $user ) =
          TestRail::Utils::parseConfig( dirname(__FILE__) )
    },
    undef,
    "No exceptions thrown by parseConfig"
);
is( $apiurl,   'http://hokum.bogus', "APIURL parse OK" );
is( $user,     'zippy',              "USER parse OK" );
is( $password, 'happy',              'PASSWORD parse OK' );

#Regrettably, I have yet to find a way to print to stdin without eval, so userInput will remain untested.
