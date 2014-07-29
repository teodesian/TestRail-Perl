use 5.010; #Perl 5.10 minimum due to usage of undef or (//)
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => "TestRail::API",
    VERSION_FROM      => "lib/TestRail/API.pm",
    MIN_PERL_VERSION  => '5.010',
    TEST_REQUIRES     => {
        "Test::More"      => 0,
        "Scalar::Util"    => 0,
        "Prompt::Timeout" => 0
    },
    PREREQ_PM => {
        "Carp"                => 0,
        "Scalar::Util"        => 0,
        "Data::Validate::URI" => 0,
        "Clone"               => 0,
        "Try::Tiny"           => 0,
        "JSON::XS"            => 0,
        "HTTP::Request"       => 0,
        "LWP::UserAgent"      => 0
    }
);
