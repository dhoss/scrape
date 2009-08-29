#!/usr/bin/env perl
use strict;
use warnings;

use URI;
  use Web::Scraper;

  my $tweets = scraper {
      process "li.status", "tweets[]" => scraper {
          process ".entry-content", body => 'TEXT';
          process ".entry-date", when => 'TEXT';
          process 'a[rel="bookmark"]', link => '@href';
      };
  };

  my $res = $tweets->scrape( URI->new("http://twitter.com/miyagawa") );

  for my $tweet (@{$res->{tweets}}) {
      print "$tweet->{body} $tweet->{when} (link: $tweet->{link})\n";
  }
