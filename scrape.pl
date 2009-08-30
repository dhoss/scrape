#!/usr/bin/env perl
use warnings;
use strict;
use Web::Scraper;
use URI;
use Data::Dumper;

my $want = scraper {
    process "div.listingName", "contractors[]" => scraper { 
        process ".omnitureListingNameLink",   name    => 'TEXT';
        process ".gold",                   address => scraper {
            process ".address", addy => 'TEXT'; # need to split this up into address, state, postcode,
        };
        process ".phoneNumber",               phone   => 'TEXT';
        process ".links",                     website => 'TEXT';        
    };
};

my $names = $want->scrape( 
    URI->new("http://yellowpages.com.au/search/postSearchEntry.do?clueType=0&clue=electrical+contractors&locationClue=All+States&x=0&y=0") 
);

print Dumper($names);
#for my $name (%{$names}) {
#    print "Name: $name->{a_span}\n";
#}
