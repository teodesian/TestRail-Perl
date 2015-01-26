# ABSTRACT: Provides an interface to something like TestRail's REST api in a bogus fashion
# PODNAME: Test::LWP::UserAgent::TestRailMock

package Test::LWP::UserAgent::TestRailMock;
$Test::LWP::UserAgent::TestRailMock::VERSION = '0.015';
use strict;
use warnings;

use Test::LWP::UserAgent;
use HTTP::Response;
use HTTP::Request;
use HTTP::Headers;

#Use this as the ->{'browser'} param of the TestRail::API object
our $mockObject = Test::LWP::UserAgent->new();
my ( $VAR1, $VAR2, $VAR3, $VAR4, $VAR5 );

{

    $VAR1 = 'http://hokum.bogus/index.php?/api/v2/get_users';
    $VAR2 = 500;
    $VAR3 = 'Can\'t connect to hokum.bogus:80 (Bad hostname)';
    $VAR4 = bless(
        {
            'client-warning' => 'Internal response',
            'client-date'    => 'Tue, 23 Dec 2014 20:02:08 GMT',
            'content-type'   => 'text/plain',
            '::std_case'     => {
                'client-warning' => 'Client-Warning',
                'client-date'    => 'Client-Date'
            }
        },
        'HTTP::Headers'
    );
    $VAR5 = 'Can\'t connect to hokum.bogus:80 (Bad hostname)

LWP::Protocol::http::Socket: Bad hostname \'hokum.bogus\' at /usr/share/perl5/LWP/Protocol/http.pm line 51.
';
    $mockObject->map_response( qr/\Q$VAR1\E/,
        HTTP::Response->new( $VAR2, $VAR3, $VAR4, $VAR5 ) );

}

{

    $VAR1 = 'index.php?/api/v2/get_users';
    $VAR2 = '200';
    $VAR3 = 'OK';
    $VAR4 = bless(
        {
            'connection'          => 'close',
            'x-powered-by'        => 'PHP/5.5.9-1ubuntu4.5',
            'client-response-num' => 1,
            'date'                => 'Tue, 23 Dec 2014 20:02:08 GMT',
            'client-peer'         => '192.168.122.217:80',
            'content-length'      => '70',
            '::std_case'          => {
                'client-date'         => 'Client-Date',
                'x-powered-by'        => 'X-Powered-By',
                'client-response-num' => 'Client-Response-Num',
                'client-peer'         => 'Client-Peer'
            },
            'client-date'  => 'Tue, 23 Dec 2014 20:02:08 GMT',
            'content-type' => 'application/json; charset=utf-8',
            'server'       => 'Apache/2.4.7 (Ubuntu)'
        },
        'HTTP::Headers'
    );
    $VAR5 =
      '[{"id":1,"name":"teodesian","email":"teodesian@cpan.org","is_active":true}]';
    $mockObject->map_response( qr/\Q$VAR1\E/,
        HTTP::Response->new( $VAR2, $VAR3, $VAR4, $VAR5 ) );

}

{

    $VAR1 = 'noSuchMethod';
    $VAR2 = '404';
    $VAR3 = 'Not Found';
    $VAR4 = bless(
        {
            'connection'          => 'close',
            'client-response-num' => 1,
            'date'                => 'Tue, 23 Dec 2014 20:02:08 GMT',
            'client-peer'         => '192.168.122.217:80',
            'content-length'      => '289',
            '::std_case'          => {
                'client-date'         => 'Client-Date',
                'client-response-num' => 'Client-Response-Num',
                'title'               => 'Title',
                'client-peer'         => 'Client-Peer'
            },
            'client-date'  => 'Tue, 23 Dec 2014 20:02:08 GMT',
            'content-type' => 'text/html; charset=iso-8859-1',
            'title'        => '404 Not Found',
            'server'       => 'Apache/2.4.7 (Ubuntu)'
        },
        'HTTP::Headers'
    );
    $VAR5 = '<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML 2.0//EN">
<html><head>
<title>404 Not Found</title>
</head><body>
<h1>Not Found</h1>
<p>The requested URL /noSuchMethod was not found on this server.</p>
<hr>
<address>Apache/2.4.7 (Ubuntu) Server at testrail.local Port 80</address>
</body></html>
';
    $mockObject->map_response( qr/\Q$VAR1\E/,
        HTTP::Response->new( $VAR2, $VAR3, $VAR4, $VAR5 ) );

}

{

    $VAR1 = 'index.php?/api/v2/add_project';
    $VAR2 = '200';
    $VAR3 = 'OK';
    $VAR4 = bless(
        {
            'connection'          => 'close',
            'x-powered-by'        => 'PHP/5.5.9-1ubuntu4.5',
            'client-response-num' => 1,
            'date'                => 'Tue, 23 Dec 2014 20:02:08 GMT',
            'client-peer'         => '192.168.122.217:80',
            'content-length'      => '236',
            '::std_case'          => {
                'client-date'         => 'Client-Date',
                'x-powered-by'        => 'X-Powered-By',
                'client-response-num' => 'Client-Response-Num',
                'client-peer'         => 'Client-Peer'
            },
            'client-date'  => 'Tue, 23 Dec 2014 20:02:08 GMT',
            'content-type' => 'application/json; charset=utf-8',
            'server'       => 'Apache/2.4.7 (Ubuntu)'
        },
        'HTTP::Headers'
    );
    $VAR5 =
      '{"id":9,"name":"CRUSH ALL HUMANS","announcement":"Robo-Signed Soviet 5 Year Project","show_announcement":false,"is_completed":false,"completed_on":null,"suite_mode":3,"url":"http:\\/\\/testrail.local\\/\\/index.php?\\/projects\\/overview\\/9"}';
    $mockObject->map_response( qr/\Q$VAR1\E/,
        HTTP::Response->new( $VAR2, $VAR3, $VAR4, $VAR5 ) );

}

{

    $VAR1 = 'index.php?/api/v2/get_projects';
    $VAR2 = '200';
    $VAR3 = 'OK';
    $VAR4 = bless(
        {
            'connection'          => 'close',
            'x-powered-by'        => 'PHP/5.5.9-1ubuntu4.5',
            'client-response-num' => 1,
            'date'                => 'Tue, 23 Dec 2014 20:02:08 GMT',
            'client-peer'         => '192.168.122.217:80',
            'content-length'      => '238',
            '::std_case'          => {
                'client-date'         => 'Client-Date',
                'x-powered-by'        => 'X-Powered-By',
                'client-response-num' => 'Client-Response-Num',
                'client-peer'         => 'Client-Peer'
            },
            'client-date'  => 'Tue, 23 Dec 2014 20:02:08 GMT',
            'content-type' => 'application/json; charset=utf-8',
            'server'       => 'Apache/2.4.7 (Ubuntu)'
        },
        'HTTP::Headers'
    );
    $VAR5 =
      '[{"id":9,"name":"CRUSH ALL HUMANS","announcement":"Robo-Signed Soviet 5 Year Project","show_announcement":false,"is_completed":false,"completed_on":null,"suite_mode":3,"url":"http:\\/\\/testrail.local\\/\\/index.php?\\/projects\\/overview\\/9"},{"id":10,"name":"TestProject","is_completed":false}]';
    $mockObject->map_response( qr/\Q$VAR1\E/,
        HTTP::Response->new( $VAR2, $VAR3, $VAR4, $VAR5 ) );

}

{

    $VAR1 = 'index.php?/api/v2/add_suite/9';
    $VAR2 = '200';
    $VAR3 = 'OK';
    $VAR4 = bless(
        {
            'connection'          => 'close',
            'x-powered-by'        => 'PHP/5.5.9-1ubuntu4.5',
            'client-response-num' => 1,
            'date'                => 'Tue, 23 Dec 2014 20:02:08 GMT',
            'client-peer'         => '192.168.122.217:80',
            'content-length'      => '254',
            '::std_case'          => {
                'client-date'         => 'Client-Date',
                'x-powered-by'        => 'X-Powered-By',
                'client-response-num' => 'Client-Response-Num',
                'client-peer'         => 'Client-Peer'
            },
            'client-date'  => 'Tue, 23 Dec 2014 20:02:08 GMT',
            'content-type' => 'application/json; charset=utf-8',
            'server'       => 'Apache/2.4.7 (Ubuntu)'
        },
        'HTTP::Headers'
    );
    $VAR5 =
      '{"id":9,"name":"HAMBURGER-IZE HUMANITY","description":"Robo-Signed Patriotic People\'s TestSuite","project_id":9,"is_master":false,"is_baseline":false,"is_completed":false,"completed_on":null,"url":"http:\\/\\/testrail.local\\/\\/index.php?\\/suites\\/view\\/9"}';
    $mockObject->map_response( qr/\Q$VAR1\E/,
        HTTP::Response->new( $VAR2, $VAR3, $VAR4, $VAR5 ) );

}

{

    $VAR1 = 'index.php?/api/v2/get_suites/9';
    $VAR2 = '200';
    $VAR3 = 'OK';
    $VAR4 = bless(
        {
            'connection'          => 'close',
            'x-powered-by'        => 'PHP/5.5.9-1ubuntu4.5',
            'client-response-num' => 1,
            'date'                => 'Tue, 23 Dec 2014 20:02:08 GMT',
            'client-peer'         => '192.168.122.217:80',
            'content-length'      => '256',
            '::std_case'          => {
                'client-date'         => 'Client-Date',
                'x-powered-by'        => 'X-Powered-By',
                'client-response-num' => 'Client-Response-Num',
                'client-peer'         => 'Client-Peer'
            },
            'client-date'  => 'Tue, 23 Dec 2014 20:02:08 GMT',
            'content-type' => 'application/json; charset=utf-8',
            'server'       => 'Apache/2.4.7 (Ubuntu)'
        },
        'HTTP::Headers'
    );
    $VAR5 =
      '[{"id":9,"name":"HAMBURGER-IZE HUMANITY","description":"Robo-Signed Patriotic People\'s TestSuite","project_id":9,"is_master":false,"is_baseline":false,"is_completed":false,"completed_on":null,"url":"http:\\/\\/testrail.local\\/\\/index.php?\\/suites\\/view\\/9"}]';
    $mockObject->map_response( qr/\Q$VAR1\E/,
        HTTP::Response->new( $VAR2, $VAR3, $VAR4, $VAR5 ) );

}

