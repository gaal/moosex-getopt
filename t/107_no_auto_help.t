# Related information:
# https://rt.cpan.org/Public/Bug/Display.html?id=47865
# https://rt.cpan.org/Public/Bug/Display.html?id=52474
# https://rt.cpan.org/Public/Bug/Display.html?id=57683
# http://www.nntp.perl.org/group/perl.moose/2010/06/msg1767.html

# Summary: If we disable the "auto_help" option in Getopt::Long, then
# getoptions() will not call into pod2usage() (causing program termination)
# when --help is passed (and MooseX::ConfigFromFile is in use).
use strict;
use warnings;

use Test::More;

use Test::Requires {
    'MooseX::SimpleConfig' => 0.07, # skip all if not installed
};

my $fail_on_exit = 1;
{
    package Class;
    use strict; use warnings;

    use Moose;
    with
        'MooseX::SimpleConfig',
        'MooseX::Getopt';

    # this is a hacky way of being able to check that we made it past the
    # $opt_parser->getoptions() call in new_with_options, because it is
    # still going to bail out later on, on seeing the --help flag
    has configfile => (
        is => 'ro', isa => 'Str',
        default => sub {
            $fail_on_exit = 0;
            'this_value_unimportant',
        },
    );

    no Moose;
    1;
}

use Test::Warn 0.21;
use Test::Fatal;

END {
    ok(!$fail_on_exit, 'getoptions() lives');

    done_testing;

    # cancel the non-zero exit status from _getopt_full_usage()
    exit 0;
}


@ARGV = ('--help');

warning_like {
    like exception { Class->new_with_options },
           #usage: 107_no_auto_help.t [-?] [long options...]
        qr/^usage: [\d\w]+\Q.t [-?] [long options...]\E.\s+\Q-? --usage --help  Prints this usage information.\E.\s+--configfile/ms,
        'usage information looks good';
    }
    qr/^Specified configfile \'this_value_unimportant\' does not exist, is empty, or is not readable$/,
    'Our dummy config file doesn\'t exist';

