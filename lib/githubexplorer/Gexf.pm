package githubexplorer::Gexf;

use Moose;
use XML::Simple;
use 5.010;

has schema => (is => 'ro', isa => 'Object', required => 1);
has id_edges => (is => 'rw', isa => 'Num', traits  => ['Counter'], default =>
0, handles => {inc_edges => 'inc'});

has graph => (
is      => 'rw',
isa     => 'HashRef',
default => sub {
    my $graph = {
        gexf => {
            version => "1.1",
            meta    => { creator => ['linkfluence'] },
            graph   => {
                type       => 'static',
                attributes => {
                    class     => 'node',
                    type      => 'static',
                    attribute => [
                        {
                            id    => 0,
                            type  => 'float',
                            title => 'name'
                        },
                        {
                            id => 1,
                            type => 'string',
                            title => 'type',
                        },
                        {
                            id    => 2,
                            type  => 'float',
                            title => 'followers_count'
                        },
                        {
                            id    => 3,
                            type  => 'float',
                            title => 'following_count'
                        },
                        {
                            id => 4,
                            type => 'float',
                            title => 'forks',
                        },
                        {
                            id => 5,
                            type => 'string',
                            title => 'location',
                        },
                        {
                            id => 6,
                            type => 'float',
                            title => 'public_gist_count',
                        },
                        {
                            id => 7,
                            type => 'float',
                            title => 'public_repo_count',
                        },
                        {
                            id => 8,
                            type => 'string',
                            title => 'language',
                        },
                        {
                            id => 9,
                            type => 'string',
                            title => 'description',
                        },
                        {
                            id => 10,
                            type => 'float',
                            title => 'watchers',
                        }
                    ]
                }
            }
        }
    };
}
);

sub gen_gexf {
    my $self = shift;

    $self->basic_profiles;
    my $basic_profiles = $self->dump_gexf;
    $basic_profiles > io('basic_profiles.gexf');

    $self->profiles_from_repositories;
    my $profiles_from_repositories = $self->dump_gexf;
    $profiles_from_repositories > io ('profiles_from_repositories.gexf');

    $self->repositories_from_profiles;
    my $repositories_from_profiles = $self->dump_gexf;
    $profiles_from_repositories > io ('repositories_from_profiles.gexf');
}

sub dump_gefx {
    my $self = shift;
    my $xml_out = XMLout( $self->graph, AttrIndent => 1, keepRoot => 1 );
    $self->graph->{gexf}->{graph}->{nodes} = undef;
    $self->graph->{gexf}->{graph}->{edges} = undef;
    return $xml_out;
}

sub basic_profiles {
    my $self     = shift;
    $self->id_edges(0);
    say "start basic_profiles ...";
    my $profiles = $self->schema->resultset('Profiles')->search();

    while ( my $profile = $profiles->next ) {
        my $node = $self->_get_node_for_profile($profile);
        push @{ $self->graph->{gexf}->{graph}->{nodes}->{node} }, $node;
    }

    my $edges = $self->schema->resultset('Follow')->search();
    my $id    = 0;
    while ( my $edge = $edges->next ) {
        my $e = {
            source   => $edge->origin->id,
            target   => $edge->dest->id,
            id       => $self->inc_edges,
        };
        push @{ $self->graph->{gexf}->{graph}->{edges}->{edge} }, $e;
    }
    say "basic_profiles done";
}

sub profiles_from_repositories {
    my $self = shift;
    $self->id_edges(0);
    say "start profiles_from_repositories ...";

    my ($nodes);
    my $profiles = $self->schema->resultset('Profiles')->search();
    while (my $profile = $profiles->next) {
        my $node = $self->_get_node_for_profile($profile);
        push @{ $self->graph->{gexf}->{graph}->{nodes}->{node} }, $node;
    }
    my $repositories = $self->schema->resultset('Repositories')->search();
    while (my $repos = $repositories->next) {
        my $forks = $self->schema->resultset('Fork')->search({repos => $repos->id});
        my @profiles;
        while (my $fork = $forks->next) {
            push @profiles, $fork->profile->id;
        }
        foreach my $p (@profiles) {
            map {
                next if $_ eq $p;
                my $e = {
                    source => $p,
                    target => $_,
                    id => $self->inc_edges,
                };
                push @{ $self->graph->{gexf}->{graph}->{edges}->{edge} }, $e;
            } @profiles;
        }
    }
    say "profiles_from_repositories done";
}

