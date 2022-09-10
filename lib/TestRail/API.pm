# ABSTRACT: Provides an interface to TestRail's REST api via HTTP
# PODNAME: TestRail::API

package TestRail::API;

=head1 SYNOPSIS

    use TestRail::API;

    my ($username,$password,$host) = ('foo','bar','http://testrail.baz.foo');
    my $tr = TestRail::API->new($host, $username, $password);

=head1 DESCRIPTION

C<TestRail::API> provides methods to access an existing TestRail account using API v2.  You can then do things like look up tests, set statuses and create runs from lists of cases.
It is by no means exhaustively implementing every TestRail API function.

=head1 IMPORTANT

All the methods aside from the constructor should not die, but return a false value upon failure (see exceptions below).
When the server is not responsive, expect a -500 response, and retry accordingly by setting the num_tries parameter in the constructor.

Also, all *ByName methods are vulnerable to duplicate naming issues.  Try not to use the same name for:

    * projects
    * testsuites within the same project
    * sections within the same testsuite that are peers
    * test cases
    * test plans and runs outside of plans which are not completed
    * configurations

To do so will result in the first of said item found being returned rather than an array of possibilities to choose from.

There are two exceptions to this, in the case of 401 and 403 responses, as these failing generally mean your program has no chance of success anyways.

=cut

use 5.010;

use strict;
use warnings;


use Carp qw{cluck confess};
use Scalar::Util qw{reftype looks_like_number};
use Clone 'clone';
use Try::Tiny;

use Types::Standard qw( slurpy ClassName Object Str Int Bool HashRef ArrayRef Maybe Optional);
use Type::Params qw( compile );

use JSON::MaybeXS 1.001000 ();
use HTTP::Request;
use LWP::UserAgent;
use HTTP::CookieJar::LWP;
use Data::Validate::URI qw{is_uri};
use List::Util 1.33;
use Encode ();

=head1 CONSTRUCTOR

=head2 B<new (api_url, user, password, encoding, debug, do_post_redirect)>

Creates new C<TestRail::API> object.

=over 4

=item STRING C<API URL> - base url for your TestRail api server.

=item STRING C<USER> - Your TestRail User.

=item STRING C<PASSWORD> - Your TestRail password, or a valid API key (TestRail 4.2 and above).

=item STRING C<ENCODING> - The character encoding used by the caller.  Defaults to 'UTF-8', see L<Encode::Supported> and  for supported encodings.

=item BOOLEAN C<DEBUG> (optional) - Print the JSON responses from TestRail with your requests. Default false.

=item BOOLEAN C<DO_POST_REDIRECT> (optional) - Follow redirects on POST requests (most add/edit/delete calls are POSTs).  Default false.

=item INTEGER C<MAX_TRIES> (optional) - Try requests up to X number of times if they fail with anything other than 401/403.  Useful with flaky external authenticators, or timeout issues.  Default 1.

=item HASHREF C<USER_FETCH_OPTS> (optional) - Options relating to getUsers call done during new:

=over 4

=item BOOLEAN C<skip_userfetch> - Skip fetching all TR users during construction. Default false.

This will save you some time on servers with quite a few users, especially if you don't
particularly have a need to know about things related to TR users themselves.
If you do need this info, you don't really save any time, however, as it will fetch them
in the relevant subroutines that need this information.

Also, on newer versions of TestRail, user fetching is not possible unless you either:
* Are an administrator on the server
* Provide the project_id (https://www.gurock.com/testrail/docs/api/reference/users)

=item STRING C<project_id> - String or number corresponding to a project ID to use when fetching users.

=back

=back

Returns C<TestRail::API> object if login is successful.

    my $tr = TestRail::API->new('http://tr.test/testrail', 'moo','M000000!');

Dies on all communication errors with the TestRail server.
Does not do above checks if debug is passed.

=cut

sub new {
    state $check = compile(ClassName, Str, Str, Str, Optional[Maybe[Str]], Optional[Maybe[Bool]], Optional[Maybe[Bool]], Optional[Maybe[Int]],Optional[Maybe[HashRef]]);
    my ($class,$apiurl,$user,$pass,$encoding,$debug, $do_post_redirect,$max_tries,$userfetch_opts) = $check->(@_);

    die("Invalid URI passed to constructor") if !is_uri($apiurl);
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
        configurations   => {},
        tr_fields        => undef,
        tr_project_id    => $userfetch_opts->{'project_id'},
        default_request  => undef,
        global_limit     => 250, #Discovered by experimentation
        browser          => LWP::UserAgent->new(
            keep_alive => 10,
            cookie_jar => HTTP::CookieJar::LWP->new(),
        ),
        do_post_redirect => $do_post_redirect,
        max_tries        => $max_tries // 1,
        retry_delay      => 5,
    };

    #Allow POST redirects
    if ($self->{do_post_redirect}) {
        push @{ $self->{'browser'}->requests_redirectable }, 'POST';
    }

    #Check chara encoding
    $self->{'encoding-nonaliased'} = Encode::resolve_alias($self->{'encoding'});
    die("Invalid encoding alias '".$self->{'encoding'}."' passed, see Encoding::Supported for a list of allowed encodings")
        unless $self->{'encoding-nonaliased'};

    die("Invalid encoding '".$self->{'encoding-nonaliased'}."' passed, see Encoding::Supported for a list of allowed encodings")
        unless grep {$_ eq $self->{'encoding-nonaliased'}} (Encode->encodings(":all"));

    #Create default request to pass on to LWP::UserAgent
    $self->{'default_request'} = HTTP::Request->new();
    $self->{'default_request'}->authorization_basic($user,$pass);

    bless( $self, $class );
    return $self if $self->debug; #For easy class testing without mocks

    # Manually do the get_users call to check HTTP status...
    # Allow users to skip the check if you have a zillion users etc,
    # as apparently that is fairly taxing on TR itself.
    if( !$userfetch_opts->{skip_usercache} ) {
        my $res = $self->getUsers($userfetch_opts->{project_id});
        confess "Error: network unreachable" if !defined($res);
        if ( (reftype($res) || 'undef') ne 'ARRAY') {
          confess "Unexpected return from _doRequest: $res" if !looks_like_number($res);
          confess "Could not communicate with TestRail Server! Check that your URI is correct, and your TestRail installation is functioning correctly." if $res == -500;
          confess "Could not list testRail users! Check that your TestRail installation has it's API enabled, and your credentials are correct" if $res == -403;
          confess "Bad user credentials!" if $res == -401;
          confess "HTTP error $res encountered while communicating with TestRail server.  Resolve issue and try again." if $res < 0;
          confess "Unknown error occurred: $res";
        }
        confess "No users detected on TestRail Install!  Check that your API is functioning correctly." if !scalar(@$res);
    }

    return $self;
}

=head1 GETTERS

=head2 B<apiurl>

=head2 B<debug>

Accessors for these parameters you pass into the constructor, in case you forget.

=cut

sub apiurl {
    state $check = compile(Object);
    my ($self) = $check->(@_);
    return $self->{'apiurl'}
}
sub debug {
    state $check = compile(Object);
    my ($self) = $check->(@_);
    return $self->{'debug'};
}

=head2 B<retry_delay>