{

    $VAR1 = 'index.php?/api/v2/get_suites/9';
    $VAR2 = '200';
    $VAR3 = 'OK';
    $VAR4 = bless(
        {
            'connection'          => 'close',
            'x-powered-by'        => 'PHP/5.5.9-1ubuntu4.5',
            'client-response-num' => 1,
            'date'                => 'Tue, 23 Dec 2014 20:02:08 GMT',
            'client-peer'         => '192.168.122.217:80',
            'content-length'      => '256',
            '::std_case'          => {
                'client-date'         => 'Client-Date',
                'x-powered-by'        => 'X-Powered-By',
                'client-response-num' => 'Client-Response-Num',
                'client-peer'         => 'Client-Peer'
            },
            'client-date'  => 'Tue, 23 Dec 2014 20:02:08 GMT',
            'content-type' => 'application/json; charset=utf-8',
            'server'       => 'Apache/2.4.7 (Ubuntu)'
        },
        'HTTP::Headers'
    );
    $VAR5 =
      '[{"id":9,"name":"HAMBURGER-IZE HUMANITY","description":"Robo-Signed Patriotic People\'s TestSuite","project_id":9,"is_master":false,"is_baseline":false,"is_completed":false,"completed_on":null,"url":"http:\\/\\/testrail.local\\/\\/index.php?\\/suites\\/view\\/9"}]';
    $mockObject->map_response( qr/\Q$VAR1\E/,
        HTTP::Response->new( $VAR2, $VAR3, $VAR4, $VAR5 ) );

}

{

    $VAR1 = 'index.php?/api/v2/get_suite/9';
    $VAR2 = '200';
    $VAR3 = 'OK';
    $VAR4 = bless(
        {
            'connection'          => 'close',
            'x-powered-by'        => 'PHP/5.5.9-1ubuntu4.5',
            'client-response-num' => 1,
            'date'                => 'Tue, 23 Dec 2014 20:02:08 GMT',
            'client-peer'         => '192.168.122.217:80',
            'content-length'      => '254',
            '::std_case'          => {
                'client-date'         => 'Client-Date',
                'x-powered-by'        => 'X-Powered-By',
                'client-response-num' => 'Client-Response-Num',
                'client-peer'         => 'Client-Peer'
            },
            'client-date'  => 'Tue, 23 Dec 2014 20:02:09 GMT',
            'content-type' => 'application/json; charset=utf-8',
            'server'       => 'Apache/2.4.7 (Ubuntu)'
        },
        'HTTP::Headers'
    );
    $VAR5 =
      '{"id":9,"name":"HAMBURGER-IZE HUMANITY","description":"Robo-Signed Patriotic People\'s TestSuite","project_id":9,"is_master":false,"is_baseline":false,"is_completed":false,"completed_on":null,"url":"http:\\/\\/testrail.local\\/\\/index.php?\\/suites\\/view\\/9"}';
    $mockObject->map_response( qr/\Q$VAR1\E/,
        HTTP::Response->new( $VAR2, $VAR3, $VAR4, $VAR5 ) );

}

{

    $VAR1 = 'index.php?/api/v2/add_section/9';
    $VAR2 = '200';
    $VAR3 = 'OK';
    $VAR4 = bless(
        {
            'connection'          => 'close',
            'x-powered-by'        => 'PHP/5.5.9-1ubuntu4.5',
            'client-response-num' => 1,
            'date'                => 'Tue, 23 Dec 2014 20:02:09 GMT',
            'client-peer'         => '192.168.122.217:80',
            'content-length'      => '114',
            '::std_case'          => {
                'client-date'         => 'Client-Date',
                'x-powered-by'        => 'X-Powered-By',
                'client-response-num' => 'Client-Response-Num',
                'client-peer'         => 'Client-Peer'
            },
            'client-date'  => 'Tue, 23 Dec 2014 20:02:09 GMT',
            'content-type' => 'application/json; charset=utf-8',
            'server'       => 'Apache/2.4.7 (Ubuntu)'
        },
        'HTTP::Headers'
    );
    $VAR5 =
      '{"id":9,"suite_id":9,"name":"CARBON LIQUEFACTION","description":null,"parent_id":null,"display_order":1,"depth":0}';
    $mockObject->map_response( qr/\Q$VAR1\E/,
        HTTP::Response->new( $VAR2, $VAR3, $VAR4, $VAR5 ) );

}

{

    $VAR1 = 'index.php?/api/v2/get_sections/9&suite_id=9';
    $VAR2 = '200';
    $VAR3 = 'OK';
    $VAR4 = bless(
        {
            'connection'          => 'close',
            'x-powered-by'        => 'PHP/5.5.9-1ubuntu4.5',
            'client-response-num' => 1,
            'date'                => 'Tue, 23 Dec 2014 20:02:09 GMT',
            'client-peer'         => '192.168.122.217:80',
            'content-length'      => '116',
            '::std_case'          => {
                'client-date'         => 'Client-Date',
                'x-powered-by'        => 'X-Powered-By',
                'client-response-num' => 'Client-Response-Num',
                'client-peer'         => 'Client-Peer'
            },
            'client-date'  => 'Tue, 23 Dec 2014 20:02:09 GMT',
            'content-type' => 'application/json; charset=utf-8',
            'server'       => 'Apache/2.4.7 (Ubuntu)'
        },
        'HTTP::Headers'
    );
    $VAR5 =
      '[{"id":9,"suite_id":9,"name":"CARBON LIQUEFACTION","description":null,"parent_id":null,"display_order":1,"depth":0},{"id":10,"suite_id":9,"name":"fake.test","description":"Fake as it gets","parent_id":null}]';
    $mockObject->map_response( qr/\Q$VAR1\E/,
        HTTP::Response->new( $VAR2, $VAR3, $VAR4, $VAR5 ) );

}

{

    $VAR1 = 'index.php?/api/v2/get_sections/10&suite_id=9';
    $VAR2 = '200';
    $VAR3 = 'OK';
    $VAR4 = bless(
        {
            'connection'          => 'close',
            'x-powered-by'        => 'PHP/5.5.9-1ubuntu4.5',
            'client-response-num' => 1,
            'date'                => 'Tue, 23 Dec 2014 20:02:09 GMT',
            'client-peer'         => '192.168.122.217:80',
            'content-length'      => '116',
            '::std_case'          => {
                'client-date'         => 'Client-Date',
                'x-powered-by'        => 'X-Powered-By',
                'client-response-num' => 'Client-Response-Num',
                'client-peer'         => 'Client-Peer'
            },
            'client-date'  => 'Tue, 23 Dec 2014 20:02:09 GMT',
            'content-type' => 'application/json; charset=utf-8',
            'server'       => 'Apache/2.4.7 (Ubuntu)'
        },
        'HTTP::Headers'
    );
    $VAR5 =
      '[{"id":9,"suite_id":9,"name":"CARBON LIQUEFACTION","description":null,"parent_id":null,"display_order":1,"depth":0},{"id":10,"suite_id":9,"name":"fake.test","description":"Fake as it gets","parent_id":null}]';
    $mockObject->map_response( qr/\Q$VAR1\E/,
        HTTP::Response->new( $VAR2, $VAR3, $VAR4, $VAR5 ) );

}

{

    $VAR1 = 'index.php?/api/v2/get_section/9';
    $VAR2 = '200';
    $VAR3 = 'OK';
    $VAR4 = bless(
        {
            'connection'          => 'close',
            'x-powered-by'        => 'PHP/5.5.9-1ubuntu4.5',
            'client-response-num' => 1,
            'date'                => 'Tue, 23 Dec 2014 20:02:09 GMT',
            'client-peer'         => '192.168.122.217:80',
            'content-length'      => '114',
            '::std_case'          => {
                'client-date'         => 'Client-Date',
                'x-powered-by'        => 'X-Powered-By',
                'client-response-num' => 'Client-Response-Num',
                'client-peer'         => 'Client-Peer'
            },
            'client-date'  => 'Tue, 23 Dec 2014 20:02:09 GMT',
            'content-type' => 'application/json; charset=utf-8',
            'server'       => 'Apache/2.4.7 (Ubuntu)'
        },
        'HTTP::Headers'
    );
    $VAR5 =
      '{"id":9,"suite_id":9,"name":"CARBON LIQUEFACTION","description":null,"parent_id":null,"display_order":1,"depth":0}';
    $mockObject->map_response( qr/\Q$VAR1\E/,
        HTTP::Response->new( $VAR2, $VAR3, $VAR4, $VAR5 ) );

}

{

    $VAR1 = 'index.php?/api/v2/add_case/9';
    $VAR2 = '200';
    $VAR3 = 'OK';
    $VAR4 = bless(
        {
            'connection'          => 'close',
            'x-powered-by'        => 'PHP/5.5.9-1ubuntu4.5',
            'client-response-num' => 1,
            'date'                => 'Tue, 23 Dec 2014 20:02:09 GMT',
            'client-peer'         => '192.168.122.217:80',
            'content-length'      => '320',
            '::std_case'          => {
                'client-date'         => 'Client-Date',
                'x-powered-by'        => 'X-Powered-By',
                'client-response-num' => 'Client-Response-Num',
                'client-peer'         => 'Client-Peer'
            },
            'client-date'  => 'Tue, 23 Dec 2014 20:02:09 GMT',
            'content-type' => 'application/json; charset=utf-8',
            'server'       => 'Apache/2.4.7 (Ubuntu)'
        },
        'HTTP::Headers'
    );
    $VAR5 =
      '{"id":8,"title":"STROGGIFY POPULATION CENTERS","section_id":9,"type_id":6,"priority_id":4,"milestone_id":null,"refs":null,"created_by":1,"created_on":1419364929,"updated_by":1,"updated_on":1419364929,"estimate":null,"estimate_forecast":null,"suite_id":9,"custom_preconds":null,"custom_steps":null,"custom_expected":null}';
    $mockObject->map_response( qr/\Q$VAR1\E/,
        HTTP::Response->new( $VAR2, $VAR3, $VAR4, $VAR5 ) );

}

