package File::CachedURL;
use strict;
use warnings;

use Moo::Role;
use File::Spec::Functions qw(tmpdir catfile);
use HTTP::Tiny;
use HTTP::Date;

has 'uri' =>
    (
     is         => 'rw',
    );

has 'cachedir' =>
    (
     is         => 'rw',
     default    => sub {
                       my $dirpath = tmpdir() || die "can't get temp directory: $!\n";
                       my $dirname = __PACKAGE__;
                       $dirname =~ s/::/-/g;
                       my $dir = catfile($dirpath, $dirname);
                       if (! -d $dir) {
                           mkdir($dir, 0755)
                           || die "can't create cache directory $dir: $!\n";
                       }
                       return $dir;
                   },
    );

has 'basename' =>
    (
        is      => 'rw',
    );

has 'filename' =>
    (
     is         => 'rw',
    );

has '_path' =>
    (
     is         => 'rw',
     init_arg   => undef,
    );

sub BUILD
{
    my $self = shift;

    if ($self->filename) {
        if (!-f $self->filename) {
            die "specified file (", $self->filename, ") not found\n";
        }
        $self->_path($self->filename);
    } else {
        $self->_get_uri();
    }
}

sub _get_uri
{
    my $self    = shift;
    my $ua      = HTTP::Tiny->new() || die "failed to create HTTP::Tiny: $!\n";
    my $options = {};

    $self->_path(catfile($self->cachedir, $self->basename));

    # If we've already got a local copy of the file,
    # then only get the remote file again if it's changed since we got it
    if (-f $self->_path) {
        $options->{'If-Modified-Since'} = time2str( (stat($self->_path))[9]);
    }

    if (not $ua->mirror($self->uri, $self->_path, $options)) {
        die "failed to mirror file\n";
    }
}

1;
