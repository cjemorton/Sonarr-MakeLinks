package Sonarr::MakeLinks;

use 5.006;
use strict;
use warnings;
use LWP::UserAgent;
use JSON::PP;
use File::Path;

=head1 NAME

Sonarr::MakeLinks - Make hard links using Sonarr api for tv shows. (Continuing, Ended, Incomplete)

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

This module uses the Sonarr api to create hard links of all shows in its database. 

It sorts these shows into three categories.

Continuing - These are shows that are currently airing.
Ended - Shows that are no longer producing new episodes. - All episodes are available on disk.
Incomplete - Shows that are no longer producing new episodes. - The local disk is missing episodes.

Media servers such as Plex then are able to point a library at each of the folders.

This has several benifits and effects.
- Hard links take up little to no additional file space.
- All media for sonarr can be kept in a single ARCHIVE directory.
- Browsing the Continuing library on plex shows currently running shows.
- Browsing the Ended library on plex shows old shows that are complete and archived on disk. 
-- (Binge watching with no missing episodes from the series.)
- Browsing the Incomplete library on plex easilly identifies shows that are old and ended, yet not all episodes are available.
-- (Binge watching incomplete means there may be missing episodes as reported by sonarr.)

-- NOTE: TARGET_DIR must be on the same filesystem as media collection. This is due to the nature of hardlinks.
-- NOTE: To read more about hard links please type 'man ln' at a shell.
-- NOTE: This script assumes that ALL media being tracked by sonarr is in a single folder on a single filesystem.

    use Sonarr::MakeLinks::run_api_call("SONARR_APIKEY", "SONARR_IP", "SONARR_PORT", "TARGET_DIR");

=head1 SUBROUTINES/METHODS

=head2 sonarr

=cut

sub run_api_call {

#####################################################################################################
# SET VALUES FOR YOUR ENVIRONMENT.
#####################################################################################################
my $s_useage = 'USEAGE: perl Sonarr::MakeLinks::run_api_call("SONARR_APIKEY", "SONARR_IP", "SONARR_PORT", "TARGET_DIR");';
my ($s_apikey, $s_ip, $s_port, $plex_ln_dir) = @_;

# DEBUG: Uncomment to print what paramaters are being passed to function.
#print "$s_apikey\n $s_ip\n $s_port\n $plex_ln_dir\n";


## TO DO: Validate input from ARGV.

if (not defined $s_apikey) {
	print "$s_useage\n";
	die "USEAGE: Missing server API KEY.\n";
}
if (not defined $s_ip) {
	print "$s_useage\n";
        die "USEAGE: Missing server IP.\n";
}
if (not defined $s_port) {
	print "$s_useage\n";
        die "USEAGE: Missing server port.\n";
}
if (not defined $plex_ln_dir) {
	print "$s_useage\n";
        die "USEAGE: Missing target link dir.\n";
}

####################################################################################################
my $dir_ended = "$plex_ln_dir/ended";
my $dir_continuing = "$plex_ln_dir/continuing";
my $dir_incomplete = "$plex_ln_dir/incomplete";

#####################################################################################################
## Query Sonarr and retrieve all series from the series endpoint.
#####################################################################################################

my $ua = LWP::UserAgent->new;
my $json = JSON::PP->new;

my $server_endpoint = "http://$s_ip:$s_port/api/v3/series?apikey=$s_apikey";
#DEBUG: Print server endpoint.
#print "$server_endpoint\n";


# set custom HTTP request header fields
my $req = HTTP::Request->new(GET => $server_endpoint);
$req->header('content-type' => 'application/json');

my $resp = $ua->request($req);
if ($resp->is_success) {
	my $data = $json->decode($resp->decoded_content);

################################################################################################
# Symbolic link creation logic.
################################################################################################
foreach my $item(@$data) {
	if ($item->{'status'} eq 'continuing'){
		# Series is continuing
		if(-e "$dir_incomplete/$item->{titleSlug}"){
			rmtree("$dir_incomplete/$item->{'titleSlug'}");
		}
		if(-e "$dir_ended/$item->{titleSlug}"){
			rmtree("$dir_ended/$item->{'titleSlug'}");
		}
		if(-e "$dir_continuing/$item->{titleSlug}"){
			# Exit Happy, link exists.
                } else {
			symlink("$item->{'path'}", "$dir_continuing/$item->{titleSlug}");
		}                 
	}
	elsif ($item->{'status'} eq 'ended'){
		# Series has ended
		if ($item->{'episodeFileCount'} lt $item->{'episodeCount'}){
			# Series is incomplete
			if(-e "$dir_ended/$item->{titleSlug}"){
				rmtree("$dir_ended/$item->{'titleSlug'}");
			}
			if(-e "$dir_continuing/$item->{titleSlug}"){
				rmtree("$dir_continuing/$item->{'titleSlug'}");
			}
			if(-e "$dir_incomplete/$item->{titleSlug}"){
                		# Exit Happy, link exists.
			} else {
                        	symlink("$item->{'path'}", "$dir_incomplete/$item->{titleSlug}");
			}			
		}
		if ($item->{'episodeFileCount'} eq $item->{'episodeCount'}){
			# Series is complete
			if(-e "$dir_incomplete/$item->{titleSlug}"){
                                rmtree("$dir_incomplete/$item->{'titleSlug'}");
                        }
                        if(-e "$dir_continuing/$item->{titleSlug}"){
                                rmtree("$dir_continuing/$item->{'titleSlug'}");
                        }
                        if(-e "$dir_ended/$item->{titleSlug}"){
                                # Exit Happy, link exists.
                        } else {
                                symlink("$item->{'path'}", "$dir_ended/$item->{titleSlug}");
                        }
		}	
	}
}
################################################################################################
}
else {
    print "HTTP GET error code: ", $resp->code, "\n";
    print "HTTP GET error message: ", $resp->message, "\n";
}

#DEBUG: Print Completion statement.
#print "Function Finished\n";
}
=head1 AUTHOR

Clem Morton, C<< <clem at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-sonarr-makelinks at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Sonarr-MakeLinks>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Sonarr::MakeLinks


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Sonarr-MakeLinks>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Sonarr-MakeLinks>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Sonarr-MakeLinks>

=item * Search CPAN

L<https://metacpan.org/release/Sonarr-MakeLinks>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT


The MIT License (MIT)

This software is Copyright (c) 2019 by Clem Morton.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


=cut

1; # End of Sonarr::MakeLinks
