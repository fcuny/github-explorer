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
    $self->profiles;
    #$self->repositories;
    say "total nodes : ".scalar (@{ $self->graph->{gexf}->{graph}->{nodes}->{node} });
    say "total edges : ".scalar (@{ $self->graph->{gexf}->{graph}->{edges}->{edge} });
    my $xml_out = XMLout( $self->graph, AttrIndent => 1, keepRoot => 1 );
    return $xml_out;
}

sub profiles {
    my $self     = shift;
    say "start profiles ...";
    my $profiles = $self->schema->resultset('Profiles')->search();

    while ( my $profile = $profiles->next ) {
        my $node = {
            id              => $profile->id,
            label           => $profile->login,
            attvalues => {
                attvalue => [
                    { for => 0, value => $profile->name},
                    { for => 1, value => "profile"},
                    { for => 2, value => $profile->followers_count},
                    { for => 3, value => $profile->following_count},
                    { for => 5, value => $profile->location},
                    { for => 6, value => $profile->public_gist_count},
                    { for => 7, value => $profile->public_repo_count},
                ]
            },
        };
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
    say " done";
}

sub repositories {
    my $self = shift;

    say "start repositories ...";
    my $repositories = $self->schema->resultset('Repositories')->search({fork => 0});
    while (my $repos = $repositories->next) {

        next if $repos->name =~ /dotfiles/i;
        # available in forks ?
        my $check_fork = $self->schema->resultset('Fork')->search({repos => $repos->id});
        next if $check_fork->count < 1;

        if (!grep {$_->{id} eq "repos_".$repos->name} @{$self->graph->{gexf}->{graph}->{nodes}->{node}}) {
            my $language = $self->schema->resultset('RepoLang')->search({repository => $repos->id}, {order_by => 'size'})->first;
            my $lang = $language ? $language->language->name : 'none';
            my $node = {
                id => "repos_".$repos->name,
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
            push @{ $self->graph->{gexf}->{graph}->{nodes}->{node} }, $node;
        }
        my $e = {
            source   => $repos->id_profile->id,
            target   => "repos_".$repos->name,
            id       => $self->inc_edges,
        };
        push @{ $self->graph->{gexf}->{graph}->{edges}->{edge} }, $e;
    }

    my $forks = $self->schema->resultset('Fork')->search();

    while (my $fork = $forks->next) {
        next if $fork->repos->name =~ /dotfiles/i;
        my $e = {
            source   => $fork->profile->id,
            target   => "repos_".$fork->repos->name,
            id       => $self->inc_edges,
        };
        push @{ $self->graph->{gexf}->{graph}->{edges}->{edge} }, $e;
    }
    say " done";
}

1;