There is no getter/setter for this parameter, but it is worth mentioning.
This is the number of seconds to wait between failed request retries when max_retries > 1.

    #Do something other than the default of 5s, like spam the server mercilessly
    $tr->{retry_delay} = 0;
    ...

=cut

#Convenient JSON-HTTP fetcher
sub _doRequest {
    state $check = compile(Object, Str, Optional[Maybe[Str]], Optional[Maybe[HashRef]]);
    my ($self,$path,$method,$data) = $check->(@_);

    $self->{num_tries}++;

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

    my $response = eval { $self->{'browser'}->request($req) };

    #Uncomment to generate mocks
    #use Data::Dumper;
    #open(my $fh, '>>', 'mock.out');
    #print $fh "{\n\n";
    #print $fh Dumper($path,'200','OK',$response->headers,$response->content);
    #print $fh '$mockObject->map_response(qr/\Q$VAR1\E/,HTTP::Response->new($VAR2, $VAR3, $VAR4, $VAR5));';
    #print $fh "\n\n}\n\n";
    #close $fh;

    if ($@) {
        #LWP threw an ex, probably a timeout
        if ($self->{num_tries} >= $self->{max_tries}) {
            $self->{num_tries} = 0;
            confess "Failed to satisfy request after $self->{num_tries} tries!";
        }
        cluck "WARNING: TestRail API request failed due to timeout, or other LWP fatal condition, re-trying request...\n";
        sleep $self->{retry_delay} if $self->{retry_delay};
        goto &_doRequest;
    }

    return $response if !defined($response); #worst case

    if ($response->code == 403) {
        confess "ERROR 403: Access Denied: ".$response->content;
    }
    if ($response->code == 401) {
        confess "ERROR 401: Authentication failed: ".$response->content;
    }

    if ($response->code != 200) {
        #LWP threw an ex, probably a timeout
        if ($self->{num_tries} >= $self->{max_tries}) {
            $self->{num_tries} = 0;
            cluck "ERROR: Arguments Bad? (got code ".$response->code."): ".$response->content;
            return -int($response->code);
        }
        cluck "WARNING: TestRail API request failed (got code ".$response->code."), re-trying request...\n";
        sleep $self->{retry_delay} if $self->{retry_delay};
        goto &_doRequest;

    }
    $self->{num_tries} = 0;

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
    state $check = compile(Object,Optional[Maybe[Str]]);
    my ($self,$project_id) = $check->(@_);

    # Return shallow clone of user_cache if set.
    return [ @{ $self->{'user_cache'} } ] if ref $self->{'user_cache'} eq 'ARRAY' && scalar(@{$self->{'user_cache'}});
    my $maybe_project = $project_id ? "/$project_id" : '';
    my $res = $self->_doRequest("index.php?/api/v2/get_users$maybe_project");
    return -500 if !$res || (reftype($res) || 'undef') ne 'ARRAY';
    $self->{'user_cache'} = $res;
    return clone($res);
}

=head2 B<getUserByID(id)>
=cut
=head2 B<getUserByName(name)>
=cut
=head2 B<getUserByEmail(email)>

Get user definition hash by ID, Name or Email.
Returns user definition HASHREF.

For efficiency's sake, these methods cache the result of getUsers until you explicitly run it again.

=cut

sub getUserByID {
    state $check = compile(Object, Int);
    my ($self,$user) = $check->(@_);

    my $users = $self->getUsers();
    return $users if ref $users ne 'ARRAY';
    foreach my $usr (@$users) {
        return $usr if $usr->{'id'} == $user;
    }
    return 0;
}

sub getUserByName {
    state $check = compile(Object, Str);
    my ($self,$user) = $check->(@_);

    my $users = $self->getUsers();
    return $users if ref $users ne 'ARRAY';
    foreach my $usr (@$users) {
        return $usr if $usr->{'name'} eq $user;
    }
    return 0;
}

