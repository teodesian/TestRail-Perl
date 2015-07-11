# ABSTRACT: Provides an interface to TestRail's REST api via HTTP
# PODNAME: TestRail::API

package TestRail::API;

=head1 SYNOPSIS

    use TestRail::API;

    my ($username,$password,$host) = ('foo','bar','testlink.baz.foo');
    my $tr = TestRail::API->new($username, $password, $host);

=head1 DESCRIPTION

C<TestRail::API> provides methods to access an existing TestRail account using API v2.  You can then do things like look up tests, set statuses and create runs from lists of cases.
It is by no means exhaustively implementing every TestRail API function.

=head1 IMPORTANT

All the methods aside from the constructor should not die, but return a false value upon failure.
When the server is not responsive, expect a -500 response, and retry accordingly.
I recommend using the excellent L<Attempt> module for this purpose.

=cut

use 5.010;

use strict;
use warnings;

use Carp qw{cluck confess};
use Scalar::Util qw{reftype looks_like_number};
use Clone 'clone';
use Try::Tiny;

use JSON::MaybeXS 1.001000 ();
use HTTP::Request;
use LWP::UserAgent;
use Data::Validate::URI qw{is_uri};
use List::Util 1.33;
use Encode ();

=head1 CONSTRUCTOR

=head2 B<new (api_url, user, password, encoding, debug)>

Creates new C<TestRail::API> object.

=over 4

=item STRING C<API URL> - base url for your TestRail api server.

=item STRING C<USER> - Your TestRail User.

=item STRING C<PASSWORD> - Your TestRail password, or a valid API key (TestRail 4.2 and above).

=item STRING C<ENCODING> - The character encoding used by the caller.  Defaults to 'UTF-8', see L<Encode::Supported> and  for supported encodings.

=item BOOLEAN C<DEBUG> (optional) - Print the JSON responses from TL with your requests. Default false.

=back

Returns C<TestRail::API> object if login is successful.

    my $tr = TestRail::API->new('http://tr.test/testrail', 'moo','M000000!');

Dies on all communication errors with the TestRail server.
Does not do above checks if debug is passed.

=cut

sub new {
    my ($class,$apiurl,$user,$pass,$encoding,$debug) = @_;
    confess("Constructor must be called statically, not by an instance") if ref($class);
    confess("Invalid URI passed to constructor") if !is_uri($apiurl);
    $user //= $ENV{'TESTRAIL_USER'};
    $pass //= $ENV{'TESTRAIL_PASSWORD'};
    $debug //= 0;

    my $self = {
        user             => $user,
        pass             => $pass,
        apiurl           => $apiurl,
        debug            => $debug,
        encoding         => $encoding || 'UTF-8',
        testtree         => [],
        flattree         => [],
        user_cache       => [],
        type_cache       => [],
        configurations   => {},
        tr_fields        => undef,
        default_request  => undef,
        global_limit     => 250, #Discovered by experimentation
        browser          => new LWP::UserAgent()
    };

    #Check chara encoding
    $self->{'encoding-nonaliased'} = Encode::resolve_alias($self->{'encoding'});
    confess("Invalid encoding alias '".$self->{'encoding'}."' passed, see Encoding::Supported for a list of allowed encodings")
        unless $self->{'encoding-nonaliased'};

    confess("Invalid encoding '".$self->{'encoding-nonaliased'}."' passed, see Encoding::Supported for a list of allowed encodings")
        unless grep {$_ eq $self->{'encoding-nonaliased'}} (Encode->encodings(":all"));

    #Create default request to pass on to LWP::UserAgent
    $self->{'default_request'} = new HTTP::Request();
    $self->{'default_request'}->authorization_basic($user,$pass);

    bless( $self, $class );
    return $self if $self->debug; #For easy class testing without mocks

    #Manually do the get_users call to check HTTP status
    my $res = $self->_doRequest('index.php?/api/v2/get_users');
    confess "Error: network unreachable" if !defined($res);
    if ( (reftype($res) || 'undef') ne 'ARRAY') {
      confess "Unexpected return from _doRequest: $res" if !looks_like_number($res);
      confess "Could not communicate with TestRail Server! Check that your URI is correct, and your TestRail installation is functioning correctly." if $res == -500;
      confess "Could not list testRail users! Check that your TestRail installation has it's API enabled, and your credentials are correct" if $res == -403;
      confess "Bad user credentials!" if $res == -401;
      confess "HTTP error $res encountered while communicating with TestRail server.  Resolve issue and try again." if !$res;
      confess "Unknown error occurred: $res";
    }
    confess "No users detected on TestRail Install!  Check that your API is functioning correctly." if !scalar(@$res);
    $self->{'user_cache'} = $res;

    return $self;
}

=head1 GETTERS

=head2 B<apiurl>

=head2 B<debug>

Accessors for these parameters you pass into the constructor, in case you forget.

=cut

sub apiurl {
  my $self = shift;
  confess("Object methods must be called by an instance") unless ref($self);
  return $self->{'apiurl'}
}
sub debug {
  my $self = shift;
  confess("Object methods must be called by an instance") unless ref($self);
  return $self->{'debug'};
}

#Convenient JSON-HTTP fetcher
sub _doRequest {
    my ($self,$path,$method,$data) = @_;
    confess("Object methods must be called by an instance") unless ref($self);
    my $req = clone $self->{'default_request'};
    $method //= 'GET';

    $req->method($method);
    $req->url($self->apiurl.'/'.$path);

    warn "$method ".$self->apiurl."/$path" if $self->debug;

    my $coder = JSON::MaybeXS->new;

    #Data sent is JSON, and encoded per user preference
    my $content = $data ? Encode::encode( $self->{'encoding-nonaliased'}, $coder->encode($data) ) : '';

    $req->content($content);
    $req->header( "Content-Type" => "application/json; charset=".$self->{'encoding'} );

    my $response = $self->{'browser'}->request($req);

    #Uncomment to generate mocks
    #use Data::Dumper;
    #print Dumper($path,'200','OK',$response->headers,$response->content);

    return $response if !defined($response); #worst case
    if ($response->code == 403) {
        cluck "ERROR: Access Denied.";
        return -403;
    }
    if ($response->code != 200) {
        cluck "ERROR: Arguments Bad: ".$response->content;
        return -int($response->code);
    }

    try {
        return $coder->decode($response->content);
    } catch {
        if ($response->code == 200 && !$response->content) {
            return 1; #This function probably just returns no data
        } else {
            cluck "ERROR: Malformed JSON returned by API.";
            cluck $@;
            if (!$self->debug) { #Otherwise we've already printed this, but we need to know if we encounter this
                cluck "RAW CONTENT:";
                cluck $response->content
            }
            return 0;
        }
    }
}

=head1 USER METHODS

=head2 B<getUsers ()>

Get all the user definitions for the provided Test Rail install.
Returns ARRAYREF of user definition HASHREFs.

=cut

sub getUsers {
    my $self = shift;
    confess("Object methods must be called by an instance") unless ref($self);
    my $res = $self->_doRequest('index.php?/api/v2/get_users');
    return -500 if !$res || (reftype($res) || 'undef') ne 'ARRAY';
    $self->{'user_cache'} = $res;
    return $res;
}

=head2 B<getUserByID(id)>
=cut
=head2 B<getUserByName(name)>
=cut
=head2 B<getUserByEmail(email)>

Get user definition hash by ID, Name or Email.
Returns user def HASHREF.

=cut

#I'm just using the cache for the following methods because it's more straightforward and faster past 1 call.
sub getUserByID {
    my ($self,$user) = @_;
    confess("Object methods must be called by an instance") unless ref($self);
    confess("User ID must be integer") unless $self->_checkInteger($user);
    $self->getUsers() if !defined($self->{'user_cache'});
    return -500 if (!defined($self->{'user_cache'}) || (reftype($self->{'user_cache'}) || 'undef') ne 'ARRAY');
    foreach my $usr (@{$self->{'user_cache'}}) {
        return $usr if $usr->{'id'} == $user;
    }
    return 0;
}

sub getUserByName {
    my ($self,$user) = @_;
    confess("Object methods must be called by an instance") unless ref($self);
    confess("User must be string") unless $self->_checkString($user);
    $self->getUsers() if !defined($self->{'user_cache'});
    return -500 if (!defined($self->{'user_cache'}) || (reftype($self->{'user_cache'}) || 'undef') ne 'ARRAY');
    foreach my $usr (@{$self->{'user_cache'}}) {
        return $usr if $usr->{'name'} eq $user;
    }
    return 0;
}

sub getUserByEmail {
    my ($self,$email) = @_;
    confess("Object methods must be called by an instance") unless ref($self);
    confess("Email must be string") unless $self->_checkString($email);
    $self->getUsers() if !defined($self->{'user_cache'});
    return -500 if (!defined($self->{'user_cache'}) || (reftype($self->{'user_cache'}) || 'undef') ne 'ARRAY');
    foreach my $usr (@{$self->{'user_cache'}}) {
        return $usr if $usr->{'email'} eq $email;
    }
    return 0;
}

=head2 userNamesToIds(names)

