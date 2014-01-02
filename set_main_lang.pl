#!/usr/bin/env perl
use strict;
use warnings;
use YAML::Syck;
use lib ('lib');
use githubexplorer;

my $conf = LoadFile(shift);

my $gh = githubexplorer->new(
    api_token    => $ENV{'GITHUB_APIKEY'},
    api_login    => $ENV{'GITHUB_LOGIN'},
    connect_info => $conf->{connect_info},
);

$gh->_connect unless $gh->has_schema;
#my $graph = githubexplorer::Gexf->new( schema => $gh->schema );

my $repositories = $gh->schema->resultset('Repositories')->search();
while (my $repos = $repositories->next) {
    my $language = $gh->schema->resultset('RepoLang') ->search( { repository => $repos->id }, { order_by => 'size' } )->first;
    if ($language) {
        $repos->update({main_language => $language->language->name});
    }
}
