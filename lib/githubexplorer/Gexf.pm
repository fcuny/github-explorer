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
                                title => 'totalrepo'
                            },
                            {
                                id    => 1,
                                type  => 'string',
                                title => 'accountlogin'
                            },
                            {
                                id    => 2,
                                type  => 'string',
                                title => 'forkedrepo'
                            },
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
            id        => $profile->name,
            label     => $profile->name,
            attvalues => [
                { id => 0, value => 'total' },
                { id => 1, $profile->name },
                { id => 2, 'forked' }
            ]
        };
        push @{ $self->graph->{gexf}->{graph}->{nodes}->{node} }, $node;
    }
    use YAML::Syck;
    warn Dump $self->graph;
}

1;
