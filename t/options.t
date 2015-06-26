use strict;
use warnings;
use Test::More 0.88;
use File::Spec::Functions qw( catfile ); # core
use Test::Warnings ':all';

use App::Software::License;

my $holder = 'A.Holder';
my $year = (localtime)[5] + 1900;

sub test_opts {
    my ($argv, $re, $desc) = @_;
    local @ARGV = @$argv;
    my $holder = 'A.Holder';
    like(
        App::Software::License->new_with_options->_software_license->notice,
        $re,
        $desc,
    );
}

my @warnings =
grep { !/Specified configfile '.*' does not exist, is empty, or is not readable/s }
warnings {

test_opts(
    [qw( --holder=A.Holder --license=BSD )],
    qr/^\QThis software is Copyright (c) $year by $holder.\E/,
    'basic args',
);

test_opts(
    [qw( --holder=A.Holder BSD )],
    qr/^\QThis software is Copyright (c) $year by $holder.\E/,
    'license as last (non-option) argument',
);

test_opts(
    [qw( --year=2000 --holder=A.Holder BSD )],
    qr/^\QThis software is Copyright (c) 2000 by $holder.\E/,
    'specify year',
);

};

warn @warnings if @warnings;

done_testing;
