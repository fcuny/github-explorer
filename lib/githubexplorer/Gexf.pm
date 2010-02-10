package githubexplorer::Gexf;

use Moose;
use XML::Simple;

has schema => (is => 'ro', isa => 'Object', required => 1);

has graph => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub {
        my $graph = {
            gexf => {
                version => "1.0",
                meta    => { creator => ['rtgi'] },
                graph   => {
                    type       => 'static',
                    attributes => {
                        class     => 'node',
                        type      => 'static',
                        attribute => [
                            {
                                id    => 0,
                                type  => 'string',
                                title => 'name'
                            },
                            {
                                id => 1,
                                type => 'string',
                                title => 'type',
                            },
                            {
                                id    => 2,
                                type  => 'string',
                                title => 'followers_count'
                            },
                            {
                                id    => 3,
                                type  => 'string',
                                title => 'following_count'
                            },
                            {
                                id => 4,
                                type => 'string',
                                title => 'forks',
                            },
                            {
                                id => 5,
                                type => 'string',
                                title => 'location',
                            },
                            {
                                id => 6,
                                type => 'string',
                                title => 'public_gist_count',
                            },
                            {
                                id => 7,
                                type => 'string',
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
                                type => 'string',
                                title => 'watchers',
                            }
                        ]
                    }
                }
            }
        };
    }
);

sub profiles {
    my $self     = shift;
    my $profiles = $self->schema->resultset('Profiles')->search();

    while ( my $profile = $profiles->next ) {
        my $node = {
            id              => $profile->id,
            label           => $profile->login,
            attvalues => {
                attvalue => [
                    {name            => $profile->name},
                    {followers_count => $profile->followers_count},
                    {following_count => $profile->following_count},
                ]
            },
        };
        push @{ $self->graph->{gexf}->{graph}->{nodes}->{node} }, $node;
    }

    my $edges = $self->schema->resultset('Follow')->search();
    my $id    = 0;
    while ( my $edge = $edges->next ) {
        my $e = {
            cardinal => 1,
            source   => $edge->origin->id,
            target   => $edge->dest->id,
            type     => 'dir',
            id       => $id++,
        };
        push @{ $self->graph->{gexf}->{graph}->{edges}->{edge} }, $e;
    }

    my $xml_out = XMLout( $self->graph, AttrIndent => 1, keepRoot => 1 );
    return $xml_out;
}

sub repositories {
    my $self = shift;
    my $repositories = $self->schema->resultset('Repositories')->search();

    while (my $repo = $repositories->next) {
    }
}

1;
