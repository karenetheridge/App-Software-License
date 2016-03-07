package App::Software::License;
# ABSTRACT: Command-line interface to Software::License
# KEYWORDS: license licence LICENSE generate distribution build tool

our $VERSION = '0.08';

use Moo;
use MooX::Options;
use File::HomeDir;
use File::Spec::Functions qw/catfile/;
use Module::Runtime qw/use_module/;
use Software::License;
use Config::Any;

use namespace::autoclean 0.16 -except => [qw/_options_data _options_config/];

=head1 SYNOPSIS

    software-license --holder 'J. Random Hacker' --license Perl_5 --type notice

=head1 DESCRIPTION

This module provides a command-line interface to Software::License. It can be
used to easily produce license notices to be included in other documents.

All the attributes documented below are available as command-line options
through L<MooX::Options> and can also be configured in
F<$HOME/.software_license.conf> through L<Config::Any>.

=cut

=attr holder

Name of the license holder.

=cut

option holder => (
    is       => 'ro',
    required => 1,
    format   => 's',
    doc => '',
);

=attr year

Year to be used in the copyright notice.

=cut

option year => (
    is     => 'ro',
    format => 'i',
    doc => '',
);

=attr license

Name of the license to use. Must be the name of a module available under the
Software::License:: namespace. Defaults to Perl_5.

=cut

option license => (
    is      => 'ro',
    default => 'Perl_5',
    format  => 's',
    doc => '',
);

=attr type

The type of license notice you'd like to generate. Available values are:

B<* notice>

This method returns a snippet of text, usually a few lines, indicating the
copyright holder and year of copyright, as well as an indication of the license
under which the software is distributed.

B<* license>

This method returns the full text of the license.

=for :stopwords fulltext

B<* fulltext>

This method returns the complete text of the license, preceded by the copyright
notice.

B<* version>

=for :stopwords versioned

This method returns the version of the license.  If the license is not
versioned, this returns nothing.

B<* meta_yml_name>

This method returns the string that should be used for this license in the CPAN
META.yml file, or nothing if there is no known string to use.

=for Pod::Coverage run

=for Pod::Coverage BUILDARGS

=cut

option type => (
    is      => 'ro',
    default => 'notice',
    format => 's',
    doc => '',
);

=attr configfile

Path to the optional configuration file. Defaults to C<$HOME/.software_license.conf>.

=cut

option configfile => (
    is => 'ro',
    default => catfile(File::HomeDir->my_home, '.software_license.conf'),
    format => 's',
    doc => '',
    order => 100,
);

has _software_license => (
    is      => 'ro',
    isa     => sub { die "Not a Software::License" if !$_[0]->isa('Software::License') },
    lazy    => 1,
    builder => '_build__software_license',
    handles => {
        notice   => 'notice',
        text     => 'license',
        fulltext => 'fulltext',
        version  => 'version',
    },
);

sub _build__software_license {
    my ($self) = @_;
    my $class = "Software::License::${\$self->license}";

    return use_module($class)->new({
        holder => $self->holder,
        year   => $self->year,
    });
}

sub BUILDARGS {
    my $class = shift;

    my $args = { @_ };
    my $configfile = $args->{configfile} || catfile(File::HomeDir->my_home, '.software_license.conf');

    # Handling license as a trailing non-option argument
    if (!exists $args->{license}
            && scalar @ARGV && $ARGV[-1] !~ m{^--.+=.+}
            && (!scalar (@_) || $ARGV[-1] ne $_[-1])
    ) {
        $args->{license} = $ARGV[-1];
    }

    if (-e $configfile) {
        my $conf = Config::Any->load_files({ files => [$configfile], use_ext => 1, flatten_to_hash => 1 })->{ $configfile };
        $args = { %{ $conf || {} }, %$args };
    }
    return $args;
}

sub run {
    my ($self) = @_;
    my $meth = $self->type;
    print $self->_software_license->$meth;
}

1;