Convenience method to translate a list of user names to TestRail user IDs.

=over 4

=item ARRAY C<NAMES> - Array of user names to translate to IDs.

=back

Returns ARRAY of user IDs.

Throws an exception in the case of one (or more) of the names not corresponding to a valid username.

=cut

sub userNamesToIds {
    my ($self,@names) = @_;
    confess("Object methods must be called by an instance") unless ref($self);
    confess("At least one user name must be provided") if !scalar(@names);
    my @ret = grep {defined $_} map {my $user = $_; my @list = grep {$user->{'name'} eq $_} @names; scalar(@list) ? $user->{'id'} : undef} @{$self->getUsers()};
    confess("One or more user names provided does not exist in TestRail.") unless scalar(@names) == scalar(@ret);
    return @ret;
};

=head1 PROJECT METHODS

=head2 B<createProject (name, [description,send_announcement])>

Creates new Project (Database of testsuites/tests).
Optionally specify an announcement to go out to the users.
Requires TestRail admin login.

=over 4

=item STRING C<NAME> - Desired name of project.

=item STRING C<DESCRIPTION> (optional) - Description of project.  Default value is 'res ipsa loquiter'.

=item BOOLEAN C<SEND ANNOUNCEMENT> (optional) - Whether to confront users with an announcement about your awesome project on next login.  Default false.

=back

Returns project definition HASHREF on success, false otherwise.

    $tl->createProject('Widgetronic 4000', 'Tests for the whiz-bang new product', true);

=cut

sub createProject {
    my ($self,$name,$desc,$announce) = @_;
    confess("Object methods must be called by an instance") unless ref($self);
    confess("Project name must be string") unless $self->_checkString($name);
    $desc     //= 'res ipsa loquiter';
    $announce //= 0;
    confess("Project description must be string") unless $self->_checkString($desc);
    confess("Announce must be integer") unless $self->_checkInteger($announce);

    my $input = {
        name              => $name,
        announcement      => $desc,
        show_announcement => $announce
    };

    my $result = $self->_doRequest('index.php?/api/v2/add_project','POST',$input);
    return $result;

}

=head2 B<deleteProject (id)>

Deletes specified project by ID.
Requires TestRail admin login.

=over 4

=item STRING C<NAME> - Desired name of project.

=back

Returns BOOLEAN.

    $success = $tl->deleteProject(1);

=cut

sub deleteProject {
    my ($self,$proj) = @_;
    confess("Object methods must be called by an instance") unless ref($self);
    confess("Project ID must be integer") unless $self->_checkInteger($proj);
    my $result = $self->_doRequest('index.php?/api/v2/delete_project/'.$proj,'POST');
    return $result;
}

=head2 B<getProjects ()>

Get all available projects

Returns array of project definition HASHREFs, false otherwise.

    $projects = $tl->getProjects;

=cut

sub getProjects {
    my $self = shift;
    confess("Object methods must be called by an instance") unless ref($self);

    my $result = $self->_doRequest('index.php?/api/v2/get_projects');

    #Save state for future use, if needed
    return -500 if !$result || (reftype($result) || 'undef') ne 'ARRAY';
    $self->{'testtree'} = $result;

    #Note that it's a project for future reference by recursive tree search
    return -500 if !$result || (reftype($result) || 'undef') ne 'ARRAY';
    foreach my $pj (@{$result}) {
        $pj->{'type'} = 'project';
    }

    return $result;
}

=head2 B<getProjectByName ($project)>

Gets some project definition hash by it's name

=over 4

=item STRING C<PROJECT> - desired project

=back

Returns desired project def HASHREF, false otherwise.

    $project = $tl->getProjectByName('FunProject');

=cut

sub getProjectByName {
    my ($self,$project) = @_;
    confess("Object methods must be called by an instance") unless ref($self);
    confess("Project must be string.") unless $self->_checkString($project);

    #See if we already have the project list...
    my $projects = $self->{'testtree'};
    return -500 if !$projects || (reftype($projects) || 'undef') ne 'ARRAY';
    $projects = $self->getProjects() unless scalar(@$projects);

    #Search project list for project
    return -500 if !$projects || (reftype($projects) || 'undef') ne 'ARRAY';
    for my $candidate (@$projects) {
        return $candidate if ($candidate->{'name'} eq $project);
    }

    return 0;
}

=head2 B<getProjectByID ($project)>

Gets some project definition hash by it's ID

=over 4

=item INTEGER C<PROJECT> - desired project

=back

Returns desired project def HASHREF, false otherwise.

    $projects = $tl->getProjectByID(222);

=cut

sub getProjectByID {
    my ($self,$project) = @_;
    confess("Object methods must be called by an instance") unless ref($self);
    confess("No project provided.") unless $project;
    confess("Project ID must be integer") unless $self->_checkInteger($project);

    #See if we already have the project list...
    my $projects = $self->{'testtree'};
    $projects = $self->getProjects() unless scalar(@$projects);

    #Search project list for project
    return -500 if !$projects || (reftype($projects) || 'undef') ne 'ARRAY';
    for my $candidate (@$projects) {
        return $candidate if ($candidate->{'id'} eq $project);
    }

    return 0;
}
=head1 TESTSUITE METHODS

=head2 B<createTestSuite (project_id, name, [description])>

Creates new TestSuite (folder of tests) in the database of test specifications under given project id having given name and details.

=over 4

=item INTEGER C<PROJECT ID> - ID of project this test suite should be under.

=item STRING C<NAME> - Desired name of test suite.

=item STRING C<DESCRIPTION> (optional) - Description of test suite.  Default value is 'res ipsa loquiter'.

=back

Returns TS definition HASHREF on success, false otherwise.

    $tl->createTestSuite(1, 'broken tests', 'Tests that should be reviewed');

=cut

sub createTestSuite {
    my ($self,$project_id,$name,$details) = @_;
    confess("Object methods must be called by an instance") unless ref($self);
    confess("Project ID must be integer") unless $self->_checkInteger($project_id);
    confess("Name must be a string") unless $self->_checkString($name);
    $details ||= 'res ipsa loquiter';
    confess("Project details must be a string") unless $self->_checkString($details);

    my $input = {
        name        => $name,
        description => $details
    };

    my $result = $self->_doRequest('index.php?/api/v2/add_suite/'.$project_id,'POST',$input);
    return $result;

}

=head2 B<deleteTestSuite (suite_id)>

Deletes specified testsuite.

=over 4

=item INTEGER C<SUITE ID> - ID of testsuite to delete.

=back

Returns BOOLEAN.

    $tl->deleteTestSuite(1);

=cut

sub deleteTestSuite {
    my ($self,$suite_id) = @_;
    confess("Object methods must be called by an instance") unless ref($self);
    confess("Suite ID must be integer") unless $self->_checkInteger($suite_id);

    my $result = $self->_doRequest('index.php?/api/v2/delete_suite/'.$suite_id,'POST');
    return $result;

}

=head2 B<getTestSuites (project_id)>

Gets the testsuites for a project

=over 4

=item STRING C<PROJECT ID> - desired project's ID

=back

Returns ARRAYREF of testsuite definition HASHREFs, 0 on error.

    $suites = $tl->getTestSuites(123);

=cut

sub getTestSuites {
    my ($self,$proj) = @_;
    confess("Object methods must be called by an instance") unless ref($self);
    confess("Project ID must be integer") unless $self->_checkInteger($proj);
    return $self->_doRequest('index.php?/api/v2/get_suites/'.$proj);
}

=head2 B<getTestSuiteByName (project_id,testsuite_name)>

Gets the testsuite that matches the given name inside of given project.

=over 4

=item STRING C<PROJECT ID> - ID of project holding this testsuite

=item STRING C<TESTSUITE NAME> - desired parent testsuite name

=back

Returns desired testsuite definition HASHREF, false otherwise.

    $suites = $tl->getTestSuitesByName(321, 'hugSuite');

=cut

sub getTestSuiteByName {
    my ($self,$project_id,$testsuite_name) = @_;
    confess("Object methods must be called by an instance") unless ref($self);
    confess("Project ID must be integer") unless $self->_checkInteger($project_id);
    confess("Testsuite Name must be String") unless $self->_checkString($testsuite_name);

    #TODO cache
    my $suites = $self->getTestSuites($project_id);
    return -500 if !$suites || (reftype($suites) || 'undef') ne 'ARRAY'; #No suites for project, or no project
    foreach my $suite (@$suites) {
        return  $suite if $suite->{'name'} eq $testsuite_name;
    }
    return 0; #Couldn't find it
}

=head2 B<getTestSuiteByID (testsuite_id)>

Gets the testsuite with the given ID.

=over 4

=item STRING C<TESTSUITE_ID> - TestSuite ID.

=back

Returns desired testsuite definition HASHREF, false otherwise.

    $tests = $tl->getTestSuiteByID(123);

=cut

sub getTestSuiteByID {
    my ($self,$testsuite_id) = @_;
    confess("Object methods must be called by an instance") unless ref($self);
    confess("Testsuite ID must be integer") unless $self->_checkInteger($testsuite_id);

    my $result = $self->_doRequest('index.php?/api/v2/get_suite/'.$testsuite_id);
    return $result;
}