sub getUserByEmail {
    state $check = compile(Object, Str);
    my ($self,$email) = $check->(@_);

    my $users = $self->getUsers();
    return $users if ref $users ne 'ARRAY';
    foreach my $usr (@$users) {
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
    state $check = compile(Object, slurpy ArrayRef[Str]);
    my ($self,$names) = $check->(@_);

    confess("At least one user name must be provided") if !scalar(@$names);
    my @ret = grep {defined $_} map {my $user = $_; my @list = grep {$user->{'name'} eq $_} @$names; scalar(@list) ? $user->{'id'} : undef} @{$self->getUsers()};
    confess("One or more user names provided does not exist in TestRail.") unless scalar(@$names) == scalar(@ret);
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
    state $check = compile(Object, Str, Optional[Maybe[Str]], Optional[Maybe[Bool]]);
    my ($self,$name,$desc,$announce) = $check->(@_);

    $desc     //= 'res ipsa loquiter';
    $announce //= 0;

    my $input = {
        name              => $name,
        announcement      => $desc,
        show_announcement => $announce
    };

    return $self->_doRequest('index.php?/api/v2/add_project','POST',$input);
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
    state $check = compile(Object, Int);
    my ($self,$proj) = $check->(@_);

    return $self->_doRequest('index.php?/api/v2/delete_project/'.$proj,'POST');
}

=head2 B<getProjects (filters)>

Get all available projects

=over 4

=item HASHREF C<FILTERS> (optional) - HASHREF describing parameters to filter cases by.

=back

Returns array of project definition HASHREFs, false otherwise.

    $projects = $tl->getProjects;

See:

    L<https://www.gurock.com/testrail/docs/api/reference/projects#getprojects>

for details as to the allowable filter keys.

=cut

sub getProjects {
    state $check = compile(Object,Optional[Maybe[HashRef]]);
    my ($self,$filters) = $check->(@_);

    my $result = $self->_doRequest('index.php?/api/v2/get_projects' . _convert_filters_to_string($filters) );
    return -500 if !$result || (reftype($result) || 'undef') ne 'HASH';
    my $projects = $result->{'projects'};
    return -500 if !$projects || (reftype($projects) || 'undef') ne 'ARRAY';

    #Save state for future use, if needed
    $self->{'testtree'} = $projects;

    foreach my $pj (@{$projects}) {
        $pj->{'type'} = 'project';
    }

    return $projects;
}

=head2 B<getProjectByName ($project)>

Gets some project definition hash by it's name

=over 4

=item STRING C<PROJECT> - desired project

=back

Returns desired project definition HASHREF, false otherwise.

    $project = $tl->getProjectByName('FunProject');

=cut

sub getProjectByName {
    state $check = compile(Object, Str);
    my ($self,$project) = $check->(@_);

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

Returns desired project definition HASHREF, false otherwise.

    $projects = $tl->getProjectByID(222);

=cut

sub getProjectByID {
    state $check = compile(Object, Int);
    my ($self,$project) = $check->(@_);

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
    state $check = compile(Object, Int, Str, Optional[Maybe[Str]]);
    my ($self,$project_id,$name,$details) = $check->(@_);

    $details //= 'res ipsa loquiter';
    my $input = {
        name        => $name,
        description => $details
    };

    return $self->_doRequest('index.php?/api/v2/add_suite/'.$project_id,'POST',$input);
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
    state $check = compile(Object, Int);
    my ($self,$suite_id) = $check->(@_);

    return $self->_doRequest('index.php?/api/v2/delete_suite/'.$suite_id,'POST');
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
    state $check = compile(Object, Int);
    my ($self,$proj) = $check->(@_);

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
    state $check = compile(Object, Int, Str);
    my ($self,$project_id,$testsuite_name) = $check->(@_);

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
    state $check = compile(Object, Int);
    my ($self,$testsuite_id) = $check->(@_);

    return $self->_doRequest('index.php?/api/v2/get_suite/'.$testsuite_id);
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
    state $check = compile(Object, Int, Int, Str, Optional[Maybe[Int]]);
    my ($self,$project_id,$suite_id,$name,$parent_id) = $check->(@_);

    my $input = {
        name     => $name,
        suite_id => $suite_id
    };
    $input->{'parent_id'} = $parent_id if $parent_id;

    return $self->_doRequest('index.php?/api/v2/add_section/'.$project_id,'POST',$input);
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
    state $check = compile(Object, Int);
    my ($self,$section_id) = $check->(@_);

    return $self->_doRequest('index.php?/api/v2/delete_section/'.$section_id,'POST');
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
    state $check = compile(Object, Int, Int);
    my ($self,$project_id,$suite_id) = $check->(@_);

    #Cache sections to reduce requests in tight loops
    return $self->{'sections'}->{$suite_id} if $self->{'sections'}->{$suite_id};
    my $response = $self->_doRequest("index.php?/api/v2/get_sections/$project_id&suite_id=$suite_id");
    return -500 if !$response || (reftype($response) || 'undef') ne 'HASH';
    my $sections = $response->{'sections'};
    return -500 if !$sections || (reftype($sections) || 'undef') ne 'ARRAY';

    $self->{'sections'}->{$suite_id} = $sections;

    return $self->{'sections'}->{$suite_id};
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
    state $check = compile(Object, Int);
    my ($self,$section_id) = $check->(@_);

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
    state $check = compile(Object, Int, Int, Str);
    my ($self,$project_id,$suite_id,$section_name) = $check->(@_);

    my $sections = $self->getSections($project_id,$suite_id);
    return -500 if !$sections || (reftype($sections) || 'undef') ne 'ARRAY';
    foreach my $sec (@$sections) {
        return $sec if $sec->{'name'} eq $section_name;
    }
    return 0;
}

=head2 B<getChildSections ($project_id, section)>

Gets desired section's child sections.

=over 4

=item INTEGER C<PROJECT_ID> - parent project ID of section.

=item HASHREF C<SECTION> - section definition HASHREF.

=back

Returns ARRAYREF of section definition HASHREF.  ARRAYREF is empty if there are none.

Recursively searches for children, so the children of child sections will be returned as well.

    $tr->getChildSections($section);

=cut

sub getChildSections {
    state $check = compile(Object, Int, HashRef);
    my ($self, $project_id, $section) = $check->(@_);

    my $sections_orig = $self->getSections($project_id,$section->{suite_id});
    return [] if !$sections_orig || (reftype($sections_orig) || 'undef') ne 'ARRAY';
    my @sections = grep { $_->{'parent_id'} ? $_->{'parent_id'} == $section->{'id'} : 0 } @$sections_orig;
    foreach my $sec (@sections) {
        push(@sections, grep { $_->{'parent_id'} ? $_->{'parent_id'} == $sec->{'id'} : 0 } @$sections_orig);
    }
    return \@sections;
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
    my $sections = $self->getSections($project_id,$suite_id) or confess("Could not find sections in provided project/suite.");
    return _X_in_my_Y($self,$sections,'id',@names);
}

=head1 CASE METHODS

=head2 B<getCaseTypes ()>

Gets possible case types.

Returns ARRAYREF of case type definition HASHREFs.

    $tr->getCaseTypes();

=cut

sub getCaseTypes {
    state $check = compile(Object);
    my ($self) = $check->(@_);
    return clone($self->{'type_cache'}) if defined($self->{'type_cache'});

    my $types = $self->_doRequest("index.php?/api/v2/get_case_types");
    return -500 if !$types || (reftype($types) || 'undef') ne 'ARRAY';
    $self->{'type_cache'} = $types;

    return clone $types;
}

=head2 B<getCaseTypeByName (name)>

Gets case type by name.

=over 4

=item STRING C<NAME> - Name of desired case type

=back

Returns case type definition HASHREF.
Dies if named case type does not exist.

    $tr->getCaseTypeByName();

=cut

sub getCaseTypeByName {
    state $check = compile(Object, Str);
    my ($self,$name) = $check->(@_);

    my $types = $self->getCaseTypes();
    return -500 if !$types || (reftype($types) || 'undef') ne 'ARRAY';
    foreach my $type (@$types) {
        return $type if $type->{'name'} eq $name;
    }
    confess("No such case type '$name'!");
}

=head2 typeNamesToIds(names)

Convenience method to translate a list of case type names to TestRail case type IDs.

=over 4

=item ARRAY C<NAMES> - Array of status names to translate to IDs.

=back

Returns ARRAY of type IDs in the same order as the type names passed.

Throws an exception in the case of one (or more) of the names not corresponding to a valid case type.

=cut

sub typeNamesToIds {
    my ($self,@names) = @_;
    return _X_in_my_Y($self,$self->getCaseTypes(),'id',@names);
};


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
    state $check = compile(Object, Int, Str, Optional[Maybe[Int]], Optional[Maybe[HashRef]], Optional[Maybe[HashRef]]);
    my ($self,$section_id,$title,$type_id,$opts,$extras) = $check->(@_);

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

    return $self->_doRequest("index.php?/api/v2/add_case/$section_id",'POST',$stuff);
}

=head2 B<updateCase(case_id,options)>

Updates a test case.

=over 4

=item INTEGER C<CASE ID> - Case ID.

=item HASHREF C<OPTIONS> - Various things about a case to set.  Everything except section_id in the output of getCaseBy* methods is a valid input here.

=back

Returns new case definition HASHREF, false otherwise.

=cut

sub updateCase {
    state $check = compile(Object, Int, Optional[Maybe[HashRef]]);
    my ($self,$case_id,$options) = $check->(@_);

    return $self->_doRequest("index.php?/api/v2/update_case/$case_id",'POST',$options);
}

=head2 B<deleteCase (case_id)>

Deletes specified test case.

=over 4

=item INTEGER C<CASE ID> - ID of case to delete.

=back

Returns BOOLEAN.

    $tr->deleteCase(1324);

=cut

sub deleteCase {
    state $check = compile(Object, Int);
    my ($self,$case_id) = $check->(@_);

    return $self->_doRequest("index.php?/api/v2/delete_case/$case_id",'POST');
}

=head2 B<getCases (project_id,suite_id,filters)>

Gets cases for provided section.

=over 4

=item INTEGER C<PROJECT ID> - ID of parent project.

=item INTEGER C<SUITE ID> - ID of parent suite.

=item HASHREF C<FILTERS> (optional) - HASHREF describing parameters to filter cases by.

=back

See:

    L<http://docs.gurock.com/testrail-api2/reference-cases#get_cases>

for details as to the allowable filter keys.

If the section ID is omitted, all cases for the suite will be returned.
Returns ARRAYREF of test case definition HASHREFs.

    $tr->getCases(1,2, {'section_id' => 3} );

=cut

sub getCases {
    state $check = compile(Object, Int, Int, Optional[Maybe[HashRef]]);
    my ($self,$project_id,$suite_id,$filters) = $check->(@_);

    my $url = "index.php?/api/v2/get_cases/$project_id&suite_id=$suite_id";
    $url .= _convert_filters_to_string($filters);

    my $response = $self->_doRequest($url);
    return -500 if !$response || (reftype($response) || 'undef') ne 'HASH';
    my $cases = $response->{'cases'};
    return -500 if !$cases || (reftype($cases) || 'undef') ne 'ARRAY';
    return $cases;
}

=head2 B<getCaseByName (project_id,suite_id,name,filters)>

Gets case by name.

=over 4

=item INTEGER C<PROJECT ID> - ID of parent project.

=item INTEGER C<SUITE ID> - ID of parent suite.

=item STRING C<NAME> - Name of desired test case.

=item HASHREF C<FILTERS> - Filter dictionary acceptable to getCases.

=back

Returns test case definition HASHREF.

    $tr->getCaseByName(1,2,'nugs', {'section_id' => 3});

=cut

sub getCaseByName {
    state $check = compile(Object, Int, Int, Str, Optional[Maybe[HashRef]]);
    my ($self,$project_id,$suite_id,$name,$filters) = $check->(@_);

    my $cases = $self->getCases($project_id,$suite_id,$filters);
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
    state $check = compile(Object, Int);
    my ($self,$case_id) = $check->(@_);

    return $self->_doRequest("index.php?/api/v2/get_case/$case_id");
}

=head2 getCaseFields

Returns ARRAYREF of available test case custom fields.

    $tr->getCaseFields();

Output is cached in the case_fields parameter.  Cache is invalidated when addCaseField is called.

=cut

sub getCaseFields {
    state $check = compile(Object);
    my ($self) = $check->(@_);
    return $self->{case_fields} if $self->{case_fields};

    $self->{case_fields} = $self->_doRequest("index.php?/api/v2/get_case_fields");
    return $self->{case_fields};
}

=head2 addCaseField(%options)

Returns HASHREF describing the case field you just added.

    $tr->addCaseField(%options)

=cut

sub addCaseField {
    state $check = compile(Object,slurpy HashRef);
    my ($self,$options) = $check->(@_);
    $self->{case_fields} = undef;
    return $self->_doRequest("index.php?/api/v2/add_case_field", 'POST', $options);
}

=head1 PRIORITY METHODS

=head2 B<getPriorities ()>

Gets possible priorities.

Returns ARRAYREF of priority definition HASHREFs.

    $tr->getPriorities();

=cut

sub getPriorities {
    state $check = compile(Object);
    my ($self) = $check->(@_);
    return clone($self->{'priority_cache'}) if defined($self->{'priority_cache'});

    my $priorities = $self->_doRequest("index.php?/api/v2/get_priorities");
    return -500 if !$priorities || (reftype($priorities) || 'undef') ne 'ARRAY';
    $self->{'priority_cache'} = $priorities;

    return clone $priorities;
}

=head2 B<getPriorityByName (name)>

Gets priority by name.

=over 4

=item STRING C<NAME> - Name of desired priority

=back

Returns priority definition HASHREF.
Dies if named priority does not exist.

    $tr->getPriorityByName();

=cut

sub getPriorityByName {
    state $check = compile(Object, Str);
    my ($self,$name) = $check->(@_);

    my $priorities = $self->getPriorities();
    return -500 if !$priorities || (reftype($priorities) || 'undef') ne 'ARRAY';
    foreach my $priority (@$priorities) {
        return $priority if $priority->{'name'} eq $name;
    }
    confess("No such priority '$name'!");
}

=head2 priorityNamesToIds(names)

Convenience method to translate a list of priority names to TestRail priority IDs.

=over 4

=item ARRAY C<NAMES> - Array of priority names to translate to IDs.

=back

Returns ARRAY of priority IDs in the same order as the priority names passed.

Throws an exception in the case of one (or more) of the names not corresponding to a valid priority.

=cut

sub priorityNamesToIds {
    my ($self,@names) = @_;
    return _X_in_my_Y($self,$self->getPriorities(),'id',@names);
};

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
    state $check = compile(Object, Int, Int, Str, Optional[Maybe[Str]], Optional[Maybe[Int]], Optional[Maybe[Int]],  Optional[Maybe[ArrayRef[Int]]]);
    my ($self,$project_id,$suite_id,$name,$desc,$milestone_id,$assignedto_id,$case_ids) = $check->(@_);

    my $stuff = {
        suite_id      => $suite_id,
        name          => $name,
        description   => $desc,
        milestone_id  => $milestone_id,
        assignedto_id => $assignedto_id,
        include_all   => defined($case_ids) ? 0 : 1,
        case_ids      => $case_ids
    };

    return $self->_doRequest("index.php?/api/v2/add_run/$project_id",'POST',$stuff);
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
    state $check = compile(Object, Int);
    my ($self,$run_id) = $check->(@_);

    return $self->_doRequest("index.php?/api/v2/delete_run/$run_id",'POST');
}

