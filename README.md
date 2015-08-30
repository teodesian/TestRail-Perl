TestRail::API
=============

Perl interface to TestRail's REST API

<img alt="TravisCI Build Status" src="https://travis-ci.org/teodesian/TestRail-Perl.svg"></img>
<a href='https://coveralls.io/r/teodesian/TestRail-Perl?branch=build%2Fmaster'><img src='https://coveralls.io/repos/teodesian/TestRail-Perl/badge.svg?branch=build%2Fmaster' alt='Coverage Status' /></a>
<a href="http://cpants.cpanauthors.org/dist/TestRail-API"><img alt="kwalitee" src="http://cpants.cpanauthors.org/dist/TestRail-API.png"></img></a>

Implements most available TestRail API methods:

* Making Projects,Suites,Sections,Cases,Plans and Runs
* Getting the same
* Deleting the same
* Setting test run statuses

Basically everything needed to sync up automated test runs to the test management DB.
Also has convenience methods to handle various limitations of the API.

> my $url = "http://some.testrail.install/";
> 
> my $user = 'JohnDoe';
> 
> my $pw = 'password';
> 
> my $apiClient = new TestRail::API($url,$user,$pass);

Also provides a prove plugin and TAP analyzer so that you can upload results on-the-fly or after it's logged to a file.

As of version 0.019, it also supports automated creation of builds (for use in a CI sort of arrangement).

TODO: alter tests so that you can keep in sync.

See POD for more info.
