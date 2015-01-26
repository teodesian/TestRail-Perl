use strict;
use warnings;

use TestRail::API;
use Test::More 'tests' => 120;
use Test::Fatal;
use Class::Inspector;
use Test::LWP::UserAgent;
use HTTP::Response;

my $tr = TestRail::API->new('http://hokum.bogus','bogus','bogus',1);
$tr->{'browser'} = Test::LWP::UserAgent->new();
$tr->{'browser'}->map_response(qr/.*/, HTTP::Response->new('500', 'ERROR', ['Content-Type' => 'text/plain'], ''));

#No-arg functions
is( exception {$tr->getCaseTypes() },undef,'getCaseTypes returns no error when no arguments are passed');
is( exception {$tr->getPossibleTestStatuses() },undef,'getPossibleTestStatuses returns no error when no arguments are passed');
is( exception {$tr->getProjects() },undef,'getProjects returns no error when no arguments are passed');
is( exception {$tr->getTestResultFields() },undef,'getTestResultFields returns no error when no arguments are passed');
is( exception {$tr->getUsers() },undef,'getUsers returns no error when no arguments are passed');

isnt( exception {$tr->createCase() },undef,'createCase returns error when no arguments are passed');
isnt( exception {$tr->createMilestone() },undef,'createMilestone returns error when no arguments are passed');
isnt( exception {$tr->createPlan() },undef,'createPlan returns error when no arguments are passed');
isnt( exception {$tr->createProject() },undef,'createProject returns error when no arguments are passed');
isnt( exception {$tr->createRun() },undef,'createRun returns error when no arguments are passed');
isnt( exception {$tr->createSection() },undef,'createSection returns error when no arguments are passed');
isnt( exception {$tr->createTestResults() },undef,'createTestResults returns error when no arguments are passed');
isnt( exception {$tr->createTestSuite() },undef,'createTestSuite returns error when no arguments are passed');
isnt( exception {$tr->deleteCase() },undef,'deleteCase returns error when no arguments are passed');
isnt( exception {$tr->deleteMilestone() },undef,'deleteMilestone returns error when no arguments are passed');
isnt( exception {$tr->deletePlan() },undef,'deletePlan returns error when no arguments are passed');
isnt( exception {$tr->deleteProject() },undef,'deleteProject returns error when no arguments are passed');
isnt( exception {$tr->deleteRun() },undef,'deleteRun returns error when no arguments are passed');
isnt( exception {$tr->deleteSection() },undef,'deleteSection returns error when no arguments are passed');
isnt( exception {$tr->deleteTestSuite() },undef,'deleteTestSuite returns error when no arguments are passed');
isnt( exception {$tr->getCaseByID() },undef,'getCaseByID returns error when no arguments are passed');
isnt( exception {$tr->getCaseByName() },undef,'getCaseByName returns error when no arguments are passed');
isnt( exception {$tr->getCaseTypeByName() },undef,'getCaseTypeByName returns error when no arguments are passed');
isnt( exception {$tr->getCases() },undef,'getCases returns error when no arguments are passed');
isnt( exception {$tr->getMilestoneByID() },undef,'getMilestoneByID returns error when no arguments are passed');
isnt( exception {$tr->getMilestoneByName() },undef,'getMilestoneByName returns error when no arguments are passed');
isnt( exception {$tr->getPlanByID() },undef,'getPlanByID returns error when no arguments are passed');
isnt( exception {$tr->getPlanByName() },undef,'getPlanByName returns error when no arguments are passed');
isnt( exception {$tr->getProjectByID() },undef,'getProjectByID returns error when no arguments are passed');
isnt( exception {$tr->getProjectByName() },undef,'getProjectByName returns error when no arguments are passed');
isnt( exception {$tr->getRunByID() },undef,'getRunByID returns error when no arguments are passed');
isnt( exception {$tr->getRunByName() },undef,'getRunByName returns error when no arguments are passed');
isnt( exception {$tr->getSectionByID() },undef,'getSectionByID returns error when no arguments are passed');
isnt( exception {$tr->getSectionByName() },undef,'getSectionByName returns error when no arguments are passed');
isnt( exception {$tr->getTestByID() },undef,'getTestByID returns error when no arguments are passed');
isnt( exception {$tr->getTestByName() },undef,'getTestByName returns error when no arguments are passed');
isnt( exception {$tr->getTestResults() },undef,'getTestResults returns error when no arguments are passed');
isnt( exception {$tr->getTestSuiteByID() },undef,'getTestSuiteByID returns error when no arguments are passed');
isnt( exception {$tr->getTestSuiteByName() },undef,'getTestSuiteByName returns error when no arguments are passed');
isnt( exception {$tr->getUserByEmail() },0,'getUserByEmail returns error when no arguments are passed');
isnt( exception {$tr->getUserByID() },0,'getUserByID returns error when no arguments are passed');
isnt( exception {$tr->getUserByName() },0,'getUserByName returns error when no arguments are passed');
isnt( exception {$tr->getTests() },undef,'getTests returns error when no arguments are passed');
isnt( exception {$tr->getTestSuites() },undef,'getTestSuites returns error when no arguments are passed');
isnt( exception {$tr->getSections() },undef,'getSections returns error when no arguments are passed');
isnt( exception {$tr->getRuns() },undef,'getRuns returns error when no arguments are passed');
isnt( exception {$tr->getPlans() },undef,'getPlans returns error when no arguments are passed');
isnt( exception {$tr->getMilestones() },undef,'getMilestones returns error when no arguments are passed');
isnt( exception {$tr->getConfigurations() },undef,'getConfigurations returns error when no arguments are passed');
isnt( exception {$tr->getChildRuns() },undef,'getChildRuns returns error when no arguments are passed');
isnt( exception {$tr->getChildRunByName() },undef,'getChildRunByName returns error when no arguments are passed');