=head2 B<getRuns (project_id,filters)>

Get all runs for specified project.
To do this, it must make (no. of runs/250) HTTP requests.
This is due to the maximum result set limit enforced by testrail.

=over 4

=item INTEGER C<PROJECT_ID> - ID of parent project

=item HASHREF C<FILTERS> - (optional) dictionary of filters, with keys corresponding to the documented filters for get_runs (other than limit/offset).

=back

Returns ARRAYREF of run definition HASHREFs.

    $allRuns = $tr->getRuns(6969);

Possible filters:

=over 4

=item created_after (UNIX timestamp)

=item created_before (UNIX timestamp)

=item created_by (csv of ints) IDs of users plans were created by

=item is_completed (bool)

=item milestone_id (csv of ints) IDs of milestone assigned to plans

=item refs_filter (string) A single Reference ID (e.g. TR-a, 4291, etc.)

=item suite_id (csv of ints) A comma-separated list of test suite IDs to filter by.

=back

=cut

sub getRuns {
    state $check = compile(Object, Int, Optional[Maybe[HashRef]]);
    my ($self,$project_id,$filters) = $check->(@_);

    my $initial_runs = $self->getRunsPaginated($project_id,$self->{'global_limit'},0,$filters);
    return $initial_runs unless (reftype($initial_runs) || 'undef') eq 'ARRAY';
    my $runs = [];
    push(@$runs,@$initial_runs);
    my $offset = 1;
    while (scalar(@$initial_runs) == $self->{'global_limit'}) {
        $initial_runs = $self->getRunsPaginated($project_id,$self->{'global_limit'},($self->{'global_limit'} * $offset),$filters);
        return $initial_runs unless (reftype($initial_runs) || 'undef') eq 'ARRAY';
        push(@$runs,@$initial_runs);
        $offset++;
    }
    return $runs;
}

=head2 B<getRunsPaginated (project_id,limit,offset,filters)>

Get some runs for specified project.

=over 4

=item INTEGER C<PROJECT_ID> - ID of parent project

=item INTEGER C<LIMIT> - Number of runs to return.

=item INTEGER C<OFFSET> - Page of runs to return.

=item HASHREF C<FILTERS> - (optional) other filters to apply to the requests other than limit/offset.  See getRuns for more information.

=back