=head1 SECTION METHODS

=head2 B<createSection(project_id,suite_id,name,[parent_id])>

Creates a section.

=over 4

=item INTEGER C<PROJECT ID> - Parent Project ID.

=item INTEGER C<SUITE ID> - Parent TestSuite ID.

=item STRING C<NAME> - desired section name.

=item INTEGER C<PARENT ID> (optional) - parent section id

=back

Returns new section definition HASHREF, false otherwise.

    $section = $tr->createSection(1,1,'nugs',1);

=cut

sub createSection {
    my ($self,$project_id,$suite_id,$name,$parent_id) = @_;
    confess("Object methods must be called by an instance") unless ref($self);
    confess("Project ID must be integer") unless $self->_checkInteger($project_id);
    confess("Suite ID must be integer") unless $self->_checkInteger($suite_id);
    confess("Section name must be string") unless $self->_checkString($name);
    confess("Parent section ID must be integer") unless !defined($parent_id) || $self->_checkInteger($parent_id);

    my $input = {
        name     => $name,
        suite_id => $suite_id
    };
    $input->{'parent_id'} = $parent_id if $parent_id;

    my $result = $self->_doRequest('index.php?/api/v2/add_section/'.$project_id,'POST',$input);
    return $result;

}

=head2 B<deleteSection (section_id)>

Deletes specified section.

=over 4

=item INTEGER C<SECTION ID> - ID of section to delete.

=back

Returns BOOLEAN.

    $tr->deleteSection(1);

=cut

sub deleteSection {
    my ($self,$section_id) = @_;
    confess("Object methods must be called by an instance") unless ref($self);
    confess("Section ID must be integer") unless $self->_checkInteger($section_id);

    my $result = $self->_doRequest('index.php?/api/v2/delete_section/'.$section_id,'POST');
    return $result;

}

=head2 B<getSections (project_id,suite_id)>

Gets sections for a given project and suite.

=over 4

=item INTEGER C<PROJECT ID> - ID of parent project.

=item INTEGER C<SUITE ID> - ID of suite to get sections for.

=back

Returns ARRAYREF of section definition HASHREFs.

    $tr->getSections(1,2);

=cut

sub getSections {
    my ($self,$project_id,$suite_id) = @_;
    confess("Object methods must be called by an instance") unless ref($self);
    confess("Project ID must be integer") unless $self->_checkInteger($project_id);
    confess("Suite ID must be integer") unless $self->_checkInteger($suite_id);
    return $self->_doRequest("index.php?/api/v2/get_sections/$project_id&suite_id=$suite_id");
}

=head2 B<getSectionByID (section_id)>

Gets desired section.

=over 4

=item INTEGER C<PROJECT ID> - ID of parent project.

=item INTEGER C<SUITE ID> - ID of suite to get sections for.

=back

Returns section definition HASHREF.

    $tr->getSectionByID(344);

=cut

sub getSectionByID {
    my ($self,$section_id) = @_;
    confess("Object methods must be called by an instance") unless ref($self);
    confess("Section ID must be integer") unless $self->_checkInteger($section_id);
    return $self->_doRequest("index.php?/api/v2/get_section/$section_id");
}

=head2 B<getSectionByName (project_id,suite_id,name)>

Gets desired section.

=over 4

=item INTEGER C<PROJECT ID> - ID of parent project.

=item INTEGER C<SUITE ID> - ID of suite to get section for.

=item STRING C<NAME> - name of section to get

=back

Returns section definition HASHREF.

    $tr->getSectionByName(1,2,'nugs');

=cut

sub getSectionByName {
    my ($self,$project_id,$suite_id,$section_name) = @_;
    confess("Object methods must be called by an instance") unless ref($self);
    confess("Project ID must be an integer") unless $self->_checkInteger($project_id);
    confess("Suite ID must be an integer") unless $self->_checkInteger($suite_id);
    confess("Section Name must be a string") unless $self->_checkString($section_name);
    my $sections = $self->getSections($project_id,$suite_id);
    return -500 if !$sections || (reftype($sections) || 'undef') ne 'ARRAY';
    foreach my $sec (@$sections) {
        return $sec if $sec->{'name'} eq $section_name;
    }
    return 0;
}

=head2 sectionNamesToIds(project_id,suite_id,names)

Convenience method to translate a list of section names to TestRail section IDs.

=over 4

=item INTEGER C<PROJECT ID> - ID of parent project.

=item INTEGER C<SUITE ID> - ID of parent suite.

=item ARRAY C<NAMES> - Array of section names to translate to IDs.

=back

Returns ARRAY of section IDs.

Throws an exception in the case of one (or more) of the names not corresponding to a valid section name.

=cut

sub sectionNamesToIds {
    my ($self,$project_id,$suite_id,@names) = @_;
    confess("Object methods must be called by an instance") unless ref($self);
    confess("Project ID must be an integer") unless $self->_checkInteger($project_id);
    confess("Suite ID must be an integer") unless $self->_checkInteger($suite_id);
    confess("At least one section name must be provided") if !scalar(@names);

    my $sections = $self->getSections($project_id,$suite_id);
    confess("Invalid project/suite ($project_id,$suite_id) provided.") unless (reftype($sections) || 'undef') eq 'ARRAY';
    my @ret = grep {defined $_} map {my $section = $_; my @list = grep {$section->{'name'} eq $_} @names; scalar(@list) ? $section->{'id'} : undef} @$sections;
    confess("One or more user names provided does not exist in TestRail.") unless scalar(@names) == scalar(@ret);
    return @ret;
}

=head1 CASE METHODS

=head2 B<getCaseTypes ()>

Gets possible case types.

Returns ARRAYREF of case type definition HASHREFs.

    $tr->getCaseTypes();

=cut

sub getCaseTypes {
    my $self = shift;
    confess("Object methods must be called by an instance") unless ref($self);
    my $types = $self->_doRequest("index.php?/api/v2/get_case_types");
    return -500 if !$types || (reftype($types) || 'undef') ne 'ARRAY';
    $self->{'type_cache'} = $types if !$self->{'type_cache'}; #We can't change this with API, so assume it is static
    return $self->{'type_cache'};
}

=head2 B<getCaseTypeByName (name)>

Gets case type by name.

=over 4

=item STRING C<NAME> - Name of desired case type

=back

Returns case type definition HASHREF.

    $tr->getCaseTypeByName();

=cut

sub getCaseTypeByName {
    #Useful for marking automated tests, etc
    my ($self,$name) = @_;
    confess("Object methods must be called by an instance") unless ref($self);
    confess("Case type must be string") unless $self->_checkString($name);
    my $types = $self->getCaseTypes();
    return -500 if !$types || (reftype($types) || 'undef') ne 'ARRAY';
    foreach my $type (@$types) {
        return $type if $type->{'name'} eq $name;
    }
    return 0;
}

=head2 B<createCase(section_id,title,type_id,options,extra_options)>

Creates a test case.

=over 4

=item INTEGER C<SECTION ID> - Parent Section ID.

=item STRING C<TITLE> - Case title.

=item INTEGER C<TYPE_ID> (optional) - desired test type's ID.  Defaults to whatever your TR install considers the default type.

=item HASHREF C<OPTIONS> (optional) - Custom fields in the case are the keys, set to the values provided.  See TestRail API documentation for more info.

=item HASHREF C<EXTRA OPTIONS> (optional) - contains priority_id, estimate, milestone_id and refs as possible keys.  See TestRail API documentation for more info.

=back

Returns new case definition HASHREF, false otherwise.

    $custom_opts = {
        preconds => "Test harness installed",
        steps         => "Do the needful",
        expected      => "cubicle environment transforms into Dali painting"
    };

    $other_opts = {
        priority_id => 4,
        milestone_id => 666,
        estimate    => '2m 45s',
        refs => ['TRACE-22','ON-166'] #ARRAYREF of bug IDs.
    }

    $case = $tr->createCase(1,'Do some stuff',3,$custom_opts,$other_opts);

=cut

sub createCase {
    my ($self,$section_id,$title,$type_id,$opts,$extras) = @_;
    confess("Object methods must be called by an instance") unless ref($self);
    confess("Section ID ($section_id) must be integer") unless $self->_checkInteger($section_id);
    confess("title must be string") unless $self->_checkString($title);
    confess("Type ID must be integer") unless !defined($type_id) || $self->_checkInteger($type_id);
    confess("Options must be HASHREF") unless !defined($opts) || (reftype($opts) || 'undef') ne 'HASH';
    confess("Extras must be HASHREF") unless !defined($extras) || (reftype($extras) || 'undef') ne 'HASH';

    my $stuff = {
        title   => $title,
        type_id => $type_id
    };

    #Handle sort of optional but baked in options
    if (defined($extras) && reftype($extras) eq 'HASH') {
        $stuff->{'priority_id'}  = $extras->{'priority_id'}       if defined($extras->{'priority_id'});
        $stuff->{'estimate'}     = $extras->{'estimate'}          if defined($extras->{'estimate'});
        $stuff->{'milestone_id'} = $extras->{'milestone_id'}      if defined($extras->{'milestone_id'});
        $stuff->{'refs'}         = join(',',@{$extras->{'refs'}}) if defined($extras->{'refs'});
    }

    #Handle custom fields
    if (defined($opts) && reftype($opts) eq 'HASH') {
        foreach my $key (keys(%$opts)) {
            $stuff->{"custom_$key"} = $opts->{$key};
        }
    }

    my $result = $self->_doRequest("index.php?/api/v2/add_case/$section_id",'POST',$stuff);
    return $result;
}

