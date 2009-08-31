#!/usr/bin/env perl
use warnings;
use strict;
use Web::Scraper;
use URI;
use YAML qw/ Dump /;
use WWW::Mechanize;

my $yaml;
my $base_url = "http://yellowpages.com.au/search/postSearchEntry.do?clueType=0&clue=electrical+contractors&locationClue=All+States&x=0&y=0";
my $mech = WWW::Mechanize->new;
print "mech object initiated\n";
$mech->get( $base_url );
print "got our url\n";
my $names;
my @information;
print "Entering link following loop\n";

while ( $mech->follow_link( text => "Next" ) ) {
    print "Beginning scrape inside loop\n";
   
     my $want = scraper {
        process "li.gold", "contractors[]" => scraper { 
            process ".omnitureListingNameLink",   name    => 'TEXT';
            process ".address", address => 'TEXT'; # need to split this up into address, state, postcode,
            process ".phoneNumber",               phone   => 'TEXT';
            process ".links",                     website => 'TEXT';        
        };
    };

    print "Before scrape is called\n";
    $names = $want->scrape( 
        URI->new($base_url) 
    );
    
    push @information, { contractor => $names };
    
    print "Saving page info...\n";
    print "Scrape successful\n";
    print "Serializing -> YAML\n";
    print "Dumping info:\n";
    print Dump(@information);
    warn "Page: $base_url\n";
    print "Sleep for a bit\n";
    sleep(1);
}

print "All done!\n";
