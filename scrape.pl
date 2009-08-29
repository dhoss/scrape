#!/usr/bin/env perl
use warnings;
use strict;
use Web::Scraper;
use URI;
use Data::Dumper;

my $want = scraper {
    process "a.omnitureListingNameLink", "names[]" => { name => "TEXT" }
};

my $names = $want->scrape( 
    URI->new("http://yellowpages.com.au/search/postSearchEntry.do?clueType=0&clue=electrical+contractors&locationClue=All+States&x=0&y=0") 
);

print Dumper($names);
#for my $name (%{$names}) {
#    print "Name: $name->{a_span}\n";
#}