#1-arg functions
is(exception {$tr->deleteCase(1)},            undef,'deleteCase returns no error when int arg passed');
is(exception {$tr->deleteMilestone(1)},       undef,'deleteMilestone returns no error when int arg passed');
is(exception {$tr->deletePlan(1)},            undef,'deletePlan returns no error when int arg passed');
is(exception {$tr->deleteProject(1)},         undef,'deleteProject returns no error when int arg passed');
is(exception {$tr->deleteRun(1)},             undef,'deleteRun returns no error when int arg passed');
is(exception {$tr->deleteSection(1)},        undef,'deleteSection returns no error when int arg passed');
is(exception {$tr->deleteTestSuite(1)},       undef,'deleteTestSuite returns no error when int arg passed');
is(exception {$tr->getCaseByID(1)},           undef,'getCaseByID returns no error when int arg passed');
is(exception {$tr->getRuns(1)},               undef,'getRuns returns no error when int arg passed');
is(exception {$tr->getSectionByID(1)},        undef,'getSectionByID returns no error when int arg passed');
is(exception {$tr->getTestByID(1)},           undef,'getTestByID returns no error when int arg passed');
is(exception {$tr->getTestSuiteByID(1)},      undef,'getTestSuiteByID returns no error when int arg passed');
is(exception {$tr->getPlans(1)},              undef,'getPlans returns no error when int arg passed');
is(exception {$tr->getProjectByID(1)},        undef,'getProjectByID returns no error when int arg passed');
is(exception {$tr->getRunByID(1)},            undef,'getRunByID returns no error when int arg passed');
is(exception {$tr->getTestSuites(1)},         undef,'getTestSuites returns no error when int arg passed');
is(exception {$tr->getTests(1)},              undef,'getTests returns no error when int arg passed');
is(exception {$tr->getUserByID(1)},           undef,'getUserByID returns no error when int arg passed');
is(exception {$tr->getMilestones(1)},         undef,'getMilestones returns no error when int arg passed');
is(exception {$tr->getPlanByID(1)},           undef,'getPlanByID returns no error when int arg passed');
is(exception {$tr->getProjectByName('fake')}, undef,'getProjectByName returns no error when string arg passed');
is(exception {$tr->getUserByEmail('tickle')}, undef,'getUserByEmail returns no error when string arg passed');
is(exception {$tr->getUserByName('zap')},     undef,'getUserByName returns no error when string arg passed');
is(exception {$tr->getCaseTypeByName('zap')}, undef,'getCaseTypeByName returns no error when string arg passed');
is(exception {$tr->createProject('zippy')},   undef,'createProject returns no error when string arg passed');
is(exception {$tr->getTestResults(1)},        undef,'getTestResults with 1 arg returns no error');
is(exception {$tr->getMilestoneByID(1)},      undef,'getMilestoneByID with 1 arg returns no error');
is(exception {$tr->getConfigurations(1)},     undef,'getConfigurations with 1 arg returns no error');
is(exception {$tr->getChildRuns({}) },        undef,'getChildRuns returns no error when 1 argument passed');