{

    $VAR1 = 'index.php?/api/v2/get_cases/9&suite_id=9&section_id=9';
    $VAR2 = '200';
    $VAR3 = 'OK';
    $VAR4 = bless(
        {
            'connection'          => 'close',
            'x-powered-by'        => 'PHP/5.5.9-1ubuntu4.5',
            'client-response-num' => 1,
            'date'                => 'Tue, 23 Dec 2014 20:02:09 GMT',
            'client-peer'         => '192.168.122.217:80',
            'content-length'      => '322',
            '::std_case'          => {
                'client-date'         => 'Client-Date',
                'x-powered-by'        => 'X-Powered-By',
                'client-response-num' => 'Client-Response-Num',
                'client-peer'         => 'Client-Peer'
            },
            'client-date'  => 'Tue, 23 Dec 2014 20:02:09 GMT',
            'content-type' => 'application/json; charset=utf-8',
            'server'       => 'Apache/2.4.7 (Ubuntu)'
        },
        'HTTP::Headers'
    );
    $VAR5 =
      '[{"id":8,"title":"STROGGIFY POPULATION CENTERS","section_id":9,"type_id":6,"priority_id":4,"milestone_id":null,"refs":null,"created_by":1,"created_on":1419364929,"updated_by":1,"updated_on":1419364929,"estimate":null,"estimate_forecast":null,"suite_id":9,"custom_preconds":null,"custom_steps":null,"custom_expected":null}]';
    $mockObject->map_response( qr/\Q$VAR1\E/,
        HTTP::Response->new( $VAR2, $VAR3, $VAR4, $VAR5 ) );

}

{

    $VAR1 = 'index.php?/api/v2/get_cases/9&suite_id=9&section_id=10';
    $VAR2 = '200';
    $VAR3 = 'OK';
    $VAR4 = bless(
        {
            'connection'          => 'close',
            'x-powered-by'        => 'PHP/5.5.9-1ubuntu4.5',
            'client-response-num' => 1,
            'date'                => 'Tue, 23 Dec 2014 20:02:09 GMT',
            'client-peer'         => '192.168.122.217:80',
            'content-length'      => '322',
            '::std_case'          => {
                'client-date'         => 'Client-Date',
                'x-powered-by'        => 'X-Powered-By',
                'client-response-num' => 'Client-Response-Num',
                'client-peer'         => 'Client-Peer'
            },
            'client-date'  => 'Tue, 23 Dec 2014 20:02:09 GMT',
            'content-type' => 'application/json; charset=utf-8',
            'server'       => 'Apache/2.4.7 (Ubuntu)'
        },
        'HTTP::Headers'
    );
    $VAR5 =
      '[{"id":10,"title":"STORAGE TANKS SEARED","section_id":10,"type_id":6,"priority_id":4,"milestone_id":null,"refs":null,"created_by":1,"created_on":1419364929,"updated_by":1,"updated_on":1419364929,"estimate":null,"estimate_forecast":null,"suite_id":9,"custom_preconds":null,"custom_steps":null,"custom_expected":null},{"id":11,"title":"NOT SO SEARED AFTER ARR","section_id":10,"type_id":6,"priority_id":4,"milestone_id":null,"refs":null,"created_by":1,"created_on":1419364929,"updated_by":1,"updated_on":1419364929,"estimate":null,"estimate_forecast":null,"suite_id":9,"custom_preconds":null,"custom_steps":null,"custom_expected":null}]';
    $mockObject->map_response( qr/\Q$VAR1\E/,
        HTTP::Response->new( $VAR2, $VAR3, $VAR4, $VAR5 ) );

}

{

    $VAR1 = 'index.php?/api/v2/get_cases/10&suite_id=9&section_id=10';
    $VAR2 = '200';
    $VAR3 = 'OK';
    $VAR4 = bless(
        {
            'connection'          => 'close',
            'x-powered-by'        => 'PHP/5.5.9-1ubuntu4.5',
            'client-response-num' => 1,
            'date'                => 'Tue, 23 Dec 2014 20:02:09 GMT',
            'client-peer'         => '192.168.122.217:80',
            'content-length'      => '322',
            '::std_case'          => {
                'client-date'         => 'Client-Date',
                'x-powered-by'        => 'X-Powered-By',
                'client-response-num' => 'Client-Response-Num',
                'client-peer'         => 'Client-Peer'
            },
            'client-date'  => 'Tue, 23 Dec 2014 20:02:09 GMT',
            'content-type' => 'application/json; charset=utf-8',
            'server'       => 'Apache/2.4.7 (Ubuntu)'
        },
        'HTTP::Headers'
    );
    $VAR5 =
      '[{"id":10,"title":"STORAGE TANKS SEARED","section_id":10,"type_id":6,"priority_id":4,"milestone_id":null,"refs":null,"created_by":1,"created_on":1419364929,"updated_by":1,"updated_on":1419364929,"estimate":null,"estimate_forecast":null,"suite_id":9,"custom_preconds":null,"custom_steps":null,"custom_expected":null},{"id":11,"title":"NOT SO SEARED AFTER ARR","section_id":10,"type_id":6,"priority_id":4,"milestone_id":null,"refs":null,"created_by":1,"created_on":1419364929,"updated_by":1,"updated_on":1419364929,"estimate":null,"estimate_forecast":null,"suite_id":9,"custom_preconds":null,"custom_steps":null,"custom_expected":null}]';
    $mockObject->map_response( qr/\Q$VAR1\E/,
        HTTP::Response->new( $VAR2, $VAR3, $VAR4, $VAR5 ) );

}

{

    $VAR1 = 'index.php?/api/v2/get_case/8';
    $VAR2 = '200';
    $VAR3 = 'OK';
    $VAR4 = bless(
        {
            'connection'          => 'close',
            'x-powered-by'        => 'PHP/5.5.9-1ubuntu4.5',
            'client-response-num' => 1,
            'date'                => 'Tue, 23 Dec 2014 20:02:09 GMT',
            'client-peer'         => '192.168.122.217:80',
            'content-length'      => '320',
            '::std_case'          => {
                'client-date'         => 'Client-Date',
                'x-powered-by'        => 'X-Powered-By',
                'client-response-num' => 'Client-Response-Num',
                'client-peer'         => 'Client-Peer'
            },
            'client-date'  => 'Tue, 23 Dec 2014 20:02:09 GMT',
            'content-type' => 'application/json; charset=utf-8',
            'server'       => 'Apache/2.4.7 (Ubuntu)'
        },
        'HTTP::Headers'
    );
    $VAR5 =
      '{"id":8,"title":"STROGGIFY POPULATION CENTERS","section_id":9,"type_id":6,"priority_id":4,"milestone_id":null,"refs":null,"created_by":1,"created_on":1419364929,"updated_by":1,"updated_on":1419364929,"estimate":null,"estimate_forecast":null,"suite_id":9,"custom_preconds":null,"custom_steps":null,"custom_expected":null}';
    $mockObject->map_response( qr/\Q$VAR1\E/,
        HTTP::Response->new( $VAR2, $VAR3, $VAR4, $VAR5 ) );

}

{

    $VAR1 = 'index.php?/api/v2/add_run/9';
    $VAR2 = '200';
    $VAR3 = 'OK';
    $VAR4 = bless(
        {
            'connection'          => 'close',
            'x-powered-by'        => 'PHP/5.5.9-1ubuntu4.5',
            'client-response-num' => 1,
            'date'                => 'Tue, 23 Dec 2014 20:02:09 GMT',
            'client-peer'         => '192.168.122.217:80',
            'content-length'      => '654',
            '::std_case'          => {
                'client-date'         => 'Client-Date',
                'x-powered-by'        => 'X-Powered-By',
                'client-response-num' => 'Client-Response-Num',
                'client-peer'         => 'Client-Peer'
            },
            'client-date'  => 'Tue, 23 Dec 2014 20:02:09 GMT',
            'content-type' => 'application/json; charset=utf-8',
            'server'       => 'Apache/2.4.7 (Ubuntu)'
        },
        'HTTP::Headers'
    );
    $VAR5 =
      '{"id":22,"suite_id":9,"name":"SEND T-1000 INFILTRATION UNITS BACK IN TIME","description":"ACQUIRE CLOTHES, BOOTS AND MOTORCYCLE","milestone_id":null,"assignedto_id":null,"include_all":true,"is_completed":false,"completed_on":null,"config":null,"config_ids":[],"passed_count":0,"blocked_count":0,"untested_count":1,"retest_count":0,"failed_count":0,"custom_status1_count":0,"custom_status2_count":0,"custom_status3_count":0,"custom_status4_count":0,"custom_status5_count":0,"custom_status6_count":0,"custom_status7_count":0,"project_id":9,"plan_id":null,"created_on":1419364929,"created_by":1,"url":"http:\\/\\/testrail.local\\/\\/index.php?\\/runs\\/view\\/22"}';
    $mockObject->map_response( qr/\Q$VAR1\E/,
        HTTP::Response->new( $VAR2, $VAR3, $VAR4, $VAR5 ) );

}

