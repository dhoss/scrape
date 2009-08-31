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

my @data;  # what we get out at the end

#my $redirect_url = WWW::Mechanize->new;
my $yaml;
 my $base_url = "http://yellowpages.com.au/search/postSearchEntry.do?clueType=0&clue=electrical+contractors&locationClue=All+States&x=0&y=0";
# my $base_url = "http://yellowpages.com.au/search/listingsSearch.do?region=australia&showAllLocations=3473402&headingCode=22683&sortByDetail=true&sortByAlphabetical=false&businessType=Electrical+contractors&sortByClosestMatch=false&iblId=3473402&iblName=&rankWithTolls=true&sortBy=mostInfo&sortByDistance=false&stateId=9&familyId=3473402&safeLocationClue=All+States&pageNumber=1000&currentLetter=&locationClue=All+States&lruPageNumber=1&serviceArea=true&locationText=All+States";

# my $base_url =  'http://yellowpages.com.au/search/listingsSearch.do?region=australia&ul.street=&headingCode=22683&sortByAlphabetical=true&rankType=1&webLink=false&userState=select+---%3E&sortByDistance=false&locationForSortBySelected=false&locationText=All+States&adPs=&adPs=&adPs=&adPs=&adPs=&ul.streetNumber=&sortByDetail=false&ul.suburb=&businessType=Electrical+contractors&sortByClosestMatch=false&sortBy=alpha&rankWithTolls=true&stateId=9&safeLocationClue=All+States&__HERE__&locationClue=All+States&serviceArea=true&suburbPostcode=#__THERE__';

my $mech = WWW::Mechanize->new;
$mech->agent_alias( 'Windows IE 6' ); # just in case ;)
my $names;
my @information;

my @letters = ("a" .. "z", 0);
my $page = 1;
foreach my $l (@letters) {
    my $url = $base_url;
    $url =~ s/__HERE__/currentLetter=$l/;
    $url =~ s/__THERE__/$l/;
    while ( $mech->get($url) ) {
        warn "letter: $l page: " . $page++. "\n";
        # we have entry classes of gold, free and almostFree
        my $want_gold = scraper {
            process "li.gold", "contractors[]" => scraper { 
                process ".omnitureListingNameLink",   name    => 'TEXT';
                process ".address", address => 'TEXT'; # need to split this up into address, state, postcode,
                process ".phoneNumber",               phone   => 'TEXT';
                process ".links",                     website => '@href';        
            },
        };

        my $want_free = scraper {
            process "li.free", "contractors[]" => scraper { 
                process ".omnitureListingNameLink",   name    => 'TEXT';
                process ".address", address => 'TEXT'; # need to split this up into address, state, postcode,
                process ".phoneNumber",               phone   => 'TEXT';
                process ".links",                     website => '@href';        
            },
        };

        my $want_nearly_free = scraper {
            process "li.almostFree", "contractors[]" => scraper { 
                process ".omnitureListingNameLink",   name    => 'TEXT';
                process ".address", address => 'TEXT'; # need to split this up into address, state, postcode,
                process ".phoneNumber",               phone   => 'TEXT';
                process ".links",                     website => '@href';        
            },
        };
        
        my $ua = $want->user_agent;
        print "Before scrape is called\n";
        $names = $want->scrape( 
            URI->new($url)
        );

        my $site = $names->{contractors}[3]->{website};
        print "Site is: $site\n";

        my $true_url = URI->new($site);
        my $query = URI::Query->new($true_url->query);
        my $site_from_query = uri_unescape($query->hash_arrayref->{webSite}->[0]); 
        push @information, { contractor => $names, real_website => $site_from_query };

        push @data, \@information;
        $url = $mech->find_link( text_regex => qr/^next$/i);
        last; # exit loop for debugging
        sleep(1);
    }
    last; # exit loop for debugging
}
open my $FH, ">", "final.yaml";
print $FH Dump \@data;
