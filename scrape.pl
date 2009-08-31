#!/usr/bin/env perl
use warnings;
use strict;
use Web::Scraper;
use URI;
use YAML qw/ Dump /;
use WWW::Mechanize;
use URI::Query;
use URI::Escape;
use IO::File;
use Smart::Comments;

my $yaml;
my $base_url = "http://yellowpages.com.au/search/postSearchEntry.do?clueType=0&clue=electrical+contractors&locationClue=All+States&x=0&y=0";
my $mech = WWW::Mechanize->new;
### mech object initiated
$mech->get( $base_url );
### got our url
my $names;
my @information;
### Entering link following loop
 
while ( $mech->follow_link( text_regex => qr/^next$/i) ) {
    ### Beginning scrape inside loop
   
     my $want = scraper {
        process "li.gold", "contractors[]" => scraper { 
            process ".omnitureListingNameLink",   name    => 'TEXT';
            process ".address", address => 'TEXT'; # need to split this up into address, state, postcode,
            process ".phoneNumber",               phone   => 'TEXT';
            process ".links",                     website => '@href';        
        };
    };
 
    my $ua = $want->user_agent;
    ### Before scrape is called
    $names = $want->scrape( 
        URI->new($base_url) 
    );
 
    my $site = $names->{contractors}[3]->{website};
    ### Site is: $site
   
    my $true_url      = URI->new($site);
    my $query = URI::Query->new($true_url->query);
    my $site_from_query = uri_unescape($query->hash_arrayref->{webSite}->[0]); 
    push @information, { contractor => $names, real_website => $site_from_query };
    
    ### Saving page info...
    ### Scrape successful
    ### Serializing -> YAML
    ### Dumping info
    print Dump(@information);
    $| = 1;   
    my $fh = IO::File->new;
    # dump our YAML to a file    
    my $file_name = $names->{contractors}[0]->{name};
    $file_name    = lc $file_name;
    $file_name    =~ s/\s/_/g;
    if ( $fh->open("> $file_name.yaml") ) {
        print $fh Dump(@information);
    }
    $fh->close;

    # dump the entire page
    if ( $fh->open("> $file_name.html") ) {
        print $fh $mech->content;
    }
    $fh->close;
    undef $fh;

    ### Page: $base_url
    ### Sleep for a bit
    sleep(1);
}
 
### All done!
