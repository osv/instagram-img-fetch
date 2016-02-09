#!/usr/bin/perl -w

=head1 NAME

inst_spy.pl - Instagram image fetcher

=head1 SYNOPSIS

  inst_spy.pl [ --help | --manual] [options] --output DIR

  Help Options:
   --help      Show this scripts help information.
   --manual    Read this scripts manual.
   --output    Where to download img/ and maria.json data file
   --wordpress Url to site that contains instagram urls
   --email     Email for notify. You should set mandrill api key in env MANDRILL then
   --from      email from, default noreply@nowhere.com

  Example:

  export MANDRILL=1234567890
  ./inst_spy.pl --word https://downtownie.wordpress.com \
                --out  ~/spy/ \
                --email olexandr.syd@gmail.com




=cut

=head1 OPTIONS

=over 8

=item B<--help>

Show the brief help information.

=item B<--manual>

Read the manual.

=item B<--output>

This script build maria.json - data about all images fetched before.
And download images into "img" subdir of B<--output> dir.
All instagram images from url set by B<--wordpress> will be appended to maria.json.

=item B<--wordpress>

Url to scan. Why switcher is called wordpress? Because it used to scan wordpress page.

=back

=head1 DESCRIPTION

Scan site for instagram images, download them, save meta into maria.json.

=head1 Why?

Some instagram accounts are hidden. But someone may be used in wordpress plugin,
to share some latest images.
I have no instagram account, but want to be notified about new picture :).
So this script fetch them and send to my email notify.

=head1 AUTHOR


 Olexandr Sydorchuk
 --
 http://github.com/osv/

=cut

use utf8;

use warnings;
use strict;

use Getopt::Long;
use Pod::Usage;
use File::Path qw(make_path);
use File::Spec;
use File::Slurp qw(read_file write_file);
use JSON::XS;
use LWP::Simple;
use Data::Dumper;
use File::Basename;
use WebService::Mandrill;

# prevent Wide character warning
binmode( STDOUT, ':utf8' );

use constant JSON_FNAME => 'maria.json';
use constant IMG_DIR    => 'img';
use constant MARIA_URL  => 'https://downtownie.wordpress.com/';

# ------------------------------------------------------
# commandline options
my $HELP   = 0;
my $MANUAL = 0;
my $NOTIFY_EMAIL;
my $FROM_EMAIL = 'noreply@nowhere.com';
my $OUTPUT_DIR;
my $WORDPRESS_URL;

GetOptions(
    "help"        => \$HELP,
    "manual"      => \$MANUAL,
    "output=s"    => \$OUTPUT_DIR,
    "wordpress=s" => \$WORDPRESS_URL,
    "email=s"     => \$NOTIFY_EMAIL,
    "from=s"      => \$FROM_EMAIL,
);

$WORDPRESS_URL |= MARIA_URL;    # default is my ex-gf :)

# ------------------------------------------------------

pod2usage( -verbose => 2 ) && exit if $MANUAL || !defined $OUTPUT_DIR;
pod2usage(1) && exit if $HELP;

my $mandrill_api_key;
if ( defined $NOTIFY_EMAIL ) {
    $mandrill_api_key = $ENV{MANDRILL}
      or die
qq(You should setup mandrill by setting env MANDRILL if you want email notify);
}

my $json_filename = File::Spec->catfile( $OUTPUT_DIR, JSON_FNAME );
my $img_dir       = File::Spec->catfile( $OUTPUT_DIR, IMG_DIR );

make_path $img_dir;

main: {
    my $data = {};

    # read json
    if ( -f $json_filename ) {
        $data = read_json($json_filename);
    }

    my $html    = get $WORDPRESS_URL or die qq(Cant fetch $WORDPRESS_URL);
    my $urls    = getImages($html);
    my @updates = appendUrls( $data, $urls );

    link_index_html($OUTPUT_DIR);

    if (@updates) {
        fetchImages(@updates);

        # set update timestamp and save
        $data->{lastUpdate} = time() * 1000;
        save_json( $json_filename, $data );
        compose_mail(
            {
                api_key  => $mandrill_api_key,
                from     => $FROM_EMAIL,
                to       => $NOTIFY_EMAIL,
                resource => $WORDPRESS_URL,
                updates  => [@updates]
            }
        ) if defined $NOTIFY_EMAIL;
    }
}

