use ExtUtils::MakeMaker;
use strict;
use warnings;

WriteMakefile(
    'NAME'         => 'Plack::Middleware::AllowCrossSiteAJAX',
    'VERSION_FROM' => 'lib/Plack/Middleware/AllowCrossSiteAJAX.pm',
    'PREREQ_PM'    => {
        'Plack'      => '0.9901',
        'Test::More' => '0',
    }
);