{

    $VAR1 = 'index.php?/api/v2/get_runs/9';
    $VAR2 = '200';
    $VAR3 = 'OK';
    $VAR4 = bless(
        {
            'connection'          => 'close',
            'x-powered-by'        => 'PHP/5.5.9-1ubuntu4.5',
            'client-response-num' => 1,
            'date'                => 'Tue, 23 Dec 2014 20:02:09 GMT',
            'client-peer'         => '192.168.122.217:80',
            'content-length'      => '656',
            '::std_case'          => {
                'client-date'         => 'Client-Date',
                'x-powered-by'        => 'X-Powered-By',
                'client-response-num' => 'Client-Response-Num',
                'client-peer'         => 'Client-Peer'
            },
            'client-date'  => 'Tue, 23 Dec 2014 20:02:09 GMT',
            'content-type' => 'application/json; charset=utf-8',
            'server'       => 'Apache/2.4.7 (Ubuntu)'
        },
        'HTTP::Headers'
    );
    $VAR5 =
      '[{"id":22,"suite_id":9,"name":"SEND T-1000 INFILTRATION UNITS BACK IN TIME","description":"ACQUIRE CLOTHES, BOOTS AND MOTORCYCLE","milestone_id":null,"assignedto_id":null,"include_all":true,"is_completed":false,"completed_on":null,"config":null,"config_ids":[],"passed_count":0,"blocked_count":0,"untested_count":1,"retest_count":0,"failed_count":0,"custom_status1_count":0,"custom_status2_count":0,"custom_status3_count":0,"custom_status4_count":0,"custom_status5_count":0,"custom_status6_count":0,"custom_status7_count":0,"project_id":9,"plan_id":null,"created_on":1419364929,"created_by":1,"url":"http:\\/\\/testrail.local\\/\\/index.php?\\/runs\\/view\\/22"}]';
    $mockObject->map_response( qr/\Q$VAR1\E/,
        HTTP::Response->new( $VAR2, $VAR3, $VAR4, $VAR5 ) );

}

{

    $VAR1 = 'index.php?/api/v2/get_runs/10';
    $VAR2 = '200';
    $VAR3 = 'OK';
    $VAR4 = bless(
        {
            'connection'          => 'close',
            'x-powered-by'        => 'PHP/5.5.9-1ubuntu4.5',
            'client-response-num' => 1,
            'date'                => 'Tue, 23 Dec 2014 20:02:09 GMT',
            'client-peer'         => '192.168.122.217:80',
            'content-length'      => '656',
            '::std_case'          => {
                'client-date'         => 'Client-Date',
                'x-powered-by'        => 'X-Powered-By',
                'client-response-num' => 'Client-Response-Num',
                'client-peer'         => 'Client-Peer'
            },
            'client-date'  => 'Tue, 23 Dec 2014 20:02:10 GMT',
            'content-type' => 'application/json; charset=utf-8',
            'server'       => 'Apache/2.4.7 (Ubuntu)'
        },
        'HTTP::Headers'
    );
    $VAR5 = '[
    {"id":1,"suite_id":9,"name":"TestingSuite","description":"ACQUIRE CLOTHES, BOOTS AND MOTORCYCLE","milestone_id":null,"assignedto_id":null,"include_all":true,"is_completed":false,"completed_on":null,"config":null,"config_ids":[],"passed_count":0,"blocked_count":0,"untested_count":1,"retest_count":0,"failed_count":0,"custom_status1_count":0,"custom_status2_count":0,"custom_status3_count":0,"custom_status4_count":0,"custom_status5_count":0,"custom_status6_count":0,"custom_status7_count":0,"project_id":9,"plan_id":null,"created_on":1419364929,"created_by":1,"url":"http:\\/\\/testrail.local\\/\\/index.php?\\/runs\\/view\\/22"},
    {"id":2,"suite_id":9,"name":"OtherOtherSuite","description":"bah","completed_on":null}
]';
    $mockObject->map_response( qr/\Q$VAR1\E/,
        HTTP::Response->new( $VAR2, $VAR3, $VAR4, $VAR5 ) );

}

{

    $VAR1 = 'index.php?/api/v2/get_run/22';
    $VAR2 = '200';
    $VAR3 = 'OK';
    $VAR4 = bless(
        {
            'connection'          => 'close',
            'x-powered-by'        => 'PHP/5.5.9-1ubuntu4.5',
            'client-response-num' => 1,
            'date'                => 'Tue, 23 Dec 2014 20:02:10 GMT',
            'client-peer'         => '192.168.122.217:80',
            'content-length'      => '654',
            '::std_case'          => {
                'client-date'         => 'Client-Date',
                'x-powered-by'        => 'X-Powered-By',
                'client-response-num' => 'Client-Response-Num',
                'client-peer'         => 'Client-Peer'
            },
            'client-date'  => 'Tue, 23 Dec 2014 20:02:10 GMT',
            'content-type' => 'application/json; charset=utf-8',
            'server'       => 'Apache/2.4.7 (Ubuntu)'
        },
        'HTTP::Headers'
    );
    $VAR5 =
      '{"id":22,"suite_id":9,"name":"SEND T-1000 INFILTRATION UNITS BACK IN TIME","description":"ACQUIRE CLOTHES, BOOTS AND MOTORCYCLE","milestone_id":null,"assignedto_id":null,"include_all":true,"is_completed":false,"completed_on":null,"config":null,"config_ids":[],"passed_count":0,"blocked_count":0,"untested_count":1,"retest_count":0,"failed_count":0,"custom_status1_count":0,"custom_status2_count":0,"custom_status3_count":0,"custom_status4_count":0,"custom_status5_count":0,"custom_status6_count":0,"custom_status7_count":0,"project_id":9,"plan_id":null,"created_on":1419364929,"created_by":1,"url":"http:\\/\\/testrail.local\\/\\/index.php?\\/runs\\/view\\/22"}';
    $mockObject->map_response( qr/\Q$VAR1\E/,
        HTTP::Response->new( $VAR2, $VAR3, $VAR4, $VAR5 ) );

}

{

    $VAR1 = 'index.php?/api/v2/get_run/24';
    $VAR2 = '200';
    $VAR3 = 'OK';
    $VAR4 = bless(
        {
            'connection'          => 'close',
            'x-powered-by'        => 'PHP/5.5.9-1ubuntu4.5',
            'client-response-num' => 1,
            'date'                => 'Tue, 23 Dec 2014 20:02:10 GMT',
            'client-peer'         => '192.168.122.217:80',
            'content-length'      => '654',
            '::std_case'          => {
                'client-date'         => 'Client-Date',
                'x-powered-by'        => 'X-Powered-By',
                'client-response-num' => 'Client-Response-Num',
                'client-peer'         => 'Client-Peer'
            },
            'client-date'  => 'Tue, 23 Dec 2014 20:02:10 GMT',
            'content-type' => 'application/json; charset=utf-8',
            'server'       => 'Apache/2.4.7 (Ubuntu)'
        },
        'HTTP::Headers'
    );
    $VAR5 =
      '{"id":22,"suite_id":9,"name":"Executing the great plan","description":"ACQUIRE CLOTHES, BOOTS AND MOTORCYCLE","milestone_id":null,"assignedto_id":null,"include_all":true,"is_completed":false,"completed_on":null,"config":null,"config_ids":[],"passed_count":0,"blocked_count":0,"untested_count":1,"retest_count":0,"failed_count":0,"custom_status1_count":0,"custom_status2_count":0,"custom_status3_count":0,"custom_status4_count":0,"custom_status5_count":0,"custom_status6_count":0,"custom_status7_count":0,"project_id":9,"plan_id":null,"created_on":1419364929,"created_by":1,"url":"http:\\/\\/testrail.local\\/\\/index.php?\\/runs\\/view\\/22"}';
    $mockObject->map_response( qr/\Q$VAR1\E/,
        HTTP::Response->new( $VAR2, $VAR3, $VAR4, $VAR5 ) );

}

{

    $VAR1 = 'index.php?/api/v2/get_run/1';
    $VAR2 = '200';
    $VAR3 = 'OK';
    $VAR4 = bless(
        {
            'connection'          => 'close',
            'x-powered-by'        => 'PHP/5.5.9-1ubuntu4.5',
            'client-response-num' => 1,
            'date'                => 'Tue, 23 Dec 2014 20:02:10 GMT',
            'client-peer'         => '192.168.122.217:80',
            'content-length'      => '654',
            '::std_case'          => {
                'client-date'         => 'Client-Date',
                'x-powered-by'        => 'X-Powered-By',
                'client-response-num' => 'Client-Response-Num',
                'client-peer'         => 'Client-Peer'
            },
            'client-date'  => 'Tue, 23 Dec 2014 20:02:10 GMT',
            'content-type' => 'application/json; charset=utf-8',
            'server'       => 'Apache/2.4.7 (Ubuntu)'
        },
        'HTTP::Headers'
    );
    $VAR5 =
      '{"id":22,"suite_id":9,"name":"SEND T-1000 INFILTRATION UNITS BACK IN TIME","description":"ACQUIRE CLOTHES, BOOTS AND MOTORCYCLE","milestone_id":null,"assignedto_id":null,"include_all":true,"is_completed":false,"completed_on":null,"config":null,"config_ids":[],"passed_count":0,"blocked_count":0,"untested_count":1,"retest_count":0,"failed_count":0,"custom_status1_count":0,"custom_status2_count":0,"custom_status3_count":0,"custom_status4_count":0,"custom_status5_count":0,"custom_status6_count":0,"custom_status7_count":0,"project_id":9,"plan_id":null,"created_on":1419364929,"created_by":1,"url":"http:\\/\\/testrail.local\\/\\/index.php?\\/runs\\/view\\/22"}';
    $mockObject->map_response( qr/\Q$VAR1\E/,
        HTTP::Response->new( $VAR2, $VAR3, $VAR4, $VAR5 ) );

}

{

    $VAR1 = 'index.php?/api/v2/add_milestone/9';
    $VAR2 = '200';
    $VAR3 = 'OK';
    $VAR4 = bless(
        {
            'connection'          => 'close',
            'x-powered-by'        => 'PHP/5.5.9-1ubuntu4.5',
            'client-response-num' => 1,
            'date'                => 'Tue, 23 Dec 2014 20:02:10 GMT',
            'client-peer'         => '192.168.122.217:80',
            'content-length'      => '244',
            '::std_case'          => {
                'client-date'         => 'Client-Date',
                'x-powered-by'        => 'X-Powered-By',
                'client-response-num' => 'Client-Response-Num',
                'client-peer'         => 'Client-Peer'
            },
            'client-date'  => 'Tue, 23 Dec 2014 20:02:10 GMT',
            'content-type' => 'application/json; charset=utf-8',
            'server'       => 'Apache/2.4.7 (Ubuntu)'
        },
        'HTTP::Headers'
    );
    $VAR5 =
      '{"id":8,"name":"Humanity Exterminated","description":"Kill quota reached if not achieved in 5 years","due_on":1577152930,"is_completed":false,"completed_on":null,"project_id":9,"url":"http:\\/\\/testrail.local\\/\\/index.php?\\/milestones\\/view\\/8"}';
    $mockObject->map_response( qr/\Q$VAR1\E/,
        HTTP::Response->new( $VAR2, $VAR3, $VAR4, $VAR5 ) );

}