=head2 B<deleteCase (case_id)>

Deletes specified section.

=over 4

=item INTEGER C<CASE ID> - ID of case to delete.

=back

Returns BOOLEAN.

    $tr->deleteCase(1324);

=cut

sub deleteCase {
    my ($self,$case_id) = @_;
    confess("Object methods must be called by an instance") unless ref($self);
    confess("Case ID must be integer") unless $self->_checkInteger($case_id);
    my $result = $self->_doRequest("index.php?/api/v2/delete_case/$case_id",'POST');
    return $result;
}

=head2 B<getCases (project_id,suite_id,section_id)>

Gets cases for provided section.

=over 4

=item INTEGER C<PROJECT ID> - ID of parent project.

=item INTEGER C<SUITE ID> - ID of parent suite.

=item INTEGER C<SECTION ID> - ID of parent section

=back

Returns ARRAYREF of test case definition HASHREFs.

    $tr->getCases(1,2,3);

=cut

sub getCases {
    my ($self,$project_id,$suite_id,$section_id) = @_;
    confess("Object methods must be called by an instance") unless ref($self);
    confess("Project ID must be integer") unless $self->_checkInteger($project_id);
    confess("Suite ID must be integer") unless $self->_checkInteger($suite_id);
    confess("Section ID must be integer") unless $self->_checkInteger($section_id);
    my $url = "index.php?/api/v2/get_cases/$project_id&suite_id=$suite_id";
    $url .= "&section_id=$section_id" if $section_id;
    return $self->_doRequest($url);
}

=head2 B<getCaseByName (project_id,suite_id,section_id,name)>

Gets case by name.

=over 4

=item INTEGER C<PROJECT ID> - ID of parent project.

=item INTEGER C<SUITE ID> - ID of parent suite.

=item INTEGER C<SECTION ID> - ID of parent section.

=item STRING <NAME> - Name of desired test case.

=back

Returns test case definition HASHREF.

    $tr->getCaseByName(1,2,3,'nugs');

=cut

sub getCaseByName {
    my ($self,$project_id,$suite_id,$section_id,$name) = @_;
    confess("Object methods must be called by an instance") unless ref($self);
    confess("Project ID must be integer") unless $self->_checkInteger($project_id);
    confess("Suite ID must be integer") unless $self->_checkInteger($suite_id);
    confess("Section ID must be integer") unless $self->_checkInteger($section_id);
    confess("Test Case name must be string") unless $self->_checkString($name);
    my $cases = $self->getCases($project_id,$suite_id,$section_id);
    return -500 if !$cases || (reftype($cases) || 'undef') ne 'ARRAY';
    foreach my $case (@$cases) {
        return $case if $case->{'title'} eq $name;
    }
    return 0;
}

=head2 B<getCaseByID (case_id)>

Gets case by ID.

=over 4

=item INTEGER C<CASE ID> - ID of case.

=back

Returns test case definition HASHREF.

    $tr->getCaseByID(1345);

=cut

sub getCaseByID {
    my ($self,$case_id) = @_;
    confess("Object methods must be called by an instance") unless ref($self);
    confess("Case ID must be integer") unless $self->_checkInteger($case_id);
    return $self->_doRequest("index.php?/api/v2/get_case/$case_id");
}

=head1 RUN METHODS

=head2 B<createRun (project_id,suite_id,name,description,milestone_id,assigned_to_id,case_ids)>

Create a run.

=over 4

=item INTEGER C<PROJECT ID> - ID of parent project.

=item INTEGER C<SUITE ID> - ID of suite to base run on

=item STRING C<NAME> - Name of run

=item STRING C<DESCRIPTION> (optional) - Description of run

=item INTEGER C<MILESTONE ID> (optional) - ID of milestone

=item INTEGER C<ASSIGNED TO ID> (optional) - User to assign the run to

=item ARRAYREF C<CASE IDS> (optional) - Array of case IDs in case you don't want to use the whole testsuite when making the build.

=back

Returns run definition HASHREF.

    $tr->createRun(1,1345,'RUN AWAY','SO FAR AWAY',22,3,[3,4,5,6]);

=cut

#If you pass an array of case ids, it implies include_all is false
sub createRun {
    my ($self,$project_id,$suite_id,$name,$desc,$milestone_id,$assignedto_id,$case_ids) = @_;
    confess("Object methods must be called by an instance") unless ref($self);
    confess("Project ID must be integer") unless $self->_checkInteger($project_id);
    confess("Suite ID must be integer") unless $self->_checkInteger($suite_id);
    confess("Name must be string") unless $self->_checkString($name);
    confess("Description must be string") unless !defined($desc) || $self->_checkString($desc);
    confess("Milestone ID must be integer") unless !defined($milestone_id) || $self->_checkInteger($milestone_id);
    confess("Assigned To ID must be integer") unless !defined($assignedto_id) || $self->_checkInteger($assignedto_id);
    confess("Case IDs must be ARRAYREF") unless !defined($case_ids) || (reftype($case_ids) || 'undef') eq 'ARRAY';

    my $stuff = {
        suite_id      => $suite_id,
        name          => $name,
        description   => $desc,
        milestone_id  => $milestone_id,
        assignedto_id => $assignedto_id,
        include_all   => defined($case_ids) ? 0 : 1,
        case_ids      => $case_ids
    };

    my $result = $self->_doRequest("index.php?/api/v2/add_run/$project_id",'POST',$stuff);
    return $result;
}

=head2 B<deleteRun (run_id)>

Deletes specified run.

=over 4

=item INTEGER C<RUN ID> - ID of run to delete.

=back

Returns BOOLEAN.

    $tr->deleteRun(1324);

=cut

sub deleteRun {
    my ($self,$run_id) = @_;
    confess("Object methods must be called by an instance") unless ref($self);
    confess("Run ID must be integer") unless $self->_checkInteger($run_id);
    my $result = $self->_doRequest("index.php?/api/v2/delete_run/$run_id",'POST');
    return $result;
}

=head2 B<getRuns (project_id)>

Get all runs for specified project.
To do this, it must make (no. of runs/250) HTTP requests.
This is due to the maximum result set limit enforced by testrail.

=over 4

=item INTEGER C<PROJECT_ID> - ID of parent project

=back

Returns ARRAYREF of run definition HASHREFs.

    $allRuns = $tr->getRuns(6969);

=cut

sub getRuns {
    my ($self,$project_id) = @_;
    confess("Object methods must be called by an instance") unless ref($self);
    confess("Project ID must be integer") unless $self->_checkInteger($project_id);
    my $initial_runs = $self->getRunsPaginated($project_id,$self->{'global_limit'},0);
    return $initial_runs unless (reftype($initial_runs) || 'undef') eq 'ARRAY';
    my $runs = [];
    push(@$runs,@$initial_runs);
    my $offset = 1;
    while (scalar(@$initial_runs) == $self->{'global_limit'}) {
        $initial_runs = $self->getRunsPaginated($project_id,$self->{'global_limit'},($self->{'global_limit'} * $offset));
        push(@$runs,@$initial_runs);
        $offset++;
    }
    return $runs;
}

=head2 B<getRunsPaginated (project_id,limit,offset)>

Get some runs for specified project.

=over 4

=item INTEGER C<PROJECT_ID> - ID of parent project

=item INTEGER C<LIMIT> - Number of runs to return.

=item INTEGER C<OFFSET> - Page of runs to return.

=back

Returns ARRAYREF of run definition HASHREFs.

    $someRuns = $tr->getRunsPaginated(6969,22,4);

=cut

sub getRunsPaginated {
    my ($self,$project_id,$limit,$offset) = @_;
    confess("Object methods must be called by an instance") unless ref($self);
    confess("Project ID must be integer") unless $self->_checkInteger($project_id);
    confess("Limit must be integer") unless !defined($limit) || $self->_checkInteger($limit);
    confess("Offset must be integer") unless !defined($offset) || $self->_checkInteger($offset);
    confess("Limit greater than ".$self->{'global_limit'}) if $limit > $self->{'global_limit'};
    my $apiurl = "index.php?/api/v2/get_runs/$project_id";
    $apiurl .= "&offset=$offset" if $offset;
    $apiurl .= "&limit=$limit" if $limit;
    return $self->_doRequest($apiurl);
}

=head2 B<getRunByName (project_id,name)>

Gets run by name.

=over 4

=item INTEGER C<PROJECT ID> - ID of parent project.

=item STRING <NAME> - Name of desired run.

=back

