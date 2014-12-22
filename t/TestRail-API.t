use strict;
use warnings;

use TestRail::API;
use Test::More tests => 50;
use Test::Fatal;
use Scalar::Util 'reftype';
use ExtUtils::MakeMaker qw{prompt};

#XXX mock in the future...
my $apiurl = $ENV{'TESTRAIL_API_URL'};
my $login  = $ENV{'TESTRAIL_USER'};
my $pw     = $ENV{'TESTRAIL_PASSWORD'};

#EXAMPLE:
#my $apiurl = 'http://testrails.cpanel.qa/testrail';
#my $login = 'some.guyb@whee.net';
#my $pw = '5gP77MdrSIB68UFWvhIK';

like(exception {TestRail::API->new('trash');}, qr/invalid uri/i, "Non-URIs bounce constructor");
like(exception {TestRail::API->new('http://hokum.bogus','lies','moreLies',0); }, qr/Could not communicate with TestRail Server/i,"Bogus Testrail URI rejected");

SKIP: {
    skip("Insufficient credentials",46) if (!$apiurl || !$login || !$pw);

    like(exception {TestRail::API->new($apiurl,'lies','moreLies',0); }, qr/Bad user credentials/i,"Bogus Testrail User rejected");
    like(exception {TestRail::API->new($apiurl,$login,'m043L13s                      ',0); }, qr/Bad user credentials/i,"Bogus Testrail Password rejected");

    my $tr = new TestRail::API($apiurl,$login,$pw,0);

    #Test USER methods
    my $userlist = $tr->getUsers();
    ok(@$userlist,"Get Users returns list");
    my $myuser = $tr->getUserByEmail($login);
    is($myuser->{'email'},$login,"Can get user by email");
    is($tr->getUserByID($myuser->{'id'})->{'id'},$myuser->{'id'},"Can get user by ID");
    is($tr->getUserByName($myuser->{'name'})->{'name'},$myuser->{'name'},"Can get user by Name");

    #Test PROJECT methods
    my $project_name = 'CRUSH ALL HUMANS';

    my $new_project = $tr->createProject($project_name,'Robo-Signed Soviet 5 Year Project');
    is($new_project->{'name'},$project_name,"Can create new project");

    ok($tr->getProjects(),"Get Projects returns list");
    is($tr->getProjectByName($project_name)->{'name'},$project_name,"Can get project by name");
    my $pjid = $tr->getProjectByID($new_project->{'id'});
    is(reftype($pjid) eq 'HASH' ? $pjid->{'id'} : $pjid,$new_project->{'id'},"Can get project by id");

    #Test TESTSUITE methods
    my $suite_name = 'HAMBURGER-IZE HUMANITY';
    my $new_suite = $tr->createTestSuite($new_project->{'id'},$suite_name,"Robo-Signed Patriotic People's TestSuite");
    is($new_suite->{'name'},$suite_name,"Can create new testsuite");

    ok($tr->getTestSuites($new_project->{'id'}),"Can get listing of testsuites for project");
    is($tr->getTestSuiteByName($new_project->{'id'},$new_suite->{'name'})->{'name'},$new_suite->{'name'},"Can get suite by name");
    is($tr->getTestSuiteByID($new_suite->{'id'})->{'id'},$new_suite->{'id'},"Can get suite by id");

    #Test SECTION methods -- roughly analogous to TESTSUITES in TL
    my $section_name = 'CARBON LIQUEFACTION';
    my $new_section = $tr->createSection($new_project->{'id'},$new_suite->{'id'},$section_name);
    is($new_section->{'name'},$section_name,"Can create new section");

    ok($tr->getSections($new_project->{'id'},$new_suite->{'id'}),"Can get section listing");
    is($tr->getSectionByName($new_project->{'id'},$new_suite->{'id'},$section_name)->{'name'},$section_name,"Can get section by name");
    is($tr->getSectionByID($new_section->{'id'})->{'id'},$new_section->{'id'},"Can get new section by id");

    #Test CASE methods
    my $case_name = 'STROGGIFY POPULATION CENTERS';
    my $new_case = $tr->createCase($new_section->{'id'},$case_name);
    is($new_case->{'title'},$case_name,"Can create new test case");

    ok($tr->getCases($new_project->{'id'},$new_suite->{'id'},$new_section->{'id'}),"Can get case listing");
    is($tr->getCaseByName($new_project->{'id'}, $new_suite->{'id'}, $new_section->{'id'}, $case_name)->{'title'},$case_name,"Can get case by name");
    is($tr->getCaseByID($new_case->{'id'})->{'id'},$new_case->{'id'},"Can get case by ID");

    #Test RUN methods
    my $run_name = 'SEND T-1000 INFILTRATION UNITS BACK IN TIME';
    my $new_run = $tr->createRun($new_project->{'id'},$new_suite->{'id'},$run_name,"ACQUIRE CLOTHES, BOOTS AND MOTORCYCLE");
    is($new_run->{'name'},$run_name,"Can create new run");

    ok($tr->getRuns($new_project->{'id'}),"Can get list of runs");
    is($tr->getRunByName($new_project->{'id'},$run_name)->{'name'},$run_name,"Can get run by name");
    is($tr->getRunByID($new_run->{'id'})->{'id'},$new_run->{'id'},"Can get run by ID");

    #Test MILESTONE methods
    my $milestone_name = "Humanity Exterminated";
    my $new_milestone = $tr->createMilestone($new_project->{'id'},$milestone_name,"Kill quota reached if not achieved in 5 years",time()+157788000); #It IS a soviet 5-year plan after all :)
    is($new_milestone->{'name'},$milestone_name,"Can create new milestone");

    ok($tr->getMilestones($new_project->{'id'}),"Can get list of milestones");
    is($tr->getMilestoneByName($new_project->{'id'},$milestone_name)->{'name'},$milestone_name,"Can get milestone by name");
    is($tr->getMilestoneByID($new_milestone->{'id'})->{'id'},$new_milestone->{'id'},"Can get milestone by ID");

    #Test PLAN methods
    my $plan_name = "GosPlan";
    my $new_plan = $tr->createPlan($new_project->{'id'},$plan_name,"Soviet 5-year agriculture plan to liquidate Kulaks",$new_milestone->{'id'},[{ suite_id => $new_suite->{'id'}, name => "Executing the great plan"}]);
    is($new_plan->{'name'},$plan_name,"Can create new plan");

    ok($tr->getPlans($new_project->{'id'}),"Can get list of plans");
    is($tr->getPlanByName($new_project->{'id'},$plan_name)->{'name'},$plan_name,"Can get plan by name");
    is($tr->getPlanByID($new_plan->{'id'})->{'id'},$new_plan->{'id'},"Can get plan by ID");

    #Test TEST/RESULT methods
    my $tests = $tr->getTests($new_run->{'id'});
    ok($tests,"Can get tests");
    is($tr->getTestByName($new_run->{'id'},$tests->[0]->{'title'})->{'title'},$tests->[0]->{'title'},"Can get test by name");
    is($tr->getTestByID($tests->[0]->{'id'})->{'id'},$tests->[0]->{'id'},"Can get test by ID");

    my $resTypes = $tr->getTestResultFields();
    my $statusTypes = $tr->getPossibleTestStatuses();
    ok($resTypes,"Can get test result fields");
    ok($statusTypes,"Can get possible test statuses");

    my $result = $tr->createTestResults($tests->[0]->{'id'},$statusTypes->[0]->{'id'},"REAPER FORCES INBOUND");
    ok(defined($result->{'id'}),"Can add test results");
    my $results = $tr->getTestResults($tests->[0]->{'id'});
    is($results->[0]->{'id'},$result->{'id'},"Can get results for test");

    #Delete a plan
    ok($tr->deletePlan($new_plan->{'id'}),"Can delete plan");

    #Delete a milestone
    ok($tr->deleteMilestone($new_milestone->{'id'}),"Can delete milestone");

    #Delete a run
    ok($tr->deleteRun($new_run->{'id'}),"Can delete run");

    #Delete a case
    ok($tr->deleteCase($new_case->{'id'}),"Can delete Case");

    #Delete a section
    ok($tr->deleteSection($new_section->{'id'}),"Can delete Section");

    #Delete a testsuite
    ok($tr->deleteTestSuite($new_suite->{'id'}),"Can delete TestSuite");

    #Delete project now that we are done with it
    ok($tr->deleteProject($new_project->{'id'}),"Can delete project");
}
1;
