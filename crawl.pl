#!/usr/bin/env perl
use strict;
use warnings;
use lib ('lib');
use githubexplorer;
use Getopt::Long;
use YAML::Syck;

GetOptions(
    'deploy'   => \my $deploy,
    'profiles' => \my $profiles,
    'repo'     => \my $repo,
    'graph'    => \my $graph,
    'network'  => \my $network,
    'seed'  => \my $seed,
    'conf=s'   => \my $conf,
);

my $conf_data = LoadFile($conf);

my $gh = githubexplorer->new(
    seed         => [qw/franckcuny/],
    api_token    => $ENV{'GITHUB_APIKEY'},
    api_login    => $ENV{'GITHUB_LOGIN'},
    with_repo    => $repo,
    connect_info => $conf_data->{connect_info},
);

$gh->deploy           if $deploy;
$gh->harvest_profiles if $profiles;
$gh->harvest_repo     if $repo;
$gh->graph_repo       if $network;
$gh->gen_graph        if $graph;
$gh->gen_seed         if $seed;