Returns run definition HASHREF.

    $tr->getRunByName(1,'R2');

=cut

sub getRunByName {
    my ($self,$project_id,$name) = @_;
    confess("Object methods must be called by an instance") unless ref($self);
    confess("Project ID must be integer") unless $self->_checkInteger($project_id);
    confess("Run name must be string") unless $self->_checkString($name);
    my $runs = $self->getRuns($project_id);
    return -500 if !$runs || (reftype($runs) || 'undef') ne 'ARRAY';
    foreach my $run (@$runs) {
        return $run if $run->{'name'} eq $name;
    }
    return 0;
}

=head2 B<getRunByID (run_id)>

Gets run by ID.

=over 4

=item INTEGER C<RUN ID> - ID of desired run.

=back

Returns run definition HASHREF.

    $tr->getRunByID(7779311);

=cut

sub getRunByID {
    my ($self,$run_id) = @_;
    confess("Object methods must be called by an instance") unless ref($self);
    confess("Run ID must be integer") unless $self->_checkInteger($run_id);
    return $self->_doRequest("index.php?/api/v2/get_run/$run_id");
}

=head2 B<closeRun (run_id)>

Close the specified run.

=over 4

=item INTEGER C<RUN ID> - ID of desired run.

=back

Returns run definition HASHREF on success, false on failure.

    $tr->closeRun(90210);

=cut

sub closeRun {
    my ($self,$run_id) = @_;
    confess("Object methods must be called by an instance") unless ref($self);
    confess("Run ID must be integer") unless $self->_checkInteger($run_id);
    return $self->_doRequest("index.php?/api/v2/close_run/$run_id",'POST');
}

=head2 B<getRunSummary(runs)>

Returns array of hashrefs describing the # of tests in the run(s) with the available statuses.
Translates custom_statuses into their system names for you.

=over 4

=item ARRAY C<RUNS> - runs obtained from getRun* or getChildRun* methods.

=back

Returns ARRAY of run HASHREFs with the added key 'run_status' holding a hashref where status_name => count.

    $tr->getRunSummary($run,$run2);

=cut

sub getRunSummary {
    my ($self,@runs) = @_;
    confess("Object methods must be called by an instance") unless ref($self);
    confess("All Plans passed must be HASHREFs") unless scalar( grep {(reftype($_) || 'undef') eq 'HASH'} @runs ) == scalar(@runs);

    #Translate custom statuses
    my $statuses = $self->getPossibleTestStatuses();
    my %shash;
    #XXX so, they do these tricks with the status names, see...so map the counts to their relevant status ids.
    @shash{map { ( $_->{'id'} < 6 ) ? $_->{'name'}."_count" : "custom_status".($_->{'id'} - 5)."_count" } @$statuses } = map { $_->{'id'} } @$statuses;
    my @sname;
    #Create listing of keys/values
    @runs = map {
        my $run = $_;
        @{$run->{statuses}}{grep {$_ =~ m/_count$/} keys(%$run)} = grep {$_ =~ m/_count$/} keys(%$run);
        foreach my $status (keys(%{$run->{'statuses'}})) {
            next if !exists($shash{$status});
            @sname = grep {exists($shash{$status}) && $_->{'id'} == $shash{$status}} @$statuses;
            $run->{'statuses_clean'}->{$sname[0]->{'name'}} = $run->{$status};
        }
        $run;
    } @runs;

    return map { {'id' => $_->{'id'}, 'name' => $_->{'name'}, 'run_status' => $_->{'statuses_clean'}, 'config_ids' => $_->{'config_ids'} } } @runs;

}

=head1 RUN AS CHILD OF PLAN METHODS

=head2 B<getChildRuns(plan)>

Extract the child runs from a plan.  Convenient, as the structure of this hash is deep, and correct error handling can be tedious.

=over 4

=item HASHREF C<PLAN> - Test Plan definition HASHREF returned by any of the PLAN methods below.

=back

Returns ARRAYREF of run definition HASHREFs.  Returns 0 upon failure to extract the data.

=cut

sub getChildRuns {
    my ($self,$plan) = @_;
    confess("Object methods must be called by an instance") unless ref($self);
    confess("Plan must be HASHREF") unless defined($plan) && (reftype($plan) || 'undef') eq 'HASH';
    return 0 unless defined($plan->{'entries'}) && (reftype($plan->{'entries'}) || 'undef') eq 'ARRAY';
    return 0 unless defined($plan->{'entries'}) && (reftype($plan->{'entries'}) || 'undef') eq 'ARRAY';
    my $entries = $plan->{'entries'};
    my $plans = [];
    foreach my $entry (@$entries) {
        push(@$plans,@{$entry->{'runs'}}) if defined($entry->{'runs'}) && ((reftype($entry->{'runs'}) || 'undef') eq 'ARRAY')
    }
    return $plans;
}

=head2 B<getChildRunByName(plan,name,configurations)>

=over 4

=item HASHREF C<PLAN> - Test Plan definition HASHREF returned by any of the PLAN methods below.

=item STRING C<NAME> - Name of run to search for within plan.

=item ARRAYREF C<CONFIGURATIONS> (optional) - Names of configurations to filter runs by.

=back

Returns run definition HASHREF, or false if no such run is found.
Convenience method using getChildRuns.

Will throw a fatal error if one or more of the configurations passed does not exist in the project.

=cut

sub getChildRunByName {
    my ($self,$plan,$name,$configurations) = @_;
    confess("Object methods must be called by an instance") unless ref($self);
    confess("Plan must be HASHREF") unless defined($plan) && (reftype($plan) || 'undef') eq 'HASH';
    confess("Run name must be STRING") unless $self->_checkString($name);
    confess("Configurations must be ARRAYREF") unless !defined($configurations) || (reftype($configurations) || 'undef') eq 'ARRAY';
    my $runs = $self->getChildRuns($plan);
    return 0 if !$runs;

    my @pconfigs = ();

    #Figure out desired config IDs
    if (defined $configurations) {
        my $avail_configs = $self->getConfigurations($plan->{'project_id'});
        my ($cname);
        @pconfigs = map {$_->{'id'}} grep { $cname = $_->{'name'}; grep {$_ eq $cname} @$configurations } @$avail_configs; #Get a list of IDs from the names passed
    }
    confess("One or more configurations passed does not exist in your project!") if defined($configurations) && (scalar(@pconfigs) != scalar(@$configurations));

    my $found;
    foreach my $run (@$runs) {
        next if $run->{name} ne $name;
        next if scalar(@pconfigs) != scalar(@{$run->{'config_ids'}});

        #Compare run config IDs against desired, invalidate run if all conditions not satisfied
        $found = 0;
        foreach my $cid (@{$run->{'config_ids'}}) {
            $found++ if grep {$_ == $cid} @pconfigs;
        }

        return $run if $found == scalar(@{$run->{'config_ids'}});
    }
    return 0;
}

=head1 PLAN METHODS

=head2 B<createPlan (project_id,name,description,milestone_id,entries)>

Create a test plan.

=over 4

=item INTEGER C<PROJECT ID> - ID of parent project.

=item STRING C<NAME> - Name of plan

=item STRING C<DESCRIPTION> (optional) - Description of plan

=item INTEGER C<MILESTONE_ID> (optional) - ID of milestone

=item ARRAYREF C<ENTRIES> (optional) - New Runs to initially populate the plan with -- See TestRail API documentation for more advanced inputs here.

=back

Returns test plan definition HASHREF, or false on failure.

    $entries = {
        suite_id => 345,
        include_all => 1,
        assignedto_id => 1
    }

    $tr->createPlan(1,'Gosplan','Robo-Signed Soviet 5-year plan',22,$entries);

=cut

sub createPlan {
    my ($self,$project_id,$name,$desc,$milestone_id,$entries) = @_;
    confess("Object methods must be called by an instance") unless ref($self);
    confess("Project ID must be integer") unless $self->_checkInteger($project_id);
    confess("Plan name must be string") unless $self->_checkString($name);
    confess("Description must be string") unless !defined($desc) || $self->_checkString($desc);
    confess("Milestone ID must be integer") unless !defined($milestone_id) || $self->_checkInteger($milestone_id);
    confess("Entries must be ARRAYREF") unless !defined($entries) || (reftype($entries) || 'undef') eq 'ARRAY';

    my $stuff = {
        name          => $name,
        description   => $desc,
        milestone_id  => $milestone_id,
        entries       => $entries
    };

    my $result = $self->_doRequest("index.php?/api/v2/add_plan/$project_id",'POST',$stuff);
    return $result;
}

=head2 B<deletePlan (plan_id)>

Deletes specified plan.

=over 4

=item INTEGER C<PLAN ID> - ID of plan to delete.

=back

Returns BOOLEAN.

    $tr->deletePlan(8675309);

=cut

sub deletePlan {
    my ($self,$plan_id) = @_;
    confess("Object methods must be called by an instance") unless ref($self);
    confess("Plan ID must be integer") unless $self->_checkInteger($plan_id);
    my $result = $self->_doRequest("index.php?/api/v2/delete_plan/$plan_id",'POST');
    return $result;
}

