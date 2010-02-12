#!/usr/bin/env perl
use strict;
use warnings;
use lib ('lib');
use 5.010;
use Geo::GeoNames;
use githubexplorer::Schema;
use YAML::Syck;

my $conf = LoadFile(shift);

my $schema = githubexplorer::Schema->connect( @{ $conf->{connect_info} } );

my $profiles = $schema->resultset('Profiles')->search(
    {
        id       => { '>'  => 55781 },
        location => { '!=' => undef },
        location => { '!=' => '' }
    }
);

my $geo = Geo::GeoNames->new();

while ( my $pr = $profiles->next ) {
    next if $pr->location =~ /^http/;
    next if $pr->country;
    next if $pr->location =~ /earth/i;
    say "-> process " . $pr->login . " with " . $pr->location;
    my $result = $geo->search( q => $pr->location, maxRows => 1 );
    my $res = shift @$result;
    if ($res) {
        eval {
            $pr->update(
                { city => $res->{name}, country => $res->{countryName} } );
        };
        next if $@;
        say "** fix with " . $pr->city . " in " . $pr->country;
    }
    sleep(1);
}