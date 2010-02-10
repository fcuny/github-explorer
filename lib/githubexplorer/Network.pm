package githubexplorer::Network;
use 5.010;
use Moose::Role;
use Net::GitHub::V2::Repositories;
use YAML::Syck;

sub fetch_network {
    my ( $self, $repos ) = @_;

    my $api_repos = Net::GitHub::V2::Repositories->new(
        owner => $repos->id_profile->login,
        repo  => $repos->name,
        login => $self->api_login,
        token => $self->api_token,
    );

    my $edges = $api_repos->network();
    foreach my $edge (@$network) {
        next if $edge->{owner} eq $repos->id_profile->login;
        my $profile = $self->schema->resultset('Profiles')
            ->find( { login => $edge->{owner} } );
        next if !$profile;

        my $relation = $self->schema->resultset('Fork')->find_or_create(
            {
                profile => $profile->id,
                repos   => $repos->id
            }
        );
    }
    sleep(1);
}

1;
