package githubexplorer::Gexf;

use Moose;
use XML::Simple;

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
                        attribute => [ { id => 0, type => 'string' } ]
                    }
                }
            }
        };
    }
);

1;
