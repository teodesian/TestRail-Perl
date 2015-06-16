use strict;
use warnings;

use Test::More 'tests' => 10;
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

#Handle both the case where we do in sequence or in paralell and mash together logs

my @files;
my $fcontents = '';
open(my $fh,'<','t/test_multiple_files.tap') or die("couldn't open our own test files!!!");
while (<$fh>) {
    if (TestRail::Utils::getFilenameFromTapLine($_)) {
        push(@files,$fcontents) if $fcontents;
        $fcontents = '';
    }
    $fcontents .= $_;
}
close($fh);
push(@files,$fcontents);
is(scalar(@files),2,"Detects # of filenames correctly in TAP");

$fcontents = '';
@files = ();
open($fh,'<','t/seq_multiple_files.tap') or die("couldn't open our own test files!!!");
while (<$fh>) {
    if (TestRail::Utils::getFilenameFromTapLine($_)) {
        push(@files,$fcontents) if $fcontents;
        $fcontents = '';
    }
    $fcontents .= $_;
}
close($fh);
push(@files,$fcontents);
is(scalar(@files),7,"Detects # of filenames correctly in TAP");


#Regrettably, I have yet to find a way to print to stdin without eval, so userInput will remain untested.
