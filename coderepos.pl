#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;
use Web::Scraper;
use URI;
use YAML::Syck;

my $scraper = scraper{process "a", "commiters[]" => "TEXT"};

my $res = $scraper->scrape(URI->new('http://coderepos.org/share/'));

my @coderepos;
foreach my $link (@{$res->{commiters}}) {
    next if $link !~ /^Committer:(\w+)/;
    push @coderepos, $1;
}

DumpFile('tocheck_coderepos.yaml', \@coderepos);
