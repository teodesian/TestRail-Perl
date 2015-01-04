use strict;
use warnings;

use TestRail::API;
use Test::More;
use Test::Fatal;
use Class::Inspector;

plan('skip_all' => "these tests are for testing by the author") unless $ENV{'AUTHOR_TESTING'};

my $tr = TestRail::API->new('http://hokum.bogus','bogus','bogus',1);

#Call instance methods as class and vice versa
like( exception {$tr->new();}, qr/.*must be called statically.*/, "Calling constructor on instance dies");

my @methods = Class::Inspector->methods('TestRail::API');
my @excludeModules = qw{Scalar::Util Carp Clone Try::Tiny HTTP::Request LWP::UserAgent Data::Validate::URI};
my @tmp = ();
my @excludedMethods = ();
foreach my $module (@excludeModules) {
    @tmp = Class::Inspector->methods($module);
    push(@excludedMethods,@{$tmp[0]});
}

foreach my $method (@{$methods[0]}) {
    next if grep {$method eq $_} qw{new buildStepResults _checkInteger _checkString};
    next if grep {$_ eq $method} @excludedMethods;
    like( exception {TestRail::API->$method}, qr/.*called by an instance.*/ , "Calling $method requires an instance");
}

done_testing();