=head2 B<getPlans (project_id)>

Gets all test plans in specified project.
Like getRuns, must make multiple HTTP requests when the number of results exceeds 250.

=over 4

=item INTEGER C<PROJECT ID> - ID of parent project.

=back

Returns ARRAYREF of all plan definition HASHREFs in a project.

    $tr->getPlans(8);

Does not contain any information about child test runs.
Use getPlanByID or getPlanByName if you want that, in particular if you are interested in using getChildRunByName.

=cut

sub getPlans {
    my ($self,$project_id) = @_;
    confess("Object methods must be called by an instance") unless ref($self);
    confess("Project ID must be integer") unless $self->_checkInteger($project_id);
    my $initial_plans = $self->getPlansPaginated($project_id,$self->{'global_limit'},0);
    return $initial_plans unless (reftype($initial_plans) || 'undef') eq 'ARRAY';
    my $plans = [];
    push(@$plans,@$initial_plans);
    my $offset = 1;
    while (scalar(@$initial_plans) == $self->{'global_limit'}) {
        $initial_plans = $self->getPlansPaginated($project_id,$self->{'global_limit'},($self->{'global_limit'} * $offset));
        push(@$plans,@$initial_plans);
        $offset++;
    }
    return $plans;
}

=head2 B<getPlansPaginated (project_id,limit,offset)>

Get some plans for specified project.

=over 4

=item INTEGER C<PROJECT_ID> - ID of parent project

=item INTEGER C<LIMIT> - Number of plans to return.

=item INTEGER C<OFFSET> - Page of plans to return.

=back

Returns ARRAYREF of plan definition HASHREFs.

    $someRuns = $tr->getPlansPaginated(6969,222,44);

=cut

sub getPlansPaginated {
    my ($self,$project_id,$limit,$offset) = @_;
    confess("Object methods must be called by an instance") unless ref($self);
    confess("Project ID must be integer") unless $self->_checkInteger($project_id);
    confess("Limit must be integer") unless !defined($limit) || $self->_checkInteger($limit);
    confess("Offset must be integer") unless !defined($offset) || $self->_checkInteger($offset);
    confess("Limit greater than ".$self->{'global_limit'}) if $limit > $self->{'global_limit'};
    my $apiurl = "index.php?/api/v2/get_plans/$project_id";
    $apiurl .= "&offset=$offset" if $offset;
    $apiurl .= "&limit=$limit" if $limit;
    return $self->_doRequest($apiurl);
}

=head2 B<getPlanByName (project_id,name)>

Gets specified plan by name.

=over 4

=item INTEGER C<PROJECT ID> - ID of parent project.

=item STRING C<NAME> - Name of test plan.

=back

Returns plan definition HASHREF.

    $tr->getPlanByName(8,'GosPlan');

=cut

sub getPlanByName {
    my ($self,$project_id,$name) = @_;
    confess("Object methods must be called by an instance") unless ref($self);
    confess("Project ID must be integer") unless $self->_checkInteger($project_id);
    confess("Plan name must be string") unless $self->_checkString($name);
    my $plans = $self->getPlans($project_id);
    return -500 if !$plans || (reftype($plans) || 'undef') ne 'ARRAY';
    foreach my $plan (@$plans) {
        if ($plan->{'name'} eq $name) {
            return $self->getPlanByID($plan->{'id'});
        }
    }
    return 0;
}

=head2 B<getPlanByID (plan_id)>

Gets specified plan by ID.

=over 4

=item INTEGER C<PLAN ID> - ID of plan.

=back

Returns plan definition HASHREF.

    $tr->getPlanByID(2);

=cut

sub getPlanByID {
    my ($self,$plan_id) = @_;
    confess("Object methods must be called by an instance") unless ref($self);
    confess("Plan ID must be integer") unless $self->_checkInteger($plan_id);
    return $self->_doRequest("index.php?/api/v2/get_plan/$plan_id");
}

=head2 B<getPlanSummary(plan_ID)>

Returns hashref describing the various pass, fail, etc. percentages for tests in the plan.
The 'totals' key has total cases in each status ('status' => count)
The 'percentages' key has the same, but as a percentage of the total.

=over 4

=item SCALAR C<plan_ID> - ID of your test plan.

=back

    $tr->getPlanSummary($plan_id);

=cut

sub getPlanSummary {
    my ($self,$plan_id) = @_;
    confess("Object methods must be called by an instance") unless ref($self);
    confess("Plan ID must be integer") unless $self->_checkInteger($plan_id);
    my $runs = $self->getPlanByID( $plan_id );
    $runs = $self->getChildRuns( $runs );
    @$runs = $self->getRunSummary(@{$runs});
    my $total_sum = 0;
    my $ret = { plan => $plan_id };

    #Compile totals
    foreach my $summary ( @$runs ) {
        my @elems = keys( %{ $summary->{'run_status'} } );
        foreach my $key (@elems) {
            $ret->{'totals'}->{$key} = 0 if !defined $ret->{'totals'}->{$key};
            $ret->{'totals'}->{$key} += $summary->{'run_status'}->{$key};
            $total_sum += $summary->{'run_status'}->{$key};
        }
    }

    #Compile percentages
    foreach my $key (keys(%{$ret->{'totals'}})) {
        next if grep {$_ eq $key} qw{plan configs percentages};
        $ret->{"percentages"}->{$key} = sprintf( "%.2f%%", ( $ret->{'totals'}->{$key} / $total_sum ) * 100 );
    }

    return $ret;
}

=head2 B<createRunInPlan (plan_id,suite_id,name,description,milestone_id,assigned_to_id,config_ids,case_ids)>

Create a run in a plan.

=over 4

=item INTEGER C<PLAN ID> - ID of parent project.

=item INTEGER C<SUITE ID> - ID of suite to base run on

=item STRING C<NAME> - Name of run

=item INTEGER C<ASSIGNED TO ID> (optional) - User to assign the run to

=item ARRAYREF C<CONFIG IDS> (optional) - Array of Configuration IDs (see getConfigurations) to apply to the created run

=item ARRAYREF C<CASE IDS> (optional) - Array of case IDs in case you don't want to use the whole testsuite when making the build.

=back

Returns run definition HASHREF.

    $tr->createRun(1,1345,'PlannedRun',3,[1,4,77],[3,4,5,6]);

=cut

#If you pass an array of case ids, it implies include_all is false
sub createRunInPlan {
    my ($self,$plan_id,$suite_id,$name,$assignedto_id,$config_ids,$case_ids) = @_;
    confess("Object methods must be called by an instance") unless ref($self);
    confess("Plan ID must be integer") unless $self->_checkInteger($plan_id);
    confess("Suite ID must be integer") unless $self->_checkInteger($suite_id);
    confess("Name must be string") unless $self->_checkString($name);
    confess("Assigned To ID must be integer") unless !defined($assignedto_id) || $self->_checkInteger($assignedto_id);
    confess("Config IDs must be ARRAYREF") unless !defined($config_ids) || (reftype($config_ids) || 'undef') eq 'ARRAY';
    confess("Case IDs must be ARRAYREF") unless !defined($case_ids) || (reftype($case_ids) || 'undef') eq 'ARRAY';

    my $runs = [
        {
            config_ids  => $config_ids,
            include_all => defined($case_ids) ? 0 : 1,
            case_ids    => $case_ids
        }
    ];

    my $stuff = {
        suite_id      => $suite_id,
        name          => $name,
        assignedto_id => $assignedto_id,
        include_all   => defined($case_ids) ? 0 : 1,
        case_ids      => $case_ids,
        config_ids    => $config_ids,
        runs          => $runs
    };
    my $result = $self->_doRequest("index.php?/api/v2/add_plan_entry/$plan_id",'POST',$stuff);
    return $result;
}

=head2 B<closePlan (plan_id)>

Close the specified plan.

=over 4

=item INTEGER C<PLAN ID> - ID of desired plan.

=back

Returns plan definition HASHREF on success, false on failure.

    $tr->closePlan(75020);

=cut

sub closePlan {
    my ($self,$plan_id) = @_;
    confess("Object methods must be called by an instance") unless ref($self);
    confess("Plan ID must be integer") unless $self->_checkInteger($plan_id);
    return $self->_doRequest("index.php?/api/v2/close_plan/$plan_id",'POST');
}

=head1 MILESTONE METHODS

=head2 B<createMilestone (project_id,name,description,due_on)>

Create a milestone.

=over 4

=item INTEGER C<PROJECT ID> - ID of parent project.

=item STRING C<NAME> - Name of milestone

=item STRING C<DESCRIPTION> (optional) - Description of milestone

=item INTEGER C<DUE_ON> - Date at which milestone should be completed. Unix Timestamp.

=back

Returns milestone definition HASHREF, or false on failure.

    $tr->createMilestone(1,'Patriotic victory of world perlism','Accomplish by Robo-Signed Soviet 5-year plan',time()+157788000);

=cut

