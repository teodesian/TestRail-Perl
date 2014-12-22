#Test behavior if the server magically disappears
#Basically the policy is no death, return false when this happens.

use strict;
use warnings;

use TestRail::API;
use Test::More 'tests' => 51;
use Test::Fatal;
use Class::Inspector;

my $tr = TestRail::API->new('http://hokum.bogus','bogus','bogus',1);

note $tr->_doRequest('badMethod');
is( $tr->_doRequest('badMethod'), -500,"Bad Request fails");

is($tr->apiurl,'http://hokum.bogus',"APIURL OK");
is($tr->debug,1,"DEBUG OK");

is($tr->createCase(),-500,'createCase returns error');
is($tr->createMilestone(),-500,'createMilestone returns error');
is($tr->createPlan(),-500,'createPlan returns error');
is($tr->createProject(),-500,'createProject returns error');
is($tr->createRun(),-500,'createRun returns error');
is($tr->createSection(),-500,'createSection returns error');
is($tr->createTestResults(),-500,'createTestResults returns error');
is($tr->createTestSuite(),-500,'createTestSuite returns error');
is($tr->deleteCase(),-500,'deleteCase returns error');
is($tr->deleteMilestone(),-500,'deleteMilestone returns error');
is($tr->deletePlan(),-500,'deletePlan returns error');
is($tr->deleteProject(),-500,'deleteProject returns error');
is($tr->deleteRun(),-500,'deleteRun returns error');
is($tr->deleteSection(),-500,'deleteSection returns error');
is($tr->deleteTestSuite(),-500,'deleteTestSuite returns error');
is($tr->getCaseByID(),-500,'getCaseByID returns error');
is($tr->getCaseByName(),-500,'getCaseByName returns error');
is($tr->getCaseTypeByName(),-500,'getCaseTypeByName returns error');
is($tr->getCaseTypes(),-500,'getCaseTypes returns error');
is($tr->getCases(),-500,'getCases returns error');
is($tr->getMilestoneByID(),-500,'getMilestoneByID returns error');
is($tr->getMilestoneByName(),-500,'getMilestoneByName returns error');
is($tr->getMilestones(),-500,'getMilestones returns error');
is($tr->getPlanByID(),-500,'getPlanByID returns error');
is($tr->getPlanByName(),-500,'getPlanByName returns error');
is($tr->getPlans(),-500,'getPlans returns error');
is($tr->getPossibleTestStatuses(),-500,'getPossibleTestStatuses returns error');
is($tr->getProjectByID(1),-500,'getProjectByID returns error');
is($tr->getProjectByName('fake'),-500,'getProjectByName returns error');
is($tr->getProjects(),-500,'getProjects returns error');
is($tr->getRunByID(),-500,'getRunByID returns error');
is($tr->getRunByName(),-500,'getRunByName returns error');
is($tr->getRuns(),-500,'getRuns returns error');
is($tr->getSectionByID(),-500,'getSectionByID returns error');
is($tr->getSectionByName(),-500,'getSectionByName returns error');
is($tr->getSections(),-500,'getSections returns error');
is($tr->getTestByID(),-500,'getTestByID returns error');
is($tr->getTestByName(),-500,'getTestByName returns error');
is($tr->getTestResultFields(),-500,'getTestResultFields returns error');
is($tr->getTestResults(),-500,'getTestResults returns error');
is($tr->getTestSuiteByID(),-500,'getTestSuiteByID returns error');
is($tr->getTestSuiteByName(),-500,'getTestSuiteByName returns error');
is($tr->getTestSuites(),-500,'getTestSuites returns error');
is($tr->getTests(),-500,'getTests returns error');
is($tr->getUserByEmail(),0,'getUserByEmail returns error');
is($tr->getUserByID(),0,'getUserByID returns error');
is($tr->getUserByName(),0,'getUserByName returns error');
is($tr->getUsers(),-500,'getUsers returns error');
