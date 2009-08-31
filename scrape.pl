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
my $start_url =  'http://yellowpages.com.au/search/listingsSearch.do?region=australia&ul.street=&headingCode=22683&sortByAlphabetical=true&rankType=1&webLink=false&userState=select+---%3E&sortByDistance=false&locationForSortBySelected=false&locationText=All+States&adPs=&adPs=&adPs=&adPs=&adPs=&ul.streetNumber=&sortByDetail=false&ul.suburb=&businessType=Electrical+contractors&sortByClosestMatch=false&sortBy=alpha&rankWithTolls=true&stateId=9&safeLocationClue=All+States&__HERE__&locationClue=All+States&serviceArea=true&suburbPostcode=';
my $mech = WWW::Mechanize->new;
### mech object initiated
### got our url
my $names;
my @information;
### Entering link following loop
my @letters = ('a' .. 'z', 0);
foreach my $l (@letters) {
    my $base_url = $start_url;
    $base_url =~ s/__HERE__/$l/;
    my $page = 1;
    ### Letter: $l

    while ($base_url) {
        $mech->get($base_url);
        $base_url = "http://yellowpages.com.au" . $mech->find_link( text_regex => qr/^next$/i)->url;
        $page++;
        ### Page: $page

        # ARGH.  Actually we want classes: li.gold li.free and li.almostFree
        my @gold        = scrape_some('gold', $mech);
        my @free        = scrape_some('free', $mech);
        my @nearly_free = scrape_some('almostFree', $mech);
        undef $base_url  if (!@gold && !@free && !@nearly_free); # nothing on this or subsequent pages for this loop.
        push @information, (@gold, @free, @nearly_free);
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
        last if $page == 3; # debug
        ### Letter: $l
    }
    last if $page == 3; # debug
    ### 5bailing on page $page
}

### All done!

sub scrape_some {
    my ( $list_type, $mech ) = @_;
    my @contractors; # return value
    my $want = scraper {
        process "li.$list_type" , "contractors[]" => scraper { 
            process ".omnitureListingNameLink",   name    => 'TEXT';
            process ".address", address => 'TEXT'; # need to split this up into address, state, postcode,
            process ".phoneNumber",               phone   => 'TEXT';
            process ".links",                     website => '@href';
        };
    };
    my $ua = $want->user_agent;
    ### Before scrape is called
    my $names = $want->scrape( $mech->content, $mech->uri);
    my @ppl = @{$names->{contractors}};

    foreach my $p (@ppl) {
        if (exists $p->{website}) {
            my $site = $p->{website};
            my $true_url      = URI->new($site);
            my $query = URI::Query->new($true_url->query);
            my $site_from_query = uri_unescape($query->hash_arrayref->{webSite}->[0]);
            $p->{website} = $site_from_query;
        }
        $p->{type} = $list_type;
        push @contractors, @ppl;
    }
    return @contractors;
}