Returns ARRAYREF of run definition HASHREFs.

    $someRuns = $tr->getRunsPaginated(6969,22,4);

=cut

sub getRunsPaginated {
    state $check = compile(Object, Int, Optional[Maybe[Int]], Optional[Maybe[Int]], Optional[Maybe[HashRef]]);
    my ($self,$project_id,$limit,$offset,$filters) = $check->(@_);

    confess("Limit greater than ".$self->{'global_limit'}) if $limit > $self->{'global_limit'};
    my $apiurl = "index.php?/api/v2/get_runs/$project_id";
    $apiurl .= "&offset=$offset" if defined($offset);
    $apiurl .= "&limit=$limit" if $limit; #You have problems if you want 0 results
    $apiurl .= _convert_filters_to_string($filters);
    my $response = $self->_doRequest($apiurl);
    return -500 if !$response || (reftype($response) || 'undef') ne 'HASH';
    my $runs = $response->{'runs'};
    return -500 if !$runs || (reftype($runs) || 'undef') ne 'ARRAY';
    return $runs;
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
    state $check = compile(Object, Int, Str);
    my ($self,$project_id,$name) = $check->(@_);

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
    state $check = compile(Object, Int);
    my ($self,$run_id) = $check->(@_);

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
    state $check = compile(Object, Int);
    my ($self,$run_id) = $check->(@_);

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
    state $check = compile(Object, slurpy ArrayRef[HashRef]);
    my ($self,$runs) = $check->(@_);
    confess("At least one run must be passed!") unless scalar(@$runs);

    #Translate custom statuses
    my $statuses = $self->getPossibleTestStatuses();
    my %shash;
    #XXX so, they do these tricks with the status names, see...so map the counts to their relevant status ids.
    @shash{map { ( $_->{'id'} < 6 ) ? $_->{'name'}."_count" : "custom_status".($_->{'id'} - 5)."_count" } @$statuses } = map { $_->{'id'} } @$statuses;

    my @sname;
    #Create listing of keys/values
    @$runs = map {
        my $run = $_;
        @{$run->{statuses}}{grep {$_ =~ m/_count$/} keys(%$run)} = grep {$_ =~ m/_count$/} keys(%$run);
        foreach my $status (keys(%{$run->{'statuses'}})) {
            next if !exists($shash{$status});
            @sname = grep {exists($shash{$status}) && $_->{'id'} == $shash{$status}} @$statuses;
            $run->{'statuses_clean'}->{$sname[0]->{'label'}} = $run->{$status};
        }
        $run;
    } @$runs;

    return map { {'id' => $_->{'id'}, 'name' => $_->{'name'}, 'run_status' => $_->{'statuses_clean'}, 'config_ids' => $_->{'config_ids'} } } @$runs;

}

=head2 B<getRunResults(run_id)>

Returns array of hashrefs describing the results of the run.

Warning: This only returns the most recent results of a run.
If you want to know about the tortured journey a test may have taken to get to it's final status,
you will need to use getTestResults.

=over 4

=item INTEGER C<RUN_ID> - Relevant Run's ID.

=back

=cut

sub getRunResults {
    state $check = compile(Object, Int, Optional[Maybe[HashRef]]);
    my ($self,$run_id, $filters) = $check->(@_);

    my $initial_results = $self->getRunResultsPaginated($run_id,$self->{'global_limit'},undef,$filters);
    return $initial_results unless (reftype($initial_results) || 'undef') eq 'ARRAY';
    my $results = [];
    push(@$results,@$initial_results);
    my $offset = 1;
    while (scalar(@$initial_results) == $self->{'global_limit'}) {
        $initial_results = $self->getRunResultsPaginated($run_id,$self->{'global_limit'},($self->{'global_limit'} * $offset),$filters);
        return $initial_results unless (reftype($initial_results) || 'undef') eq 'ARRAY';
        push(@$results,@$initial_results);
        $offset++;
    }
    return $results;
}

=head2 B<getRunResultsPaginated(run_id,limit,offset,filters)>

=cut

sub getRunResultsPaginated {
    state $check = compile(Object, Int, Optional[Maybe[Int]], Optional[Maybe[Int]], Optional[Maybe[HashRef]]);
    my ($self,$run_id,$limit,$offset,$filters) = $check->(@_);

    confess("Limit greater than ".$self->{'global_limit'}) if $limit > $self->{'global_limit'};
    my $apiurl = "index.php?/api/v2/get_results_for_run/$run_id";
    $apiurl .= "&offset=$offset" if defined($offset);
    $apiurl .= "&limit=$limit" if $limit; #You have problems if you want 0 results
    $apiurl .= _convert_filters_to_string($filters);
    my $response = $self->_doRequest($apiurl);
    return $response->{'results'};
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
    state $check = compile(Object, HashRef);
    my ($self,$plan) = $check->(@_);

    return 0 unless defined($plan->{'entries'}) && (reftype($plan->{'entries'}) || 'undef') eq 'ARRAY';
    my $entries = $plan->{'entries'};
    my $plans = [];
    foreach my $entry (@$entries) {
        push(@$plans,@{$entry->{'runs'}}) if defined($entry->{'runs'}) && ((reftype($entry->{'runs'}) || 'undef') eq 'ARRAY')
    }
    return $plans;
}

=head2 B<getChildRunByName(plan,name,configurations,testsuite_id)>

=over 4

=item HASHREF C<PLAN> - Test Plan definition HASHREF returned by any of the PLAN methods below.

=item STRING C<NAME> - Name of run to search for within plan.

=item ARRAYREF C<CONFIGURATIONS> (optional) - Names of configurations to filter runs by.

=item INTEGER C<TESTSUITE_ID> (optional) - Filter by the provided Testsuite ID.  Helpful for when child runs have duplicate names, but are from differing testsuites.

=back

Returns run definition HASHREF, or false if no such run is found.
Convenience method using getChildRuns.

Will throw a fatal error if one or more of the configurations passed does not exist in the project.

=cut