sub repositories_from_profiles {
    my $self = shift;
    $self->id_edges(0);
    say "start repositories_from_profiles ...";

    my ($nodes);
    my $repositories = $self->schema->resultset('Repositories')->search();
    while (my $repos = $repositories->next) {
        next if $repos->name =~ /dotfiles/;

        if (!exists $nodes->{$repos->name}) {
            my $language = $self->schema->resultset('RepoLang')->search({repository => $repos->id}, {order_by => 'size'})->first;
            my $lang = $language ? $language->language->name : 'none';
            $nodes->{$repos->name} = {
                id => $repos->name,
                label => $repos->name,
                attvalues => {
                    attvalue => [
                        { for => 0,  value => $repos->name},
                        { for => 1,  value => "repository"},
                        { for => 4,  value => $repos->forks},
                        { for => 9,  value => $repos->description},
                        { for => 10, value => $repos->watchers},
                        { for => 8,  value => $lang},
                    ],
                },
            };
        }
        my $forks = $self->schema->resultset('Fork')->search({repos => $repos->id});
        while (my $fork = $forks->next) {
            my $e = {
                source   => $fork->profile->id,
                target   => $fork->repos->name,
                id       => $self->inc_edges,
            };
            push @{ $self->graph->{gexf}->{graph}->{edges}->{edge} }, $e;
        }
    }
    map {push @{ $self->graph->{gexf}->{graph}->{nodes}->{node} }, $nodes->{$_} keys %$nodes;
    say "repositories_from_profiles done";
}

sub stats_languages_by_country {
    my $self = shift;
}

sub _get_node_for_profile {
    my ($self, $profile) = @_;
    my ($languages, $ordered_languages) = $self->_get_languages_for_profile($profile);
    my $main_lang = shift @$ordered_languages;
    my $node = {
        id              => $profile->id,
        label           => $profile->login,
        attvalues => {
            attvalue => [
                { for => 0, value => $profile->name},
                { for => 1, value => "profile"},
                { for => 2, value => $profile->followers_count},
                { for => 3, value => $profile->following_count},
                { for => 5, value => $profile->country},
                { for => 6, value => $profile->public_gist_count},
                { for => 7, value => $profile->public_repo_count},
                { for => 8, value => $main_lang},
            ]
        },
    };
    return $node;
}

sub _get_languages_for_profile {
    my ($self, $profile) = shift;

    my $forks = $self->schema->resultset('Fork')->search({profile =>
        $profile->id});

    my %languages;
    while (my $fork = $forks->next) {
        my $languages =
        $self->schema->resultset('RepoLang')->search({repository =>
                $fork->repos->id});
        while (my $lang = $languages->next) {
            $languages{$lang->language->name}+=$lang->size;
        }
    }
    my @sorted_lang = sort {$languages{$b} <=> $languages{$a}} keys %languages;
    return (\%languages, \@sorted_lang);
}

#sub repositories {
#    my $self = shift;
#
#    say "start repositories ...";
#    my $repositories = $self->schema->resultset('Repositories')->search({fork => 0});
#    while (my $repos = $repositories->next) {
#
#        next if $repos->name =~ /dotfiles/i;
#        # available in forks ?
#        my $check_fork = $self->schema->resultset('Fork')->search({repos => $repos->id});
#        next if $check_fork->count < 1;
#
#        if (!grep {$_->{id} eq "repos_".$repos->name} @{$self->graph->{gexf}->{graph}->{nodes}->{node}}) {
#            my $language = $self->schema->resultset('RepoLang')->search({repository => $repos->id}, {order_by => 'size'})->first;
#            my $lang = $language ? $language->language->name : 'none';
#            my $node = {
#                id => "repos_".$repos->name,
#                label => $repos->name,
#                attvalues => {
#                    attvalue => [
#                        { for => 0,  value => $repos->name},
#                        { for => 1,  value => "repository"},
#                        { for => 4,  value => $repos->forks},
#                        { for => 9,  value => $repos->description},
#                        { for => 10, value => $repos->watchers},
#                        { for => 8,  value => $lang},
#                    ],
#                },
#            };
#            push @{ $self->graph->{gexf}->{graph}->{nodes}->{node} }, $node;
#        }
#        my $e = {
#            source   => $repos->id_profile->id,
#            target   => "repos_".$repos->name,
#            id       => $self->inc_edges,
#        };
#        push @{ $self->graph->{gexf}->{graph}->{edges}->{edge} }, $e;
#    }
#
#    my $forks = $self->schema->resultset('Fork')->search();
#
#    while (my $fork = $forks->next) {
#        next if $fork->repos->name =~ /dotfiles/i;
#        my $e = {
#            source   => $fork->profile->id,
#            target   => "repos_".$fork->repos->name,
#            id       => $self->inc_edges,
#        };
#        push @{ $self->graph->{gexf}->{graph}->{edges}->{edge} }, $e;
#    }
#    say " done";
#}

1;
