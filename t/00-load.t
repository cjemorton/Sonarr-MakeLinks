#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Sonarr::MakeLinks' ) || print "Bail out!\n";
}

diag( "Testing Sonarr::MakeLinks $Sonarr::MakeLinks::VERSION, Perl $], $^X" );