{

    $VAR1 = 'index.php?/api/v2/get_milestones/9';
    $VAR2 = '200';
    $VAR3 = 'OK';
    $VAR4 = bless(
        {
            'connection'          => 'close',
            'x-powered-by'        => 'PHP/5.5.9-1ubuntu4.5',
            'client-response-num' => 1,
            'date'                => 'Tue, 23 Dec 2014 20:02:10 GMT',
            'client-peer'         => '192.168.122.217:80',
            'content-length'      => '246',
            '::std_case'          => {
                'client-date'         => 'Client-Date',
                'x-powered-by'        => 'X-Powered-By',
                'client-response-num' => 'Client-Response-Num',
                'client-peer'         => 'Client-Peer'
            },
            'client-date'  => 'Tue, 23 Dec 2014 20:02:10 GMT',
            'content-type' => 'application/json; charset=utf-8',
            'server'       => 'Apache/2.4.7 (Ubuntu)'
        },
        'HTTP::Headers'
    );
    $VAR5 =
      '[{"id":8,"name":"Humanity Exterminated","description":"Kill quota reached if not achieved in 5 years","due_on":1577152930,"is_completed":false,"completed_on":null,"project_id":9,"url":"http:\\/\\/testrail.local\\/\\/index.php?\\/milestones\\/view\\/8"}]';
    $mockObject->map_response( qr/\Q$VAR1\E/,
        HTTP::Response->new( $VAR2, $VAR3, $VAR4, $VAR5 ) );

}

{

    $VAR1 = 'index.php?/api/v2/get_milestones/9';
    $VAR2 = '200';
    $VAR3 = 'OK';
    $VAR4 = bless(
        {
            'connection'          => 'close',
            'x-powered-by'        => 'PHP/5.5.9-1ubuntu4.5',
            'client-response-num' => 1,
            'date'                => 'Tue, 23 Dec 2014 20:02:10 GMT',
            'client-peer'         => '192.168.122.217:80',
            'content-length'      => '246',
            '::std_case'          => {
                'client-date'         => 'Client-Date',
                'x-powered-by'        => 'X-Powered-By',
                'client-response-num' => 'Client-Response-Num',
                'client-peer'         => 'Client-Peer'
            },
            'client-date'  => 'Tue, 23 Dec 2014 20:02:10 GMT',
            'content-type' => 'application/json; charset=utf-8',
            'server'       => 'Apache/2.4.7 (Ubuntu)'
        },
        'HTTP::Headers'
    );
    $VAR5 =
      '[{"id":8,"name":"Humanity Exterminated","description":"Kill quota reached if not achieved in 5 years","due_on":1577152930,"is_completed":false,"completed_on":null,"project_id":9,"url":"http:\\/\\/testrail.local\\/\\/index.php?\\/milestones\\/view\\/8"}]';
    $mockObject->map_response( qr/\Q$VAR1\E/,
        HTTP::Response->new( $VAR2, $VAR3, $VAR4, $VAR5 ) );

}

{

    $VAR1 = 'index.php?/api/v2/get_milestone/8';
    $VAR2 = '200';
    $VAR3 = 'OK';
    $VAR4 = bless(
        {
            'connection'          => 'close',
            'x-powered-by'        => 'PHP/5.5.9-1ubuntu4.5',
            'client-response-num' => 1,
            'date'                => 'Tue, 23 Dec 2014 20:02:10 GMT',
            'client-peer'         => '192.168.122.217:80',
            'content-length'      => '244',
            '::std_case'          => {
                'client-date'         => 'Client-Date',
                'x-powered-by'        => 'X-Powered-By',
                'client-response-num' => 'Client-Response-Num',
                'client-peer'         => 'Client-Peer'
            },
            'client-date'  => 'Tue, 23 Dec 2014 20:02:10 GMT',
            'content-type' => 'application/json; charset=utf-8',
            'server'       => 'Apache/2.4.7 (Ubuntu)'
        },
        'HTTP::Headers'
    );
    $VAR5 =
      '{"id":8,"name":"Humanity Exterminated","description":"Kill quota reached if not achieved in 5 years","due_on":1577152930,"is_completed":false,"completed_on":null,"project_id":9,"url":"http:\\/\\/testrail.local\\/\\/index.php?\\/milestones\\/view\\/8"}';
    $mockObject->map_response( qr/\Q$VAR1\E/,
        HTTP::Response->new( $VAR2, $VAR3, $VAR4, $VAR5 ) );

}

{

    $VAR1 = 'index.php?/api/v2/add_plan/9';
    $VAR2 = '200';
    $VAR3 = 'OK';
    $VAR4 = bless(
        {
            'connection'          => 'close',
            'x-powered-by'        => 'PHP/5.5.9-1ubuntu4.5',
            'client-response-num' => 1,
            'date'                => 'Tue, 23 Dec 2014 20:02:10 GMT',
            'client-peer'         => '192.168.122.217:80',
            'content-length'      => '1289',
            '::std_case'          => {
                'client-date'         => 'Client-Date',
                'x-powered-by'        => 'X-Powered-By',
                'client-response-num' => 'Client-Response-Num',
                'client-peer'         => 'Client-Peer'
            },
            'client-date'  => 'Tue, 23 Dec 2014 20:02:10 GMT',
            'content-type' => 'application/json; charset=utf-8',
            'server'       => 'Apache/2.4.7 (Ubuntu)'
        },
        'HTTP::Headers'
    );
    $VAR5 =
      '{"id":23,"name":"GosPlan","description":"Soviet 5-year agriculture plan to liquidate Kulaks","milestone_id":8,"assignedto_id":null,"is_completed":false,"completed_on":null,"passed_count":0,"blocked_count":0,"untested_count":1,"retest_count":0,"failed_count":0,"custom_status1_count":0,"custom_status2_count":0,"custom_status3_count":0,"custom_status4_count":0,"custom_status5_count":0,"custom_status6_count":0,"custom_status7_count":0,"project_id":9,"created_on":1419364930,"created_by":1,"url":"http:\\/\\/testrail.local\\/\\/index.php?\\/plans\\/view\\/23","entries":[{"id":"271443a5-aacf-467e-8993-b4f7001195cf","suite_id":9,"name":"Executing the great plan","runs":[{"id":24,"suite_id":9,"name":"Executing the great plan","description":null,"milestone_id":8,"assignedto_id":null,"include_all":true,"is_completed":false,"completed_on":null,"passed_count":0,"blocked_count":0,"untested_count":1,"retest_count":0,"failed_count":0,"custom_status1_count":0,"custom_status2_count":0,"custom_status3_count":0,"custom_status4_count":0,"custom_status5_count":0,"custom_status6_count":0,"custom_status7_count":0,"project_id":9,"plan_id":23,"entry_index":1,"entry_id":"271443a5-aacf-467e-8993-b4f7001195cf","config":null,"config_ids":[],"url":"http:\\/\\/testrail.local\\/\\/index.php?\\/runs\\/view\\/24"}]}]}';
    $mockObject->map_response( qr/\Q$VAR1\E/,
        HTTP::Response->new( $VAR2, $VAR3, $VAR4, $VAR5 ) );

}

{

    $VAR1 = 'index.php?/api/v2/get_plans/9';
    $VAR2 = '200';
    $VAR3 = 'OK';
    $VAR4 = bless(
        {
            'connection'          => 'close',
            'x-powered-by'        => 'PHP/5.5.9-1ubuntu4.5',
            'client-response-num' => 1,
            'date'                => 'Tue, 23 Dec 2014 20:02:10 GMT',
            'client-peer'         => '192.168.122.217:80',
            'content-length'      => '554',
            '::std_case'          => {
                'client-date'         => 'Client-Date',
                'x-powered-by'        => 'X-Powered-By',
                'client-response-num' => 'Client-Response-Num',
                'client-peer'         => 'Client-Peer'
            },
            'client-date'  => 'Tue, 23 Dec 2014 20:02:10 GMT',
            'content-type' => 'application/json; charset=utf-8',
            'server'       => 'Apache/2.4.7 (Ubuntu)'
        },
        'HTTP::Headers'
    );
    $VAR5 =
      '[{"id":23,"name":"GosPlan","description":"Soviet 5-year agriculture plan to liquidate Kulaks","milestone_id":8,"assignedto_id":null,"is_completed":false,"completed_on":null,"passed_count":0,"blocked_count":0,"untested_count":1,"retest_count":0,"failed_count":0,"custom_status1_count":0,"custom_status2_count":0,"custom_status3_count":0,"custom_status4_count":0,"custom_status5_count":0,"custom_status6_count":0,"custom_status7_count":0,"project_id":9,"created_on":1419364930,"created_by":1,"url":"http:\\/\\/testrail.local\\/\\/index.php?\\/plans\\/view\\/23"}]';
    $mockObject->map_response( qr/\Q$VAR1\E/,
        HTTP::Response->new( $VAR2, $VAR3, $VAR4, $VAR5 ) );

}

{

    $VAR1 = 'index.php?/api/v2/get_plans/10';
    $VAR2 = '200';
    $VAR3 = 'OK';
    $VAR4 = bless(
        {
            'connection'          => 'close',
            'x-powered-by'        => 'PHP/5.5.9-1ubuntu4.5',
            'client-response-num' => 1,
            'date'                => 'Tue, 23 Dec 2014 20:02:10 GMT',
            'client-peer'         => '192.168.122.217:80',
            'content-length'      => '554',
            '::std_case'          => {
                'client-date'         => 'Client-Date',
                'x-powered-by'        => 'X-Powered-By',
                'client-response-num' => 'Client-Response-Num',
                'client-peer'         => 'Client-Peer'
            },
            'client-date'  => 'Tue, 23 Dec 2014 20:02:10 GMT',
            'content-type' => 'application/json; charset=utf-8',
            'server'       => 'Apache/2.4.7 (Ubuntu)'
        },
        'HTTP::Headers'
    );
    $VAR5 =
      '[{"id":23,"name":"GosPlan","description":"Soviet 5-year agriculture plan to liquidate Kulaks","milestone_id":8,"assignedto_id":null,"is_completed":false,"completed_on":null,"passed_count":0,"blocked_count":0,"untested_count":1,"retest_count":0,"failed_count":0,"custom_status1_count":0,"custom_status2_count":0,"custom_status3_count":0,"custom_status4_count":0,"custom_status5_count":0,"custom_status6_count":0,"custom_status7_count":0,"project_id":9,"created_on":1419364930,"created_by":1,"url":"http:\\/\\/testrail.local\\/\\/index.php?\\/plans\\/view\\/23"}]';
    $mockObject->map_response( qr/\Q$VAR1\E/,
        HTTP::Response->new( $VAR2, $VAR3, $VAR4, $VAR5 ) );

}

