use strict;
use warnings;

use Test::More 'tests' => 8;
use Test::Fatal;
use TestRail::Utils;
use File::Basename qw{dirname};

my ($apiurl,$user,$password);

#check the binary output mode
is(exception {($apiurl,$password,$user) = TestRail::Utils::parseConfig(dirname(__FILE__),1)}, undef, "No exceptions thrown by parseConfig in array mode");
is($apiurl,'http://hokum.bogus',"APIURL parse OK");
is($user,'zippy',"USER parse OK");
is($password, 'happy', 'PASSWORD parse OK');

my $out;
is(exception {$out = TestRail::Utils::parseConfig(dirname(__FILE__))}, undef, "No exceptions thrown by parseConfig default mode");
is($out->{apiurl},'http://hokum.bogus',"APIURL parse OK");
is($out->{user},'zippy',"USER parse OK");
is($out->{password}, 'happy', 'PASSWORD parse OK');


#Regrettably, I have yet to find a way to print to stdin without eval, so userInput will remain untested.
