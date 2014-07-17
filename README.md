TestRail-Perl
=============

Perl interface to TestRail's REST API

Doesn't implement every method provided (yet), just the ones *I* needed:

* Making Projects,Suites,Sections,Cases,Plans and Runs
* Getting the same
* Deleting the same
* Setting test run statuses

Basically everything needed to sync up automated test runs to the test management DB.
TODO: alter tests so that you can keep in sync.

> my $url = "http://some.testrail.install/";
> 
> my $user = 'JohnDoe';
> 
> my $pw = 'password';
> 
> my $apiClient = new TestLink::API($url,$user,$pass);

See POD for more info.
