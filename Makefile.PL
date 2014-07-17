use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => "TestRail::API",
    VERSION_FROM      => "lib/TestRail/API.pm",
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