# Create symlink to index.html and vendor files in output dir
sub link_index_html {
    my $dir = shift;
    my $cd  = dirname($0);

    foreach my $file (qw(index.html vendor)) {
        my $src = File::Spec->catfile( $cd, 'web', $file );
        my $dst = File::Spec->catfile( $dir, $file );

        $src = File::Spec->rel2abs($src);
        $dst = File::Spec->rel2abs($dst);

        if ( !-e $dst ) {
            symlink( $src, $dst );
        }
    }
}

sub save_json {
    my ( $json_filename, $data ) = @_;

    $data = uniq_by_file($data);

    my $json = JSON::XS->new->pretty(1)->encode($data);

    write_file( $json_filename, { binmode => ':utf8' }, $json );
}

sub uniq_by_file {
    my $data = shift;

    my @sorted = sort { $b->{time} <=> $a->{time} } @{ $data->{urls} };

    my %seen;
    my @result;

    foreach my $item (@sorted) {
        next if $seen{ $item->{l} };
        $seen{ $item->{l} } = 1;

        push @result, $item;
    }

    $data->{urls} = \@result;

    return $data;
}

sub read_json {
    my $json_filename = shift;
    my $json = read_file $json_filename, { binmode => ':utf8' };
    return JSON::XS->new->decode($json);
}

sub fetchImages {
    my @updates = @_;

    foreach my $needFetch (@updates) {
        my $url = $needFetch->{img};

        for my $retry ( 1 .. 3 ) {
            my $content = get $url;

            if ( defined $content ) {
                print "Ok $url\n";
                my $filename = basename $url;
                $filename =~s/\?.*//g;
                my $filepath = File::Spec->catfile( $img_dir, $filename );
                write_file( $filepath, $content );
                last;
            }
            else {
                print "Fail fetch $url\n";
                print "Retry $retry\n";
            }
        }
    }
}

sub getImages {
    my $content = shift;
    my @result;

    while (
        $content =~ m |
                          <a\s+href="([^"]+?instagram[^"]+)">
                          (.*?)
                          </a>
                      |xgsim
      )
    {
        my ( $instagramUrl, $a_body ) = ( $1, $2 );

        if ( $a_body =~ m/<img[^>]+src="([^"]+)"/ ) {
            my $url      = $1;
            my $filename = basename($url);
            $filename =~s/\?.*//g;
            my $loc_img  = File::Spec->catfile( IMG_DIR, $filename );
            my ($title)  = $a_body =~ m|title="([^"]+)"|;
            $title |= '';

            push @result,
              {
                img   => $url,
                title => $title,
                inst  => $instagramUrl,
                l     => $loc_img,
              };
        }
    }

    @result = reverse @result;
    return \@result;
}

# Append to property [urls] of $json where urls is obj of {'img', 'title', 'inst'}
# but only new one.
sub appendUrls {
    my ( $json, $instagramsImg ) = @_;
    my $jsonUrls = \$json->{urls} || [];
    my $now = time * 1000;
    my @toAppend;

    my %urls;
    foreach my $u ( @{$$jsonUrls} ) {
        my $url = basename($u->{img});
        $urls{$url} = 1;
    }

    foreach my $masha ( @{$instagramsImg} ) {
        my $photoUrl = basename($masha->{img});
        next if ( exists $urls{$photoUrl} );

        # add timestamp to this
        $masha->{time} = $now;
        push @toAppend, $masha;
    }

    push @{$$jsonUrls}, @toAppend;

    return @toAppend;
}

sub compose_mail {
    my $opt        = shift;
    my $mandrill   = WebService::Mandrill->new( api_key => $opt->{api_key}, );
    my @updates    = @{ $opt->{updates} };
    my $updatesNum = scalar @updates;
    my $resource   = $opt->{resource};

    my $updatesText = join(
        "\n",
        map {
            <<HTML
<p>
  <b>$_->{title}</b><br/>
  <a href="$_->{inst}">
    <img src="$_->{img}" height="640" width="640">
  </a>
</p>
HTML
              ;
        } @updates
    );

    my $html = <<MSG
Hello,<br/>

<p>I found new instagram images in <a href="$resource">$resource<a/>:</p>

$updatesText
MSG
      ;

    my $response = $mandrill->send(
        subject      => qq($updatesNum Instagram Updates from "$resource"),
        from_email   => $opt->{from},
        html         => $html,
        track_opens  => 1,
        track_clicks => 1,
        to           => [
            {
                email => $opt->{to}
            }
        ],
    );

}