sub createMilestone {
    my ($self,$project_id,$name,$desc,$due_on) = @_;
    confess("Object methods must be called by an instance") unless ref($self);
    confess("Project ID must be integer") unless $self->_checkInteger($project_id);
    confess("Name must be string") unless $self->_checkString($name);
    confess("Description must be string") unless !defined($desc) || $self->_checkString($desc);
    confess("Due on must be unix time stamp (integer)") unless !defined($due_on) || $self->_checkInteger($due_on);

    my $stuff = {
        name        => $name,
        description => $desc,
        due_on      => $due_on # unix timestamp
    };

    my $result = $self->_doRequest("index.php?/api/v2/add_milestone/$project_id",'POST',$stuff);
    return $result;
}

=head2 B<deleteMilestone (milestone_id)>

Deletes specified milestone.

=over 4

=item INTEGER C<MILESTONE ID> - ID of milestone to delete.

=back

Returns BOOLEAN.

    $tr->deleteMilestone(86);

=cut

sub deleteMilestone {
    my ($self,$milestone_id) = @_;
    confess("Object methods must be called by an instance") unless ref($self);
    confess("Milestone ID must be integer") unless $self->_checkInteger($milestone_id);
    my $result = $self->_doRequest("index.php?/api/v2/delete_milestone/$milestone_id",'POST');
    return $result;
}

=head2 B<getMilestones (project_id)>

Get milestones for some project.

=over 4

=item INTEGER C<PROJECT ID> - ID of parent project.

=back

Returns ARRAYREF of milestone definition HASHREFs.

    $tr->getMilestones(8);


=cut

sub getMilestones {
    my ($self,$project_id) = @_;
    confess("Object methods must be called by an instance") unless ref($self);
    confess("Project ID must be integer") unless $self->_checkInteger($project_id);
    return $self->_doRequest("index.php?/api/v2/get_milestones/$project_id");
}

=head2 B<getMilestoneByName (project_id,name)>

Gets specified milestone by name.

=over 4

=item INTEGER C<PROJECT ID> - ID of parent project.

=item STRING C<NAME> - Name of milestone.

=back

Returns milestone definition HASHREF.

    $tr->getMilestoneByName(8,'whee');

=cut

sub getMilestoneByName {
    my ($self,$project_id,$name) = @_;
    confess("Object methods must be called by an instance") unless ref($self);
    confess("Project ID must be integer") unless $self->_checkInteger($project_id);
    confess("Milestone name must be string") unless $self->_checkString($name);
    my $milestones = $self->getMilestones($project_id);
    return -500 if !$milestones || (reftype($milestones) || 'undef') ne 'ARRAY';
    foreach my $milestone (@$milestones) {
        return $milestone if $milestone->{'name'} eq $name;
    }
    return 0;
}

=head2 B<getMilestoneByID (milestone_id)>

Gets specified milestone by ID.

=over 4

=item INTEGER C<MILESTONE ID> - ID of milestone.

=back

Returns milestone definition HASHREF.

    $tr->getMilestoneByID(2);

=cut

sub getMilestoneByID {
    my ($self,$milestone_id) = @_;
    confess("Object methods must be called by an instance") unless ref($self);
    confess("Milestone ID must be integer") unless $self->_checkInteger($milestone_id);
    return $self->_doRequest("index.php?/api/v2/get_milestone/$milestone_id");
}

=head1 TEST METHODS

=head2 B<getTests (run_id,status_ids,assignedto_ids)>

Get tests for some run.  Optionally filter by provided status_ids and assigned_to ids.

=over 4

=item INTEGER C<RUN ID> - ID of parent run.

=item ARRAYREF C<STATUS IDS> (optional) - IDs of relevant test statuses to filter by.  Get with getPossibleTestStatuses.

=item ARRAYREF C<ASSIGNEDTO IDS> (optional) - IDs of users assigned to test to filter by.  Get with getUsers.

=back

Returns ARRAYREF of test definition HASHREFs.

    $tr->getTests(8,[1,2,3],[2]);

=cut

sub getTests {
    my ($self,$run_id,$status_ids,$assignedto_ids) = @_;
    confess("Object methods must be called by an instance") unless ref($self);
    confess("Run ID must be integer") unless $self->_checkInteger($run_id);
    confess("Status IDs must be ARRAYREF") unless !defined($status_ids) || ( reftype($status_ids) || 'undef' ) eq 'ARRAY';
    confess("Assigned to IDs must be ARRAYREF") unless !defined($assignedto_ids) || ( reftype($assignedto_ids) || 'undef' ) eq 'ARRAY';

    my $query_string = '';
    $query_string = '&status_id='.join(',',@$status_ids) if defined($status_ids) && scalar(@$status_ids);
    my $results = $self->_doRequest("index.php?/api/v2/get_tests/$run_id$query_string");
    @$results = grep {my $aid = $_->{'assignedto_id'}; grep {defined($aid) && $aid == $_} @$assignedto_ids} @$results if defined($assignedto_ids) && scalar(@$assignedto_ids);
    return $results;
}

=head2 B<getTestByName (run_id,name)>

Gets specified test by name.

=over 4

=item INTEGER C<RUN ID> - ID of parent run.

=item STRING C<NAME> - Name of milestone.

=back

Returns test definition HASHREF.

    $tr->getTestByName(36,'wheeTest');

=cut

sub getTestByName {
    my ($self,$run_id,$name) = @_;
    confess("Object methods must be called by an instance") unless ref($self);
    confess("Run ID must be integer") unless $self->_checkInteger($run_id);
    confess("Test name must be string") unless $self->_checkString($name);
    my $tests = $self->getTests($run_id);
    return -500 if !$tests || (reftype($tests) || 'undef') ne 'ARRAY';
    foreach my $test (@$tests) {
        return $test if $test->{'title'} eq $name;
    }
    return 0;
}

=head2 B<getTestByID (test_id)>

Gets specified test by ID.

=over 4

=item INTEGER C<TEST ID> - ID of test.

=back

Returns test definition HASHREF.

    $tr->getTestByID(222222);

=cut

sub getTestByID {
    my ($self,$test_id) = @_;
    confess("Object methods must be called by an instance") unless ref($self);
    confess("Test ID must be integer") unless $self->_checkInteger($test_id);
    return $self->_doRequest("index.php?/api/v2/get_test/$test_id");
}

=head2 B<getTestResultFields()>

Gets custom fields that can be set for tests.

Returns ARRAYREF of result definition HASHREFs.

=cut

sub getTestResultFields {
    my $self = shift;
    confess("Object methods must be called by an instance") unless ref($self);
    return $self->{'tr_fields'} if defined($self->{'tr_fields'}); #cache
    $self->{'tr_fields'} = $self->_doRequest('index.php?/api/v2/get_result_fields');
    return $self->{'tr_fields'};
}

=head2 B<getTestResultFieldByName(SYSTEM_NAME,PROJECT_ID)>

Gets a test result field by it's system name.  Optionally filter by project ID.

=over 4

=item B<SYSTEM NAME> - STRING: system name of a result field.

=item B<PROJECT ID> - INTEGER (optional): Filter by whether or not the field is enabled for said project

=back

=cut

sub getTestResultFieldByName {
    my ($self,$system_name,$project_id) = @_;
    confess("Object methods must be called by an instance") unless ref($self);
    confess("System name must be string") unless $self->_checkString($system_name);
    my @candidates = grep { $_->{'name'} eq $system_name} @{$self->getTestResultFields()};
    return 0 if !scalar(@candidates); #No such name
    return -1 if ref($candidates[0]) ne 'HASH';
    return -2 if ref($candidates[0]->{'configs'}) ne 'ARRAY' && !scalar(@{$candidates[0]->{'configs'}}); #bogofilter

    #Give it to the user
    my $ret = $candidates[0]; #copy/save for later
    return $ret if !defined($project_id);

    #Filter by project ID
    foreach my $config (@{$candidates[0]->{'configs'}}) {
        return $ret if ( grep { $_ == $project_id} @{ $config->{'context'}->{'project_ids'} } )
    }

    return -3;
}

=head2 B<getPossibleTestStatuses()>

Gets all possible statuses a test can be set to.

Returns ARRAYREF of status definition HASHREFs.

=cut

sub getPossibleTestStatuses {
    my $self = shift;
    confess("Object methods must be called by an instance") unless ref($self);
    return $self->_doRequest('index.php?/api/v2/get_statuses');
}

=head2 statusNamesToIds(names)

Convenience method to translate a list of statuses to TestRail status IDs.
The names referred to here are 'internal names' rather than the labels shown in TestRail.

=over 4

=item ARRAY C<NAMES> - Array of status names to translate to IDs.

=back

Returns ARRAY of status IDs.

Throws an exception in the case of one (or more) of the names not corresponding to a valid test status.

=cut

sub statusNamesToIds {
    my ($self,@names) = @_;
    confess("Object methods must be called by an instance") unless ref($self);
    confess("At least one status name must be provided") if !scalar(@names);
    my @ret = grep {defined $_} map {my $status = $_; my @list = grep {$status->{'name'} eq $_} @names; scalar(@list) ? $status->{'id'} : undef} @{$self->getPossibleTestStatuses()};
    confess("One or more status names provided does not exist in TestRail.") unless scalar(@names) == scalar(@ret);
    return @ret;
};