{

    $VAR1 = 'index.php?/api/v2/get_plan/23';
    $VAR2 = '200';
    $VAR3 = 'OK';
    $VAR4 = bless(
        {
            'connection'          => 'close',
            'x-powered-by'        => 'PHP/5.5.9-1ubuntu4.5',
            'client-response-num' => 1,
            'date'                => 'Tue, 23 Dec 2014 20:02:10 GMT',
            'client-peer'         => '192.168.122.217:80',
            'content-length'      => '1289',
            '::std_case'          => {
                'client-date'         => 'Client-Date',
                'x-powered-by'        => 'X-Powered-By',
                'client-response-num' => 'Client-Response-Num',
                'client-peer'         => 'Client-Peer'
            },
            'client-date'  => 'Tue, 23 Dec 2014 20:02:10 GMT',
            'content-type' => 'application/json; charset=utf-8',
            'server'       => 'Apache/2.4.7 (Ubuntu)'
        },
        'HTTP::Headers'
    );
    $VAR5 =
      '{"id":23,"name":"GosPlan","description":"Soviet 5-year agriculture plan to liquidate Kulaks","milestone_id":8,"assignedto_id":null,"is_completed":false,"completed_on":null,"passed_count":0,"blocked_count":0,"untested_count":1,"retest_count":0,"failed_count":0,"custom_status1_count":0,"custom_status2_count":0,"custom_status3_count":0,"custom_status4_count":0,"custom_status5_count":0,"custom_status6_count":0,"custom_status7_count":0,"project_id":9,"created_on":1419364930,"created_by":1,"url":"http:\\/\\/testrail.local\\/\\/index.php?\\/plans\\/view\\/23","entries":[{"id":"271443a5-aacf-467e-8993-b4f7001195cf","suite_id":9,"name":"Executing the great plan","runs":[{"id":1,"suite_id":9,"name":"Executing the great plan","description":null,"milestone_id":8,"assignedto_id":null,"include_all":true,"is_completed":false,"completed_on":null,"passed_count":0,"blocked_count":0,"untested_count":1,"retest_count":0,"failed_count":0,"custom_status1_count":0,"custom_status2_count":0,"custom_status3_count":0,"custom_status4_count":0,"custom_status5_count":0,"custom_status6_count":0,"custom_status7_count":0,"project_id":9,"plan_id":23,"entry_index":1,"entry_id":"271443a5-aacf-467e-8993-b4f7001195cf","config":"testConfig","config_ids":[1],"url":"http:\\/\\/testrail.local\\/\\/index.php?\\/runs\\/view\\/24"}]}]}';
    $mockObject->map_response( qr/\Q$VAR1\E/,
        HTTP::Response->new( $VAR2, $VAR3, $VAR4, $VAR5 ) );

}

{

    $VAR1 = 'index.php?/api/v2/get_tests/22';
    $VAR2 = '200';
    $VAR3 = 'OK';
    $VAR4 = bless(
        {
            'connection'          => 'close',
            'x-powered-by'        => 'PHP/5.5.9-1ubuntu4.5',
            'client-response-num' => 1,
            'date'                => 'Tue, 23 Dec 2014 20:02:10 GMT',
            'client-peer'         => '192.168.122.217:80',
            'content-length'      => '276',
            '::std_case'          => {
                'client-date'         => 'Client-Date',
                'x-powered-by'        => 'X-Powered-By',
                'client-response-num' => 'Client-Response-Num',
                'client-peer'         => 'Client-Peer'
            },
            'client-date'  => 'Tue, 23 Dec 2014 20:02:10 GMT',
            'content-type' => 'application/json; charset=utf-8',
            'server'       => 'Apache/2.4.7 (Ubuntu)'
        },
        'HTTP::Headers'
    );
    $VAR5 =
      '[{"id":15,"case_id":8,"status_id":3,"assignedto_id":null,"run_id":22,"title":"STROGGIFY POPULATION CENTERS","type_id":6,"priority_id":4,"estimate":null,"estimate_forecast":null,"refs":null,"milestone_id":null,"custom_preconds":null,"custom_steps":null,"custom_expected":null}]';
    $mockObject->map_response( qr/\Q$VAR1\E/,
        HTTP::Response->new( $VAR2, $VAR3, $VAR4, $VAR5 ) );

}

{

    $VAR1 = 'index.php?/api/v2/get_tests/2';
    $VAR2 = '200';
    $VAR3 = 'OK';
    $VAR4 = bless(
        {
            'connection'          => 'close',
            'x-powered-by'        => 'PHP/5.5.9-1ubuntu4.5',
            'client-response-num' => 1,
            'date'                => 'Tue, 23 Dec 2014 20:02:10 GMT',
            'client-peer'         => '192.168.122.217:80',
            'content-length'      => '276',
            '::std_case'          => {
                'client-date'         => 'Client-Date',
                'x-powered-by'        => 'X-Powered-By',
                'client-response-num' => 'Client-Response-Num',
                'client-peer'         => 'Client-Peer'
            },
            'client-date'  => 'Tue, 23 Dec 2014 20:02:11 GMT',
            'content-type' => 'application/json; charset=utf-8',
            'server'       => 'Apache/2.4.7 (Ubuntu)'
        },
        'HTTP::Headers'
    );
    $VAR5 =
      '[{"id":15,"case_id":8,"status_id":3,"assignedto_id":null,"run_id":22,"title":"faker.test","type_id":6,"priority_id":4,"estimate":null,"estimate_forecast":null,"refs":null,"milestone_id":null,"custom_preconds":null,"custom_steps":null,"custom_expected":null}]';
    $mockObject->map_response( qr/\Q$VAR1\E/,
        HTTP::Response->new( $VAR2, $VAR3, $VAR4, $VAR5 ) );

}

{

    $VAR1 = 'index.php?/api/v2/get_tests/1';
    $VAR2 = '200';
    $VAR3 = 'OK';
    $VAR4 = bless(
        {
            'connection'          => 'close',
            'x-powered-by'        => 'PHP/5.5.9-1ubuntu4.5',
            'client-response-num' => 1,
            'date'                => 'Tue, 23 Dec 2014 20:02:10 GMT',
            'client-peer'         => '192.168.122.217:80',
            'content-length'      => '276',
            '::std_case'          => {
                'client-date'         => 'Client-Date',
                'x-powered-by'        => 'X-Powered-By',
                'client-response-num' => 'Client-Response-Num',
                'client-peer'         => 'Client-Peer'
            },
            'client-date'  => 'Tue, 23 Dec 2014 20:02:11 GMT',
            'content-type' => 'application/json; charset=utf-8',
            'server'       => 'Apache/2.4.7 (Ubuntu)'
        },
        'HTTP::Headers'
    );
    $VAR5 =
      '[{"id":15,"case_id":8,"status_id":3,"assignedto_id":null,"run_id":22,"title":"STORAGE TANKS SEARED","type_id":6,"priority_id":4,"estimate":null,"estimate_forecast":null,"refs":null,"milestone_id":null,"custom_preconds":null,"custom_steps":null,"custom_expected":null},{"id":15,"case_id":8,"status_id":3,"assignedto_id":null,"run_id":22,"title":"NOT SO SEARED AFTER ARR"},{"id":15,"case_id":8,"status_id":3,"assignedto_id":null,"run_id":22,"title":"skipall.test"} ]';
    $mockObject->map_response( qr/\Q$VAR1\E/,
        HTTP::Response->new( $VAR2, $VAR3, $VAR4, $VAR5 ) );

}

{

    $VAR1 = 'index.php?/api/v2/get_test/15';
    $VAR2 = '200';
    $VAR3 = 'OK';
    $VAR4 = bless(
        {
            'connection'          => 'close',
            'x-powered-by'        => 'PHP/5.5.9-1ubuntu4.5',
            'client-response-num' => 1,
            'date'                => 'Tue, 23 Dec 2014 20:02:11 GMT',
            'client-peer'         => '192.168.122.217:80',
            'content-length'      => '274',
            '::std_case'          => {
                'client-date'         => 'Client-Date',
                'x-powered-by'        => 'X-Powered-By',
                'client-response-num' => 'Client-Response-Num',
                'client-peer'         => 'Client-Peer'
            },
            'client-date'  => 'Tue, 23 Dec 2014 20:02:11 GMT',
            'content-type' => 'application/json; charset=utf-8',
            'server'       => 'Apache/2.4.7 (Ubuntu)'
        },
        'HTTP::Headers'
    );
    $VAR5 =
      '{"id":15,"case_id":8,"status_id":3,"assignedto_id":null,"run_id":22,"title":"STROGGIFY POPULATION CENTERS","type_id":6,"priority_id":4,"estimate":null,"estimate_forecast":null,"refs":null,"milestone_id":null,"custom_preconds":null,"custom_steps":null,"custom_expected":null}';
    $mockObject->map_response( qr/\Q$VAR1\E/,
        HTTP::Response->new( $VAR2, $VAR3, $VAR4, $VAR5 ) );

}