isnt(exception {$tr->createCase(1)}, undef,'createCase with 1 arg returns error');
isnt(exception {$tr->createMilestone(1)}, undef,'createMilestone with 1 arg returns error');
isnt(exception {$tr->createPlan(1)}, undef,'createPlan with 1 arg returns error');
isnt(exception {$tr->createRun(1)}, undef,'createRun with 1 arg returns error');
isnt(exception {$tr->createSection(1)}, undef,'createSection with 1 arg returns error');
isnt(exception {$tr->createTestResults(1)}, undef,'createTestResults with 1 arg returns error');
isnt(exception {$tr->createTestSuite(1)}, undef,'createTestSuite with 1 arg returns error');
isnt(exception {$tr->getCaseByName(1)}, undef,'getCaseByName with 1 arg returns error');
isnt(exception {$tr->getCases(1)}, undef,'getCases with 1 arg returns error');
isnt(exception {$tr->getMilestoneByName(1)}, undef,'getMilestoneByName with 1 arg returns error');
isnt(exception {$tr->getPlanByName(1)}, undef,'getPlanByName with 1 arg returns error');
isnt(exception {$tr->getRunByName(1)}, undef,'getRunByName with 1 arg returns error');
isnt(exception {$tr->getSectionByName(1)}, undef,'getSectionByName with 1 arg returns error');
isnt(exception {$tr->getSections(1)}, undef,'getSections with 1 arg returns error');
isnt(exception {$tr->getTestByName(1)}, undef,'getTestByName with 1 arg returns error');
isnt(exception {$tr->getTestSuiteByName(1)}, undef,'getTestSuiteByName with 1 arg returns error');
isnt(exception {$tr->getChildRunByName({}) },undef,'getChildRunByName returns error when 1 argument passed');

#2 arg functions
is(exception {$tr->createMilestone(1,'whee')}, undef,'createMilestone with 2 args returns no error');
is(exception {$tr->createPlan(1,'whee')}, undef,'createPlan with 2 args returns no error');
is(exception {$tr->createTestResults(1,1)}, undef,'createTestResults with 2 args returns no error');
is(exception {$tr->createTestSuite(1,'zugzug')}, undef,'createTestSuite with 2 args returns no error');
is(exception {$tr->getMilestoneByName(1,'hug')}, undef,'getMilestoneByName with 2 args returns no error');
is(exception {$tr->getPlanByName(1,'nugs')}, undef,'getPlanByName with 2 args returns no error');
is(exception {$tr->getRunByName(1,'zoom')}, undef,'getRunByName with 2 args returns no error');
is(exception {$tr->getSections(1,1)}, undef,'getSections with 2 args returns no error');
is(exception {$tr->getTestByName(1,'poo')}, undef,'getTestByName with 2 args returns no error');
is(exception {$tr->getTestSuiteByName(1,'zap')}, undef,'getTestSuiteByName with 2 args returns no error');
is(exception {$tr->createCase(1,'whee')}, undef,'createCase with 2 args returns no error');
is(exception {$tr->getChildRunByName({},'whee')},undef,'getChildRunByName returns no error when 2 arguments passed');

isnt(exception {$tr->createRun(1,1)}, undef,'createRun with 2 args returns error');
isnt(exception {$tr->createSection(1,1)}, undef,'createSection with 2 args returns error');
isnt(exception {$tr->getCaseByName(1,1)}, undef,'getCaseByName with 2 args returns error');
isnt(exception {$tr->getCases(1,2)}, undef,'getCases with 2 args returns error');
isnt(exception {$tr->getSectionByName(1,1)}, undef,'getSectionByName with 2 args returns error');

#3 arg functions
is(exception {$tr->createRun(1,1,'whee')}, undef,'createRun with 3 args returns no error');
is(exception {$tr->createSection(1,1,'whee')}, undef,'createSection with 3 args returns no error');
is(exception {$tr->getCases(1,2,3)}, undef,'getCases with 3 args returns no error');
is(exception {$tr->getSectionByName(1,1,'zip')}, undef,'getSectionByName with 3 args returns no error');

isnt(exception {$tr->getCaseByName(1,1,1)}, undef,'getCaseByName with 3 args returns error');

#4 arg functions
is(exception {$tr->getCaseByName(1,1,1,'hug')}, undef,'getCaseByName with 4 args returns no error');