sub getChildRunByName {
    state $check = compile(Object, HashRef, Str, Optional[Maybe[ArrayRef[Str]]], Optional[Maybe[Int]]);
    my ($self,$plan,$name,$configurations,$testsuite_id) = $check->(@_);

    my $runs = $self->getChildRuns($plan);
    @$runs = grep {$_->{suite_id} == $testsuite_id}  @$runs if $testsuite_id;
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

    $entries = [{
        suite_id => 345,
        include_all => 1,
        assignedto_id => 1
    }];

    $tr->createPlan(1,'Gosplan','Robo-Signed Soviet 5-year plan',22,$entries);

=cut

sub createPlan {
    state $check = compile(Object, Int, Str, Optional[Maybe[Str]], Optional[Maybe[Int]], Optional[Maybe[ArrayRef[HashRef]]]);
    my ($self,$project_id,$name,$desc,$milestone_id,$entries) = $check->(@_);

    my $stuff = {
        name          => $name,
        description   => $desc,
        milestone_id  => $milestone_id,
        entries       => $entries
    };

    return $self->_doRequest("index.php?/api/v2/add_plan/$project_id",'POST',$stuff);
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
    state $check = compile(Object, Int);
    my ($self,$plan_id) = $check->(@_);

    return $self->_doRequest("index.php?/api/v2/delete_plan/$plan_id",'POST');
}

=head2 B<getPlans (project_id,filters)>

Gets all test plans in specified project.
Like getRuns, must make multiple HTTP requests when the number of results exceeds 250.

=over 4

=item INTEGER C<PROJECT ID> - ID of parent project.

=item HASHREF C<FILTERS> - (optional) dictionary of filters, with keys corresponding to the documented filters for get_plans (other than limit/offset).

=back

Returns ARRAYREF of all plan definition HASHREFs in a project.

    $tr->getPlans(8);

Does not contain any information about child test runs.
Use getPlanByID or getPlanByName if you want that, in particular if you are interested in using getChildRunByName.

Possible filters:

=over 4

=item created_after (UNIX timestamp)

=item created_before (UNIX timestamp)

=item created_by (csv of ints) IDs of users plans were created by

=item is_completed (bool)

=item milestone_id (csv of ints) IDs of milestone assigned to plans

=back

=cut

sub getPlans {
    state $check = compile(Object, Int, Optional[Maybe[HashRef]]);
    my ($self,$project_id,$filters) = $check->(@_);

    my $initial_plans = $self->getPlansPaginated($project_id,$self->{'global_limit'},0,$filters);
    return $initial_plans unless (reftype($initial_plans) || 'undef') eq 'ARRAY';
    my $plans = [];
    push(@$plans,@$initial_plans);
    my $offset = 1;
    while (scalar(@$initial_plans) == $self->{'global_limit'}) {
        $initial_plans = $self->getPlansPaginated($project_id,$self->{'global_limit'},($self->{'global_limit'} * $offset),$filters);
        return $initial_plans unless (reftype($initial_plans) || 'undef') eq 'ARRAY';
        push(@$plans,@$initial_plans);
        $offset++;
    }
    return $plans;
}

=head2 B<getPlansPaginated (project_id,limit,offset,filters)>

Get some plans for specified project.

=over 4

=item INTEGER C<PROJECT_ID> - ID of parent project

=item INTEGER C<LIMIT> - Number of plans to return.

=item INTEGER C<OFFSET> - Page of plans to return.

=item HASHREF C<FILTERS> - (optional) other filters to apply to the requests (other than limit/offset).  See getPlans for more information.

=back

Returns ARRAYREF of plan definition HASHREFs.

    $someRuns = $tr->getPlansPaginated(6969,222,44);

=cut

sub getPlansPaginated {
    state $check = compile(Object, Int, Optional[Maybe[Int]], Optional[Maybe[Int]], Optional[Maybe[HashRef]]);
    my ($self,$project_id,$limit,$offset,$filters) = $check->(@_);

    confess("Limit greater than ".$self->{'global_limit'}) if $limit > $self->{'global_limit'};
    my $apiurl = "index.php?/api/v2/get_plans/$project_id";
    $apiurl .= "&offset=$offset" if defined($offset);
    $apiurl .= "&limit=$limit" if $limit; #You have problems if you want 0 results
    $apiurl .= _convert_filters_to_string($filters);
    my $response = $self->_doRequest($apiurl);
    return -500 if !$response || (reftype($response) || 'undef') ne 'HASH';
    my $plans = $response->{'plans'};
    return -500 if !$plans || (reftype($plans) || 'undef') ne 'ARRAY';
    return $plans;
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
    state $check = compile(Object, Int, Str);
    my ($self,$project_id,$name) = $check->(@_);

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
    state $check = compile(Object, Int);
    my ($self,$plan_id) = $check->(@_);

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
    state $check = compile(Object, Int);
    my ($self,$plan_id) = $check->(@_);

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

=head2 B<createRunInPlan (plan_id,suite_id,name,assigned_to_id,config_ids,case_ids)>

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
    state $check = compile(Object, Int, Int, Str, Optional[Maybe[Int]], Optional[Maybe[ArrayRef[Int]]], Optional[Maybe[ArrayRef[Int]]]);
    my ($self,$plan_id,$suite_id,$name,$assignedto_id,$config_ids,$case_ids) = $check->(@_);

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
    return $self->_doRequest("index.php?/api/v2/add_plan_entry/$plan_id",'POST',$stuff);
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
    state $check = compile(Object, Int);
    my ($self,$plan_id) = $check->(@_);

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
    state $check = compile(Object, Int, Str, Optional[Maybe[Str]], Optional[Maybe[Int]]);
    my ($self,$project_id,$name,$desc,$due_on) = $check->(@_);

    my $stuff = {
        name        => $name,
        description => $desc,
        due_on      => $due_on # unix timestamp
    };

    return $self->_doRequest("index.php?/api/v2/add_milestone/$project_id",'POST',$stuff);
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
    state $check = compile(Object, Int);
    my ($self,$milestone_id) = $check->(@_);

    return $self->_doRequest("index.php?/api/v2/delete_milestone/$milestone_id",'POST');
}

=head2 B<getMilestones (project_id,filters)>

Get milestones for some project.

=over 4

=item INTEGER C<PROJECT ID> - ID of parent project.

=item HASHREF C<FILTERS> (optional) - HASHREF describing parameters to filter milestones by.

=back

See:

    L<https://www.gurock.com/testrail/docs/api/reference/milestones#getmilestones>

for details as to the allowable filter keys.

Returns ARRAYREF of milestone definition HASHREFs.

    $tr->getMilestones(8);

=cut

sub getMilestones {
    state $check = compile(Object, Int, Optional[Maybe[HashRef]]);
    my ($self,$project_id, $filters) = $check->(@_);

    my $response = $self->_doRequest("index.php?/api/v2/get_milestones/$project_id" . _convert_filters_to_string($filters));
    return -500 if !$response || (reftype($response) || 'undef') ne 'HASH';
    my $milestones = $response->{'milestones'};
    return -500 if !$milestones || (reftype($milestones) || 'undef') ne 'ARRAY';
    return $milestones;
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
    state $check = compile(Object, Int, Str);
    my ($self,$project_id,$name) = $check->(@_);

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
    state $check = compile(Object, Int);
    my ($self,$milestone_id) = $check->(@_);

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
    state $check = compile(Object, Int, Optional[Maybe[ArrayRef[Int]]], Optional[Maybe[ArrayRef[Int]]]);
    my ($self,$run_id,$status_ids,$assignedto_ids) = $check->(@_);

    my $query_string = '';
    $query_string = '&status_id='.join(',',@$status_ids) if defined($status_ids) && scalar(@$status_ids);
    my $response = $self->_doRequest("index.php?/api/v2/get_tests/$run_id$query_string");

    return -500 if !$response || (reftype($response) || 'undef') ne 'HASH';
    my $results = $response->{'tests'};
    return -500 if !$results || (reftype($results) || 'undef') ne 'ARRAY';

    @$results = grep {my $aid = $_->{'assignedto_id'}; grep {defined($aid) && $aid == $_} @$assignedto_ids} @$results if defined($assignedto_ids) && scalar(@$assignedto_ids);

    #Cache stuff for getTestByName
    $self->{tests_cache} //= {};
    $self->{tests_cache}->{$run_id} = $results;

    return clone($results);
}

=head2 B<getTestByName (run_id,name)>

Gets specified test by name.

This is done by getting the list of all tests in the run and then picking out the relevant test.
As such, for efficiency the list of tests is cached.
The cache may be refreshed, or restricted by running getTests (with optional restrictions, such as assignedto_ids, etc).

=over 4

=item INTEGER C<RUN ID> - ID of parent run.

=item STRING C<NAME> - Name of milestone.

=back

Returns test definition HASHREF.

    $tr->getTestByName(36,'wheeTest');

=cut

sub getTestByName {
    state $check = compile(Object, Int, Str);
    my ($self,$run_id,$name) = $check->(@_);

    $self->{tests_cache} //= {};
    my $tests = $self->{tests_cache}->{$run_id};

    $tests = $self->getTests($run_id) if !$tests;
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
    state $check = compile(Object, Int);
    my ($self,$test_id) = $check->(@_);

    return $self->_doRequest("index.php?/api/v2/get_test/$test_id");
}

=head2 B<getTestResultFields()>

Gets custom fields that can be set for tests.

Returns ARRAYREF of result definition HASHREFs.

=cut

sub getTestResultFields {
    state $check = compile(Object);
    my ($self) = $check->(@_);

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

Returns a value less than 0 if unsuccessful.

=cut

sub getTestResultFieldByName {
    state $check = compile(Object, Str, Optional[Maybe[Int]]);
    my ($self,$system_name,$project_id) = $check->(@_);

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

Caches the result for the lifetime of the TestRail::API object.

=cut

sub getPossibleTestStatuses {
    state $check = compile(Object);
    my ($self) = $check->(@_);
    return $self->{'status_cache'} if $self->{'status_cache'};

    $self->{'status_cache'} = $self->_doRequest('index.php?/api/v2/get_statuses');
    return clone $self->{'status_cache'};
}

=head2 statusNamesToIds(names)

Convenience method to translate a list of statuses to TestRail status IDs.
The names referred to here are 'internal names' rather than the labels shown in TestRail.

=over 4

=item ARRAY C<NAMES> - Array of status names to translate to IDs.

=back

Returns ARRAY of status IDs in the same order as the status names passed.

Throws an exception in the case of one (or more) of the names not corresponding to a valid test status.

=cut

sub statusNamesToIds {
    my ($self,@names) = @_;
    return _X_in_my_Y($self,$self->getPossibleTestStatuses(),'id',@names);
};

=head2 statusNamesToLabels(names)

Convenience method to translate a list of statuses to TestRail status labels (the 'nice' form of status names).
This is useful when interacting with getRunSummary or getPlanSummary, which uses these labels as hash keys.

=over 4

=item ARRAY C<NAMES> - Array of status names to translate to IDs.

=back

Returns ARRAY of status labels in the same order as the status names passed.

Throws an exception in the case of one (or more) of the names not corresponding to a valid test status.

=cut

sub statusNamesToLabels {
    my ($self,@names) = @_;
    return _X_in_my_Y($self,$self->getPossibleTestStatuses(),'label',@names);
};

# Reduce code duplication with internal methods?
# It's more likely than you think
# Free PC check @ cpan.org
sub _X_in_my_Y {
    state $check = compile(Object, ArrayRef, Str, slurpy ArrayRef[Str]);
    my ($self,$search_arr,$key,$names) = $check->(@_);

    my @ret;
    foreach my $name (@$names) {
        foreach my $member (@$search_arr) {
            if ($member->{'name'} eq $name) {
                push @ret, $member->{$key};
                last;
            }
        }
    }
    confess("One or more names provided does not exist in TestRail.") unless scalar(@$names) == scalar(@ret);
    return @ret;
}

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
    state $check = compile(Object, Int, Int, Optional[Maybe[Str]], Optional[Maybe[HashRef]], Optional[Maybe[HashRef]]);
    my ($self,$test_id,$status_id,$comment,$opts,$custom_fields) = $check->(@_);

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

=item ARRAYREF C<RESULTS> - Array of result HASHREFs to upload.

=back

Returns ARRAYREF of result definition HASHREFs.

=cut

sub bulkAddResults {
    state $check = compile(Object, Int, ArrayRef[HashRef]);
    my ($self,$run_id, $results) = $check->(@_);

    return $self->_doRequest("index.php?/api/v2/add_results/$run_id", 'POST', { 'results' => $results });
}

=head2 bulkAddResultsByCase(run_id,results)

Basically the same as bulkAddResults, but instead of a test_id for each entry you use a case_id.

=cut

sub bulkAddResultsByCase {
    state $check = compile(Object, Int, ArrayRef[HashRef]);
    my ($self,$run_id, $results) = $check->(@_);

    return $self->_doRequest("index.php?/api/v2/add_results_for_cases/$run_id", 'POST', { 'results' => $results });
}


=head2 B<getTestResults(test_id,limit,offset,filters)>

Get the recorded results for desired test, limiting output to 'limit' entries.

=over 4

=item INTEGER C<TEST_ID> - ID of desired test

=item POSITIVE INTEGER C<LIMIT> (OPTIONAL) - provide no more than this number of results.

=item INTEGER C<OFFSET> (OPTIONAL) - Offset to begin viewing result set at.

=item HASHREF C<FILTERS> (optional) - HASHREF describing parameters to filter test results by (other than limit/offset).

=back

See:

    L<https://www.gurock.com/testrail/docs/api/reference/results#getresults>

for details as to the allowable filter keys.

Returns ARRAYREF of result definition HASHREFs.

=cut

sub getTestResults {
    state $check = compile(Object, Int, Optional[Maybe[Int]], Optional[Maybe[Int]], Optional[Maybe[HashRef]]);
    my ($self,$test_id,$limit,$offset,$filters) = $check->(@_);

    my $url = "index.php?/api/v2/get_results/$test_id";
    $url .= "&limit=$limit" if $limit;
    $url .= "&offset=$offset" if defined($offset);
    $url .= _convert_filters_to_string($filters);
    my $response = $self->_doRequest($url);
    return -500 if !$response || (reftype($response) || 'undef') ne 'HASH';
    my $results = $response->{'results'};
    return -500 if !$results || (reftype($results) || 'undef') ne 'ARRAY';
    return $results;
}

=head2 B<getResultsForCase(run_id,case_id,limit,offset,filters)>

Get the recorded results for a test run and case combination., limiting output to 'limit' entries.

=over 4

=item INTEGER C<RUN_ID> - ID of desired run

=item INTEGER C<CASE_ID> - ID of desired case

=item POSITIVE INTEGER C<LIMIT> (OPTIONAL) - provide no more than this number of results.

=item INTEGER C<OFFSET> (OPTIONAL) - Offset to begin viewing result set at.

=item HASHREF C<FILTERS> (optional) - HASHREF describing parameters to filter by (other than limit/offset).

=back

See:

    L<https://www.gurock.com/testrail/docs/api/reference/results#getresultsforcase>

for details as to the allowable filter keys.

Returns ARRAYREF of result definition HASHREFs.

=cut

sub getResultsForCase {
    state $check = compile(Object, Int, Int, Optional[Maybe[Int]], Optional[Maybe[Int]], Optional[Maybe[HashRef]]);
    my ($self,$run_id,$case_id,$limit,$offset,$filters) = $check->(@_);

    my $url = "index.php?/api/v2/get_results_for_case/$run_id/$case_id";
    $url .= "&limit=$limit" if $limit;
    $url .= "&offset=$offset" if defined($offset);
    $url .= _convert_filters_to_string($filters);
    my $response = $self->_doRequest($url);
    return $response->{'results'};
}

=head1 CONFIGURATION METHODS

=head2 B<getConfigurationGroups(project_id)>

Gets the available configuration groups for a project, with their configurations as children.

=over 4

=item INTEGER C<PROJECT_ID> - ID of relevant project

=back

Returns ARRAYREF of configuration group definition HASHREFs.

=cut

sub getConfigurationGroups {
    state $check = compile(Object, Int);
    my ($self,$project_id) = $check->(@_);

    my $url = "index.php?/api/v2/get_configs/$project_id";
    return $self->_doRequest($url);
}

=head2 B<getConfigurationGroupByName(project_id,name)>

Get the provided configuration group by name.

Returns false if the configuration group could not be found.

=cut

sub getConfigurationGroupByName {
    state $check = compile(Object, Int, Str);
    my ($self,$project_id,$name) = $check->(@_);

    my $cgroups = $self->getConfigurationGroups($project_id);
    return 0 if ref($cgroups) ne 'ARRAY';
    @$cgroups = grep {$_->{'name'} eq $name} @$cgroups;
    return 0 unless scalar(@$cgroups);
    return $cgroups->[0];
}

=head2 B<addConfigurationGroup(project_id,name)>

New in TestRail 5.2.

Add a configuration group to the specified project.

=over 4

=item INTEGER C<PROJECT_ID> - ID of relevant project

=item STRING C<NAME> - Name for new configuration Group.

=back

Returns HASHREF with new configuration group.

=cut

sub addConfigurationGroup {
    state $check = compile(Object, Int, Str);
    my ($self,$project_id,$name) = $check->(@_);

    my $url = "index.php?/api/v2/add_config_group/$project_id";
    return $self->_doRequest($url,'POST',{'name' => $name});
}

=head2 B<editConfigurationGroup(config_group_id,name)>

New in TestRail 5.2.

Change the name of a configuration group.

=over 4

=item INTEGER C<CONFIG_GROUP_ID> - ID of relevant configuration group

=item STRING C<NAME> - Name for new configuration Group.

=back

Returns HASHREF with new configuration group.

=cut

sub editConfigurationGroup {
    state $check = compile(Object, Int, Str);
    my ($self,$config_group_id,$name) = $check->(@_);

    my $url = "index.php?/api/v2/update_config_group/$config_group_id";
    return $self->_doRequest($url,'POST',{'name' => $name});
}

=head2 B<deleteConfigurationGroup(config_group_id)>

New in TestRail 5.2.

Delete a configuration group.

=over 4

=item INTEGER C<CONFIG_GROUP_ID> - ID of relevant configuration group


=back

Returns BOOL.

=cut

sub deleteConfigurationGroup {
    state $check = compile(Object, Int);
    my ($self,$config_group_id) = $check->(@_);

    my $url = "index.php?/api/v2/delete_config_group/$config_group_id";
    return $self->_doRequest($url,'POST');
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
    state $check = compile(Object, Int);
    my ($self,$project_id) = $check->(@_);

    my $cgroups = $self->getConfigurationGroups($project_id);
    my $configs = [];
    return $cgroups unless (reftype($cgroups) || 'undef') eq 'ARRAY';
    foreach my $cfg (@$cgroups) {
        push(@$configs, @{$cfg->{'configs'}});
    }
    return $configs;
}

=head2 B<addConfiguration(configuration_group_id,name)>

New in TestRail 5.2.

Add a configuration to the specified configuration group.

=over 4

=item INTEGER C<CONFIGURATION_GROUP_ID> - ID of relevant configuration group

=item STRING C<NAME> - Name for new configuration.

=back

Returns HASHREF with new configuration.

=cut

sub addConfiguration {
    state $check = compile(Object, Int, Str);
    my ($self,$configuration_group_id,$name) = $check->(@_);

    my $url = "index.php?/api/v2/add_config/$configuration_group_id";
    return $self->_doRequest($url,'POST',{'name' => $name});
}

=head2 B<editConfiguration(config_id,name)>

New in TestRail 5.2.

Change the name of a configuration.

=over 4

=item INTEGER C<CONFIG_ID> - ID of relevant configuration.

=item STRING C<NAME> - New name for configuration.

=back

Returns HASHREF with new configuration group.

=cut

sub editConfiguration {
    state $check = compile(Object, Int, Str);
    my ($self,$config_id,$name) = $check->(@_);

    my $url = "index.php?/api/v2/update_config/$config_id";
    return $self->_doRequest($url,'POST',{'name' => $name});
}

=head2 B<deleteConfiguration(config_id)>

New in TestRail 5.2.

Delete a configuration.

=over 4

=item INTEGER C<CONFIG_ID> - ID of relevant configuration

=back

Returns BOOL.

=cut

sub deleteConfiguration {
    state $check = compile(Object, Int);
    my ($self,$config_id) = $check->(@_);

    my $url = "index.php?/api/v2/delete_config/$config_id";
    return $self->_doRequest($url,'POST');
}

=head2 B<translateConfigNamesToIds(project_id,configs)>

Transforms a list of configuration names into a list of config IDs.

=over 4

=item INTEGER C<PROJECT_ID> - Relevant project ID for configs.

=item ARRAY C<CONFIGS> - Array of config names

=back

Returns ARRAY of configuration names, with undef values for unknown configuration names.

=cut

sub translateConfigNamesToIds {
    my ($self,$project_id,@names) = @_;
    my $configs = $self->getConfigurations($project_id) or confess("Could not determine configurations in provided project.");
    return _X_in_my_Y($self,$configs,'id',@names);
}

=head1 REPORT METHODS

=head2 getReports

Return the ARRAYREF of reports available for the provided project.

Requires you to mark a particular report as accessible in the API via the TestRail report interface.

=over 4

=item INTEGER C<PROJECT_ID> - Relevant project ID.

=back

=cut

sub getReports {
    state $check = compile(Object, Int);
    my ($self,$project_id) = $check->(@_);
    my $url = "index.php?/api/v2/get_reports/$project_id";
    return $self->_doRequest($url,'GET');
}

=head2 runReport

Compute the provided report using currently available data.

Returns HASHREF describing URLs to access completed reports.

=over 4

=item INTEGER C<REPORT_ID> - Relevant report ID.

=back

=cut

sub runReport {
    state $check = compile(Object, Int);
    my ($self,$report_id) = $check->(@_);
    my $url = "index.php?/api/v2/run_report/$report_id";
    return $self->_doRequest($url,'GET');
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
    state $check = compile(Str, Str, Str, Int);
    my ($content,$expected,$actual,$status_id) = $check->(@_);

    return {
        content   => $content,
        expected  => $expected,
        actual    => $actual,
        status_id => $status_id
    };
}

# Convenience method for building filter string from filters Hashref
sub _convert_filters_to_string {
    state $check = compile(Maybe[HashRef]);
    my ($filters) = $check->(@_);

    $filters //= {};

    my $filter_string = '';
    foreach my $filter (keys(%$filters)) {
        if (ref $filters->{$filter} eq 'ARRAY') {
            $filter_string .= "&$filter=".join(',',@{$filters->{$filter}});
        } else {
            $filter_string .= "&$filter=".$filters->{$filter} if defined($filters->{$filter});
        }
    }
    return $filter_string;
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