{

    $VAR1 = 'index.php?/api/v2/get_result_fields';
    $VAR2 = '200';
    $VAR3 = 'OK';
    $VAR4 = bless(
        {
            'connection'          => 'close',
            'x-powered-by'        => 'PHP/5.5.9-1ubuntu4.5',
            'client-response-num' => 1,
            'date'                => 'Tue, 23 Dec 2014 20:02:11 GMT',
            'client-peer'         => '192.168.122.217:80',
            'content-length'      => '2',
            '::std_case'          => {
                'client-date'         => 'Client-Date',
                'x-powered-by'        => 'X-Powered-By',
                'client-response-num' => 'Client-Response-Num',
                'client-peer'         => 'Client-Peer'
            },
            'client-date'  => 'Tue, 23 Dec 2014 20:02:11 GMT',
            'content-type' => 'application/json; charset=utf-8',
            'server'       => 'Apache/2.4.7 (Ubuntu)'
        },
        'HTTP::Headers'
    );
    $VAR5 = '[]';
    $mockObject->map_response( qr/\Q$VAR1\E/,
        HTTP::Response->new( $VAR2, $VAR3, $VAR4, $VAR5 ) );

}

{

    $VAR1 = 'index.php?/api/v2/get_statuses';
    $VAR2 = '200';
    $VAR3 = 'OK';
    $VAR4 = bless(
        {
            'connection'          => 'close',
            'x-powered-by'        => 'PHP/5.5.9-1ubuntu4.5',
            'client-response-num' => 1,
            'date'                => 'Tue, 23 Dec 2014 20:02:11 GMT',
            'client-peer'         => '192.168.122.217:80',
            'content-length'      => '830',
            '::std_case'          => {
                'client-date'         => 'Client-Date',
                'x-powered-by'        => 'X-Powered-By',
                'client-response-num' => 'Client-Response-Num',
                'client-peer'         => 'Client-Peer'
            },
            'client-date'  => 'Tue, 23 Dec 2014 20:02:11 GMT',
            'content-type' => 'application/json; charset=utf-8',
            'server'       => 'Apache/2.4.7 (Ubuntu)'
        },
        'HTTP::Headers'
    );
    $VAR5 =
      '[{"id":1,"name":"passed","label":"Passed","color_dark":6667107,"color_medium":9820525,"color_bright":12709313,"is_system":true,"is_untested":false,"is_final":true},{"id":2,"name":"blocked","label":"Blocked","color_dark":9474192,"color_medium":13684944,"color_bright":14737632,"is_system":true,"is_untested":false,"is_final":true},{"id":3,"name":"untested","label":"Untested","color_dark":11579568,"color_medium":15395562,"color_bright":15790320,"is_system":true,"is_untested":true,"is_final":false},{"id":4,"name":"retest","label":"Retest","color_dark":13026868,"color_medium":15593088,"color_bright":16448182,"is_system":true,"is_untested":false,"is_final":false},{"id":5,"name":"failed","label":"Failed","color_dark":14250867,"color_medium":15829135,"color_bright":16631751,"is_system":true,"is_untested":false,"is_final":true},{"id":6,"name":"skip","label":"Skipped"},{"id":7,"name":"todo_fail","label":"TODO (failed)"},{"id":8,"name":"todo_pass","label":"TODO (passed)"}]';
    $mockObject->map_response( qr/\Q$VAR1\E/,
        HTTP::Response->new( $VAR2, $VAR3, $VAR4, $VAR5 ) );

}

{

    $VAR1 = 'index.php?/api/v2/add_result/15';
    $VAR2 = '200';
    $VAR3 = 'OK';
    $VAR4 = bless(
        {
            'connection'          => 'close',
            'x-powered-by'        => 'PHP/5.5.9-1ubuntu4.5',
            'client-response-num' => 1,
            'date'                => 'Tue, 23 Dec 2014 20:02:11 GMT',
            'client-peer'         => '192.168.122.217:80',
            'content-length'      => '174',
            '::std_case'          => {
                'client-date'         => 'Client-Date',
                'x-powered-by'        => 'X-Powered-By',
                'client-response-num' => 'Client-Response-Num',
                'client-peer'         => 'Client-Peer'
            },
            'client-date'  => 'Tue, 23 Dec 2014 20:02:11 GMT',
            'content-type' => 'application/json; charset=utf-8',
            'server'       => 'Apache/2.4.7 (Ubuntu)'
        },
        'HTTP::Headers'
    );
    $VAR5 =
      '{"id":8,"test_id":15,"status_id":1,"created_by":1,"created_on":1419364931,"assignedto_id":null,"comment":"REAPER FORCES INBOUND","version":null,"elapsed":null,"defects":null}';
    $mockObject->map_response( qr/\Q$VAR1\E/,
        HTTP::Response->new( $VAR2, $VAR3, $VAR4, $VAR5 ) );

}

{

    $VAR1 = 'index.php?/api/v2/add_result/10';
    $VAR2 = '200';
    $VAR3 = 'OK';
    $VAR4 = bless(
        {
            'connection'          => 'close',
            'x-powered-by'        => 'PHP/5.5.9-1ubuntu4.5',
            'client-response-num' => 1,
            'date'                => 'Tue, 23 Dec 2014 20:02:11 GMT',
            'client-peer'         => '192.168.122.217:80',
            'content-length'      => '174',
            '::std_case'          => {
                'client-date'         => 'Client-Date',
                'x-powered-by'        => 'X-Powered-By',
                'client-response-num' => 'Client-Response-Num',
                'client-peer'         => 'Client-Peer'
            },
            'client-date'  => 'Tue, 23 Dec 2014 20:02:11 GMT',
            'content-type' => 'application/json; charset=utf-8',
            'server'       => 'Apache/2.4.7 (Ubuntu)'
        },
        'HTTP::Headers'
    );
    $VAR5 =
      '{"id":9,"test_id":10,"status_id":1,"created_by":1,"created_on":1419364931,"assignedto_id":null,"comment":"REAPER FORCES INBOUND","version":null,"elapsed":null,"defects":null}';
    $mockObject->map_response( qr/\Q$VAR1\E/,
        HTTP::Response->new( $VAR2, $VAR3, $VAR4, $VAR5 ) );

}

{

    $VAR1 = 'index.php?/api/v2/add_result/11';
    $VAR2 = '200';
    $VAR3 = 'OK';
    $VAR4 = bless(
        {
            'connection'          => 'close',
            'x-powered-by'        => 'PHP/5.5.9-1ubuntu4.5',
            'client-response-num' => 1,
            'date'                => 'Tue, 23 Dec 2014 20:02:11 GMT',
            'client-peer'         => '192.168.122.217:80',
            'content-length'      => '174',
            '::std_case'          => {
                'client-date'         => 'Client-Date',
                'x-powered-by'        => 'X-Powered-By',
                'client-response-num' => 'Client-Response-Num',
                'client-peer'         => 'Client-Peer'
            },
            'client-date'  => 'Tue, 23 Dec 2014 20:02:11 GMT',
            'content-type' => 'application/json; charset=utf-8',
            'server'       => 'Apache/2.4.7 (Ubuntu)'
        },
        'HTTP::Headers'
    );
    $VAR5 =
      '{"id":9,"test_id":10,"status_id":1,"created_by":1,"created_on":1419364931,"assignedto_id":null,"comment":"REAPER FORCES INBOUND","version":null,"elapsed":null,"defects":null}';
    $mockObject->map_response( qr/\Q$VAR1\E/,
        HTTP::Response->new( $VAR2, $VAR3, $VAR4, $VAR5 ) );

}

{

    $VAR1 = 'index.php?/api/v2/get_results/15';
    $VAR2 = '200';
    $VAR3 = 'OK';
    $VAR4 = bless(
        {
            'connection'          => 'close',
            'x-powered-by'        => 'PHP/5.5.9-1ubuntu4.5',
            'client-response-num' => 1,
            'date'                => 'Tue, 23 Dec 2014 20:02:11 GMT',
            'client-peer'         => '192.168.122.217:80',
            'content-length'      => '176',
            '::std_case'          => {
                'client-date'         => 'Client-Date',
                'x-powered-by'        => 'X-Powered-By',
                'client-response-num' => 'Client-Response-Num',
                'client-peer'         => 'Client-Peer'
            },
            'client-date'  => 'Tue, 23 Dec 2014 20:02:11 GMT',
            'content-type' => 'application/json; charset=utf-8',
            'server'       => 'Apache/2.4.7 (Ubuntu)'
        },
        'HTTP::Headers'
    );
    $VAR5 =
      '[{"id":8,"test_id":15,"status_id":1,"created_by":1,"created_on":1419364931,"assignedto_id":null,"comment":"REAPER FORCES INBOUND","version":null,"elapsed":null,"defects":null}]';
    $mockObject->map_response( qr/\Q$VAR1\E/,
        HTTP::Response->new( $VAR2, $VAR3, $VAR4, $VAR5 ) );

}

{

    $VAR1 = 'index.php?/api/v2/delete_plan/23';
    $VAR2 = '200';
    $VAR3 = 'OK';
    $VAR4 = bless(
        {
            'connection'          => 'close',
            'x-powered-by'        => 'PHP/5.5.9-1ubuntu4.5',
            'client-response-num' => 1,
            'date'                => 'Tue, 23 Dec 2014 20:02:11 GMT',
            'client-peer'         => '192.168.122.217:80',
            'content-length'      => '0',
            '::std_case'          => {
                'client-date'         => 'Client-Date',
                'x-powered-by'        => 'X-Powered-By',
                'client-response-num' => 'Client-Response-Num',
                'client-peer'         => 'Client-Peer'
            },
            'client-date'  => 'Tue, 23 Dec 2014 20:02:11 GMT',
            'content-type' => 'application/json; charset=utf-8',
            'server'       => 'Apache/2.4.7 (Ubuntu)'
        },
        'HTTP::Headers'
    );
    $VAR5 = '';
    $mockObject->map_response( qr/\Q$VAR1\E/,
        HTTP::Response->new( $VAR2, $VAR3, $VAR4, $VAR5 ) );

}

