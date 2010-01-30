#!/usr/bin/env perl
use strict;
use warnings;
use lib ('lib');
use githubexplorer;
use Getopt::Long;

GetOptions(
    'deploy'   => \my $deploy,
    'profiles' => \my $profiles,
    'repo'     => \my $repo,
    'graph' => \my $graph,
);

my $gh = githubexplorer->new(
    seed      => [qw/franckcuny/],
    api_token => $ENV{'GITHUB_APIKEY'},
    api_login => $ENV{'GITHUB_LOGIN'},
    with_repo => $repo,
    connect_info =>
        [ 'dbi:SQLite:dbname=test.sqlite', '', '', { AutoCommit => 1 } ],
);

$gh->deploy if $deploy;
$gh->harvest_profiles if $profiles;
$gh->gen_graph if $graph;
