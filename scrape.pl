#!/usr/bin/env perl
use Smart::Comments;
use warnings;
use strict;
use Web::Scraper;
use URI;
use YAML qw/ Dump /;
use WWW::Mechanize;
use WWW::Mechanize::Link;
use URI::Query;
use URI::Escape;
use IO::File;

### On your marks
my $yaml;
my $start_url =  WWW::Mechanize::Link->new( { url =>'http://yellowpages.com.au/search/listingsSearch.do?region=australia&ul.street=&headingCode=22683&sortByAlphabetical=true&rankType=1&webLink=false&userState=select+---%3E&sortByDistance=false&locationForSortBySelected=false&locationText=All+States&adPs=&adPs=&adPs=&adPs=&adPs=&ul.streetNumber=&sortByDetail=false&ul.suburb=&businessType=Electrical+contractors&sortByClosestMatch=false&sortBy=alpha&rankWithTolls=true&stateId=9&safeLocationClue=All+States&__HERE__&locationClue=All+States&serviceArea=true&suburbPostcode='});

### Get Set
my $mech = WWW::Mechanize->new;
my @letters = (0, 'a' .. 'z');
unlink "full.yml";


### GO!
foreach my $l (@letters) {
    my $base_url = $start_url->url;
    $base_url =~ s/__HERE__/currentLetter=$l/;
    my $page = 1;
    ### Letter: $l

    while ($base_url) {
        ### Page: $page
        $mech->get($base_url);
        my $next = $mech->find_link( text_regex => qr/^Next$/i);

        # Bailout
        $base_url = $next ? $next : undef;

        $page++;

        # ARGH.  Actually we want classes: li.gold li.free and li.almostFree
        my @gold        = scrape_some('gold', $mech);
        my @free        = scrape_some('free', $mech);
        my @nearly_free = scrape_some('almostFree', $mech);

        # bailout condition
        undef $base_url  if (!@gold && !@free && !@nearly_free); # nothing on this or subsequent pages for this loop.
        my @information = (@gold, @free, @nearly_free);
        open my $OUT, ">>", "full.yml";
        print $OUT Dump(@information);
        close $OUT;
    }
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
    my $names = $want->scrape( $mech->content, $mech->uri);
    my @ppl = ();
    @ppl = @{$names->{contractors}} if $names->{contractors};

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