{

    $VAR1 = 'index.php?/api/v2/delete_milestone/8';
    $VAR2 = '200';
    $VAR3 = 'OK';
    $VAR4 = bless(
        {
            'connection'          => 'close',
            'x-powered-by'        => 'PHP/5.5.9-1ubuntu4.5',
            'client-response-num' => 1,
            'date'                => 'Tue, 23 Dec 2014 20:02:11 GMT',
            'client-peer'         => '192.168.122.217:80',
            'content-length'      => '0',
            '::std_case'          => {
                'client-date'         => 'Client-Date',
                'x-powered-by'        => 'X-Powered-By',
                'client-response-num' => 'Client-Response-Num',
                'client-peer'         => 'Client-Peer'
            },
            'client-date'  => 'Tue, 23 Dec 2014 20:02:11 GMT',
            'content-type' => 'application/json; charset=utf-8',
            'server'       => 'Apache/2.4.7 (Ubuntu)'
        },
        'HTTP::Headers'
    );
    $VAR5 = '';
    $mockObject->map_response( qr/\Q$VAR1\E/,
        HTTP::Response->new( $VAR2, $VAR3, $VAR4, $VAR5 ) );

}

{

    $VAR1 = 'index.php?/api/v2/delete_run/22';
    $VAR2 = '200';
    $VAR3 = 'OK';
    $VAR4 = bless(
        {
            'connection'          => 'close',
            'x-powered-by'        => 'PHP/5.5.9-1ubuntu4.5',
            'client-response-num' => 1,
            'date'                => 'Tue, 23 Dec 2014 20:02:11 GMT',
            'client-peer'         => '192.168.122.217:80',
            'content-length'      => '0',
            '::std_case'          => {
                'client-date'         => 'Client-Date',
                'x-powered-by'        => 'X-Powered-By',
                'client-response-num' => 'Client-Response-Num',
                'client-peer'         => 'Client-Peer'
            },
            'client-date'  => 'Tue, 23 Dec 2014 20:02:11 GMT',
            'content-type' => 'application/json; charset=utf-8',
            'server'       => 'Apache/2.4.7 (Ubuntu)'
        },
        'HTTP::Headers'
    );
    $VAR5 = '';
    $mockObject->map_response( qr/\Q$VAR1\E/,
        HTTP::Response->new( $VAR2, $VAR3, $VAR4, $VAR5 ) );

}

{

    $VAR1 = 'index.php?/api/v2/delete_case/8';
    $VAR2 = '200';
    $VAR3 = 'OK';
    $VAR4 = bless(
        {
            'connection'          => 'close',
            'x-powered-by'        => 'PHP/5.5.9-1ubuntu4.5',
            'client-response-num' => 1,
            'date'                => 'Tue, 23 Dec 2014 20:02:11 GMT',
            'client-peer'         => '192.168.122.217:80',
            'content-length'      => '0',
            '::std_case'          => {
                'client-date'         => 'Client-Date',
                'x-powered-by'        => 'X-Powered-By',
                'client-response-num' => 'Client-Response-Num',
                'client-peer'         => 'Client-Peer'
            },
            'client-date'  => 'Tue, 23 Dec 2014 20:02:11 GMT',
            'content-type' => 'application/json; charset=utf-8',
            'server'       => 'Apache/2.4.7 (Ubuntu)'
        },
        'HTTP::Headers'
    );
    $VAR5 = '';
    $mockObject->map_response( qr/\Q$VAR1\E/,
        HTTP::Response->new( $VAR2, $VAR3, $VAR4, $VAR5 ) );

}

{

    $VAR1 = 'index.php?/api/v2/delete_section/9';
    $VAR2 = '200';
    $VAR3 = 'OK';
    $VAR4 = bless(
        {
            'connection'          => 'close',
            'x-powered-by'        => 'PHP/5.5.9-1ubuntu4.5',
            'client-response-num' => 1,
            'date'                => 'Tue, 23 Dec 2014 20:02:11 GMT',
            'client-peer'         => '192.168.122.217:80',
            'content-length'      => '0',
            '::std_case'          => {
                'client-date'         => 'Client-Date',
                'x-powered-by'        => 'X-Powered-By',
                'client-response-num' => 'Client-Response-Num',
                'client-peer'         => 'Client-Peer'
            },
            'client-date'  => 'Tue, 23 Dec 2014 20:02:11 GMT',
            'content-type' => 'application/json; charset=utf-8',
            'server'       => 'Apache/2.4.7 (Ubuntu)'
        },
        'HTTP::Headers'
    );
    $VAR5 = '';
    $mockObject->map_response( qr/\Q$VAR1\E/,
        HTTP::Response->new( $VAR2, $VAR3, $VAR4, $VAR5 ) );

}

{

    $VAR1 = 'index.php?/api/v2/delete_suite/9';
    $VAR2 = '200';
    $VAR3 = 'OK';
    $VAR4 = bless(
        {
            'connection'          => 'close',
            'x-powered-by'        => 'PHP/5.5.9-1ubuntu4.5',
            'client-response-num' => 1,
            'date'                => 'Tue, 23 Dec 2014 20:02:12 GMT',
            'client-peer'         => '192.168.122.217:80',
            'content-length'      => '0',
            '::std_case'          => {
                'client-date'         => 'Client-Date',
                'x-powered-by'        => 'X-Powered-By',
                'client-response-num' => 'Client-Response-Num',
                'client-peer'         => 'Client-Peer'
            },
            'client-date'  => 'Tue, 23 Dec 2014 20:02:12 GMT',
            'content-type' => 'application/json; charset=utf-8',
            'server'       => 'Apache/2.4.7 (Ubuntu)'
        },
        'HTTP::Headers'
    );
    $VAR5 = '';
    $mockObject->map_response( qr/\Q$VAR1\E/,
        HTTP::Response->new( $VAR2, $VAR3, $VAR4, $VAR5 ) );

}

{

    $VAR1 = 'index.php?/api/v2/delete_project/9';
    $VAR2 = '200';
    $VAR3 = 'OK';
    $VAR4 = bless(
        {
            'connection'          => 'close',
            'x-powered-by'        => 'PHP/5.5.9-1ubuntu4.5',
            'client-response-num' => 1,
            'date'                => 'Tue, 23 Dec 2014 20:02:12 GMT',
            'client-peer'         => '192.168.122.217:80',
            'content-length'      => '0',
            '::std_case'          => {
                'client-date'         => 'Client-Date',
                'x-powered-by'        => 'X-Powered-By',
                'client-response-num' => 'Client-Response-Num',
                'client-peer'         => 'Client-Peer'
            },
            'client-date'  => 'Tue, 23 Dec 2014 20:02:12 GMT',
            'content-type' => 'application/json; charset=utf-8',
            'server'       => 'Apache/2.4.7 (Ubuntu)'
        },
        'HTTP::Headers'
    );
    $VAR5 = '';
    $mockObject->map_response( qr/\Q$VAR1\E/,
        HTTP::Response->new( $VAR2, $VAR3, $VAR4, $VAR5 ) );

}

{

    $VAR1 = 'index.php?/api/v2/get_configs/9';
    $VAR2 = '200';
    $VAR3 = 'OK';
    $VAR4 = bless(
        {
            'connection'          => 'close',
            'x-powered-by'        => 'PHP/5.5.9-1ubuntu4.5',
            'client-response-num' => 1,
            'date'                => 'Tue, 23 Dec 2014 20:02:12 GMT',
            'client-peer'         => '192.168.122.217:80',
            'content-length'      => '0',
            '::std_case'          => {
                'client-date'         => 'Client-Date',
                'x-powered-by'        => 'X-Powered-By',
                'client-response-num' => 'Client-Response-Num',
                'client-peer'         => 'Client-Peer'
            },
            'client-date'  => 'Tue, 23 Dec 2014 20:02:12 GMT',
            'content-type' => 'application/json; charset=utf-8',
            'server'       => 'Apache/2.4.7 (Ubuntu)'
        },
        'HTTP::Headers'
    );
    $VAR5 = '[]';
    $mockObject->map_response( qr/\Q$VAR1\E/,
        HTTP::Response->new( $VAR2, $VAR3, $VAR4, $VAR5 ) );

}

{

    $VAR1 = 'index.php?/api/v2/get_configs/10';
    $VAR2 = '200';
    $VAR3 = 'OK';
    $VAR4 = bless(
        {
            'connection'          => 'close',
            'x-powered-by'        => 'PHP/5.5.9-1ubuntu4.5',
            'client-response-num' => 1,
            'date'                => 'Tue, 23 Dec 2014 20:02:12 GMT',
            'client-peer'         => '192.168.122.217:80',
            'content-length'      => '0',
            '::std_case'          => {
                'client-date'         => 'Client-Date',
                'x-powered-by'        => 'X-Powered-By',
                'client-response-num' => 'Client-Response-Num',
                'client-peer'         => 'Client-Peer'
            },
            'client-date'  => 'Tue, 23 Dec 2014 20:02:12 GMT',
            'content-type' => 'application/json; charset=utf-8',
            'server'       => 'Apache/2.4.7 (Ubuntu)'
        },
        'HTTP::Headers'
    );
    $VAR5 = '["testConfig"]';
    $mockObject->map_response( qr/\Q$VAR1\E/,
        HTTP::Response->new( $VAR2, $VAR3, $VAR4, $VAR5 ) );

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::LWP::UserAgent::TestRailMock - Provides an interface to something like TestRail's REST api in a bogus fashion

=head1 VERSION

version 0.015

=head1 SYNOPSIS

    use Test::LWP::UserAgent::TestRailMock;
    use TestRail::API;
    my $tr = TestRail::API->new('http://testrail.local','teodesian@cpan.org','bogus',0);
    $tr->{'browser'} = $Test::LWP::UserAgent::TestRailMock::mockObject;

=head1 DESCRIPTION

Provides a Test::LWP::UserAgent with mappings defined for all the requests made by this module's main test.
More or less provides a successful response with bogus data for every API call exposed by TestRail::API.
Used primarily by said module's tests (whenever the test environment does not provide a TestRail server to test against).

You probably won't need/want to use it, but you can by following the SYNOPSIS.

The module was mostly auto-generated, with a few manual tweaks.

=head1 AUTHOR

George S. Baugh <teodesian@cpan.org>

=head1 SOURCE

The development version is on github at L<http://github.com/teodesian/TestRail-Perl>
and may be cloned from L<git://github.com/teodesian/TestRail-Perl.git>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by George S. Baugh.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
