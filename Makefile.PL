use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME      => 'Yancha::Twitter::Bot',
    PREREQ_PM => {
        'HTTP::Request'             => '6.00',
        'AnyEvent::Twitter::Stream' => '0.22',
        'AnyEvent::HTTP::Request'   => '0.301',
        'URI::Escape'               => '3.31',
        'Encode'                    => '2.49',
        'FindBin'                   => 0,
    },
    MIN_PERL_VERSION => '5.010001',
);
