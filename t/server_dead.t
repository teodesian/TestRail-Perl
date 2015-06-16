#Test behavior if the server magically disappears
#Basically the policy is no death, return false when this happens.

use strict;
use warnings;

use TestRail::API;
use Test::More 'tests' => 54;
use Test::Fatal;
use Class::Inspector;
use Test::LWP::UserAgent;
use HTTP::Response;

my $tr = TestRail::API->new('http://hokum.bogus','bogus','bogus',1);
$tr->{'browser'} = Test::LWP::UserAgent->new();
$tr->{'browser'}->map_response(qr/.*/, HTTP::Response->new('500', 'ERROR', ['Content-Type' => 'text/plain'], ''));

is( $tr->_doRequest('badMethod'), -500,"Bad Request fails");

is($tr->apiurl,'http://hokum.bogus',"APIURL OK");
is($tr->debug,1,"DEBUG OK");

is($tr->createCase(1,'whee',1),-500,'createCase returns error');
is($tr->createMilestone(1,'whee'),-500,'createMilestone returns error');
is($tr->createPlan(1,'whee'),-500,'createPlan returns error');
is($tr->createProject('zippy'),-500,'createProject returns error');
is($tr->createRun(1,1,'whee'),-500,'createRun returns error');
is($tr->createSection(1,1,'whee'),-500,'createSection returns error');
is($tr->createTestResults(1,1),-500,'createTestResults returns error');
is($tr->createTestSuite(1,'zugzug'),-500,'createTestSuite returns error');
is($tr->deleteCase(1),-500,'deleteCase returns error');
is($tr->deleteMilestone(1),-500,'deleteMilestone returns error');
is($tr->deletePlan(1),-500,'deletePlan returns error');
is($tr->deleteProject(1),-500,'deleteProject returns error');
is($tr->deleteRun(1),-500,'deleteRun returns error');
is($tr->deleteSection(1),-500,'deleteSection returns error');
is($tr->deleteTestSuite(1),-500,'deleteTestSuite returns error');
is($tr->getCaseByID(1),-500,'getCaseByID returns error');
is($tr->getCaseByName(1,1,1,'hug'),-500,'getCaseByName returns error');
is($tr->getCaseTypeByName('zap'),-500,'getCaseTypeByName returns error');
is($tr->getCaseTypes(),-500,'getCaseTypes returns error');
is($tr->getCases(1,2,3),-500,'getCases returns error');
is($tr->getMilestoneByID(1,1),-500,'getMilestoneByID returns error');
is($tr->getMilestoneByName(1,'hug'),-500,'getMilestoneByName returns error');
is($tr->getMilestones(1),-500,'getMilestones returns error');
is($tr->getPlanByID(1),-500,'getPlanByID returns error');
is($tr->getPlanByName(1,'nugs'),-500,'getPlanByName returns error');
is($tr->getPlans(1),-500,'getPlans returns error');
is($tr->getPossibleTestStatuses(),-500,'getPossibleTestStatuses returns error');
is($tr->getProjectByID(1),-500,'getProjectByID returns error');
is($tr->getProjectByName('fake'),-500,'getProjectByName returns error');
is($tr->getProjects(),-500,'getProjects returns error');
is($tr->getRunByID(1),-500,'getRunByID returns error');
is($tr->getRunByName(1,'zoom'),-500,'getRunByName returns error');
is($tr->getRuns(1),-500,'getRuns returns error');
is($tr->getSectionByID(1),-500,'getSectionByID returns error');
is($tr->getSectionByName(1,1,'zip'),-500,'getSectionByName returns error');
is($tr->getSections(1,1),-500,'getSections returns error');
is($tr->getTestByID(1),-500,'getTestByID returns error');
is($tr->getTestByName(1,'poo'),-500,'getTestByName returns error');
is($tr->getTestResultFields(),-500,'getTestResultFields returns error');
is($tr->getTestResults(1,1),-500,'getTestResults returns error');
is($tr->getTestSuiteByID(1),-500,'getTestSuiteByID returns error');
is($tr->getTestSuiteByName(1,'zap'),-500,'getTestSuiteByName returns error');
is($tr->getTestSuites(1),-500,'getTestSuites returns error');
is($tr->getTests(1),-500,'getTests returns error');
is($tr->getUserByEmail('tickle'),0,'getUserByEmail returns error');
is($tr->getUserByID(1),0,'getUserByID returns error');
is($tr->getUserByName('zap'),0,'getUserByName returns error');
is($tr->getUsers(),-500,'getUsers returns error');
is($tr->getConfigurations(1),-500,'getConfigurations returns error');
is($tr->closePlan(1),-500,'closePlan returns error');
is($tr->closeRun(1),-500,'closeRun returns error');
