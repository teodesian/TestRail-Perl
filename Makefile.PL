use 5.010; #Perl 5.10 minimum due to usage of undef or (//)
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => "TestRail::API",
    VERSION_FROM      => "lib/TestRail/API.pm",
    MIN_PERL_VERSION  => '5.010',
    TEST_REQUIRES     => {
        "Test::More"          => 0,
        "Scalar::Util"        => 0,
        "Prompt::Timeout"     => 0,
        "Test::Pod"           => 0,
        "Test::Pod::Coverage" => 0
    },
    PREREQ_PM => {
        "Carp"                => 0,
        "Scalar::Util"        => 0,
        "Data::Validate::URI" => 0,
        "Clone"               => 0,
        "Try::Tiny"           => 0,
        "JSON::XS"            => 0,
        "HTTP::Request"       => 0,
        "LWP::UserAgent"      => 0,
        "Types::Serialiser"   => 0
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        abstract    => "Provides an interface to TestRail's REST api via HTTP",
        author      => ['George S. Baugh <teodesian@cpan.org>'],
        resources   => {
             repository => {
                 type => 'git',
                 url  => 'https://github.com/teodesian/TestRail-Perl.git',
                 web  => 'https://github.com/teodesian/TestRail-Perl',
             },
        },
        license => ['artistic_2'],
        prereqs => {
            runtime => {
                requires => {
                    'perl'                => '5.010',
                    "Carp"                => 0,
                    "Scalar::Util"        => 0,
                    "Data::Validate::URI" => 0,
                    "Clone"               => 0,
                    "Try::Tiny"           => 0,
                    "JSON::XS"            => 0,
                    "HTTP::Request"       => 0,
                    "LWP::UserAgent"      => 0,
                    "Types::Serialiser"   => 0
                }
            },
            test => {
                requires => {
                    "Test::More"          => 0,
                    "Scalar::Util"        => 0,
                    "Prompt::Timeout"     => 0,
                    "Test::Pod"           => 0,
                    "Test::Pod::Coverage" => 0
                },
            }
        },
        provides => {
            'TestRail::API' => {
                file    => 'lib/TestRail/API.pm',
                version => '0.010'
            }
        }
    }
);
