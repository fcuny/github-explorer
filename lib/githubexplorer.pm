package githubexplorer;
use 5.010;
use lib ('/home/franck/code/git/net-github/lib');
use YAML::Syck;
use Moose;
use githubexplorer::Schema;

with qw/githubexplorer::Profile githubexplorer::Repositorie/;

has seed         => ( isa => 'ArrayRef', is => 'ro', required => 1 );
has api_login    => ( isa => 'Str',      is => 'ro', required => 1 );
has api_token    => ( isa => 'Str',      is => 'ro', required => 1 );
has connect_info => ( isa => 'ArrayRef', is => 'ro', required => 1 );
has with_repo    => ( isa => 'Bool',     is => 'ro', default  => sub {0} );
has schema => (
    isa       => 'githubexplorer::Schema',
    is        => 'rw',
    predicate => 'has_schema'
);

sub deploy {
    my ($self) = @_;
    $self->_connect() unless $self->has_schema;
    $self->schema->deploy;
}

sub _connect {
    my $self = shift;
    $self->schema(
        githubexplorer::Schema->connect( @{ $self->connect_info } ) );
}

sub harvest_profiles {
    my ( $self, $depth) = @_;
    $self->_connect() unless $self->has_schema;
    $depth //= 1;
    foreach my $login ( @{ $self->seed } ) {
        $self->fetch_profile($login, $depth);
    }
}

sub harvest_repo {
    my ($self) = @_;
    $self->_connect unless $self->has_schema;
    my $profiles = $self->schema->resultset('Profiles')->search();
    while (my $p = $profiles->next) {
        $self->fetch_repo($p);
    }
}

1;