=head2 B<createTestResults(test_id,status_id,comment,options,custom_options)>

Creates a result entry for a test.

=over 4

=item INTEGER C<TEST_ID> - ID of desired test

=item INTEGER C<STATUS_ID> - ID of desired test result status

=item STRING C<COMMENT> (optional) - Any comments about this result

=item HASHREF C<OPTIONS> (optional) - Various "Baked-In" options that can be set for test results.  See TR docs for more information.

=item HASHREF C<CUSTOM OPTIONS> (optional) - Options to set for custom fields.  See buildStepResults for a simple way to post up custom steps.

=back

Returns result definition HASHREF.

    $options = {
        elapsed => '30m 22s',
        defects => ['TSR-3','BOOM-44'],
        version => '6969'
    };

    $custom_options = {
        step_results => [
            {
                content   => 'Step 1',
                expected  => "Bought Groceries",
                actual    => "No Dinero!",
                status_id => 2
            },
            {
                content   => 'Step 2',
                expected  => 'Ate Dinner',
                actual    => 'Went Hungry',
                status_id => 2
            }
        ]
    };

    $res = $tr->createTestResults(1,2,'Test failed because it was all like WAAAAAAA when I poked it',$options,$custom_options);

=cut

sub createTestResults {
    my ($self,$test_id,$status_id,$comment,$opts,$custom_fields) = @_;
    confess("Object methods must be called by an instance") unless ref($self);
    confess("Test ID must be integer") unless $self->_checkInteger($test_id);
    confess("Status ID must be integer") unless $self->_checkInteger($status_id);
    confess("Comment must be string") unless !defined($comment) || $self->_checkString($comment);
    confess("Options must be HASHREF") unless !defined($opts) || (reftype($opts) || 'undef') eq 'HASH';
    confess("Custom Options must be HASHREF") unless !defined($custom_fields) || (reftype($custom_fields) || 'undef') eq 'HASH';
    my $stuff = {
        status_id     => $status_id,
        comment       => $comment
    };

    #Handle options
    if (defined($opts) && reftype($opts) eq 'HASH') {
        $stuff->{'version'}       = defined($opts->{'version'}) ? $opts->{'version'} : undef;
        $stuff->{'elapsed'}       = defined($opts->{'elapsed'}) ? $opts->{'elapsed'} : undef;
        $stuff->{'defects'}       = defined($opts->{'defects'}) ? join(',',@{$opts->{'defects'}}) : undef;
        $stuff->{'assignedto_id'} = defined($opts->{'assignedto_id'}) ? $opts->{'assignedto_id'} : undef;
    }

    #Handle custom fields
    if (defined($custom_fields) && reftype($custom_fields) eq 'HASH') {
        foreach my $field (keys(%$custom_fields)) {
            $stuff->{"custom_$field"} = $custom_fields->{$field};
        }
    }

    return $self->_doRequest("index.php?/api/v2/add_result/$test_id",'POST',$stuff);
}

=head2 bulkAddResults(run_id,results)

Add multiple results to a run, where each result is a HASHREF with keys as outlined in the get_results API call documentation.

=over 4

=item INTEGER C<RUN_ID> - ID of desired run to add results to

=item ARRAYREF C<RESULTS> - Array of result objects to upload.

=back

Returns ARRAYREF of result definition HASHREFs.

=cut

sub bulkAddResults {
    my ($self, $run_id, $results) = @_;
    confess("Object methods must be called by an instance") unless ref($self);
    confess("Run ID must be integer") unless $self->_checkInteger($run_id);
    confess("results must be arrayref") unless ( reftype($results) || 'undef' ) eq 'ARRAY';
    return $self->_doRequest("index.php?/api/v2/add_results/$run_id", 'POST', { 'results' => $results });
}

=head2 B<getTestResults(test_id,limit,offset)>

Get the recorded results for desired test, limiting output to 'limit' entries.

=over 4

=item INTEGER C<TEST_ID> - ID of desired test

=item POSITIVE INTEGER C<LIMIT> (OPTIONAL) - provide no more than this number of results.

=item INTEGER C<OFFSET> (OPTIONAL) - Offset to begin viewing result set at.

=back

Returns ARRAYREF of result definition HASHREFs.

=cut

sub getTestResults {
    my ($self,$test_id,$limit,$offset) = @_;
    confess("Object methods must be called by an instance") unless ref($self);
    confess("Test ID must be positive integer") unless $self->_checkInteger($test_id);
    confess("Result limitation must be positive integer") unless !defined($limit) || ($self->_checkInteger($limit) && $limit > 0);
    confess("Result offset must be integer") unless !defined($offset) || $self->_checkInteger($offset);
    my $url = "index.php?/api/v2/get_results/$test_id";
    $url .= "&limit=$limit" if defined($limit);
    $url .= "&offset=$offset" if defined($offset);
    return $self->_doRequest($url);
}

=head1 CONFIGURATION METHODS

=head2 B<getConfigurationGroups(project_id)>

Gets the available configuration groups for a project, with their configurations as children.
Basically a direct wrapper of The 'get_configs' api call, with caching tacked on.

=over 4

=item INTEGER C<PROJECT_ID> - ID of relevant project

=back

Returns ARRAYREF of configuration group definition HASHREFs.

=cut

sub getConfigurationGroups {
    my ($self,$project_id) = @_;
    confess("Object methods must be called by an instance") unless ref($self);
    confess("Project ID must be positive integer") unless $self->_checkInteger($project_id);
    my $url = "index.php?/api/v2/get_configs/$project_id";
    return $self->{'configurations'}->{$project_id} if $self->{'configurations'}->{$project_id}; #cache this since we can't change it with the API
    $self->{'configurations'}->{$project_id} = $self->_doRequest($url);
    return $self->{'configurations'}->{$project_id};
}

=head2 B<getConfigurations(project_id)>

Gets the available configurations for a project.
Mostly for convenience (no need to write a boilerplate loop over the groups).

=over 4

=item INTEGER C<PROJECT_ID> - ID of relevant project

=back

Returns ARRAYREF of configuration definition HASHREFs.
Returns result of getConfigurationGroups (likely -500) in the event that call fails.

=cut

sub getConfigurations {
    my ($self,$project_id) = @_;
    confess("Object methods must be called by an instance") unless ref($self);
    confess("Project ID must be positive integer") unless $self->_checkInteger($project_id);
    my $cgroups = $self->getConfigurationGroups($project_id);
    my $configs = [];
    return $cgroups unless (reftype($cgroups) || 'undef') eq 'ARRAY';
    foreach my $cfg (@$cgroups) {
        push(@$configs, @{$cfg->{'configs'}});
    }
    return $configs;
}

=head2 B<translateConfigNamesToIds(project_id,configs)>

Transforms a list of configuration names into a list of config IDs.

=over 4

=item INTEGER C<PROJECT_ID> - Relevant project ID for configs.

=item ARRAYREF C<CONFIGS> - Array ref of config names

=back

Returns ARRAYREF of configuration names, with undef values for unknown configuration names.

=cut

sub translateConfigNamesToIds {
    my ($self,$project_id,$configs) = @_;
    confess("Object methods must be called by an instance") unless ref($self);
    confess("Project ID must be positive integer") unless $self->_checkInteger($project_id);
    confess("Configs must be arrayref") unless (reftype($configs) || 'undef') eq 'ARRAY';
    return [] if !scalar(@$configs);
    my $existing_configs = $self->getConfigurations($project_id);
    return map {undef} @$configs if (reftype($existing_configs) || 'undef') ne 'ARRAY';
    my @ret = map {my $name = $_; my @candidates = grep { $name eq $_->{'name'} } @$existing_configs; scalar(@candidates) ? $candidates[0]->{'id'} : undef } @$configs;
    return \@ret;
}

=head1 STATIC METHODS

=head2 B<buildStepResults(content,expected,actual,status_id)>

Convenience method to build the stepResult hashes seen in the custom options for getTestResults.

=over 4

=item STRING C<CONTENT> (optional) - The step itself.

=item STRING C<EXPECTED> (optional) - Expected result of test step.

=item STRING C<ACTUAL> (optional) - Actual result of test step

=item INTEGER C<STATUS ID> (optional) - Status ID of result

=back

=cut

#Convenience method for building stepResults
sub buildStepResults {
    my ($content,$expected,$actual,$status_id) = @_;
    return {
        content   => $content,
        expected  => $expected,
        actual    => $actual,
        status_id => $status_id
    };
}


#Type checks

sub _checkInteger {
    shift;
    my $integer = shift;
    return ( defined $integer && looks_like_number($integer) && int($integer) == $integer );
}

sub _checkString {
  shift;
  my $str = shift;
  return ( defined($str) && !ref($str) );
}

1;

__END__

=head1 SEE ALSO

L<HTTP::Request>

L<LWP::UserAgent>

L<JSON::MaybeXS>

L<http://docs.gurock.com/testrail-api2/start>

=head1 SPECIAL THANKS

Thanks to cPanel Inc, for graciously funding the creation of this module.
