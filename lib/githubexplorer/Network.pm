package githubexplorer::Network;
use 5.010;
use Moose::Role;
use Net::GitHub::V2::Repositories;
use YAML::Syck;

sub fetch_network {
    my ( $self, $repos ) = @_;

    say ">> start on ".$repos->name;
    my $api_repos = Net::GitHub::V2::Repositories->new(
        owner => $repos->id_profile->login,
        repo  => $repos->name,
        login => $self->api_login,
        token => $self->api_token,
    );

    my $edges = $api_repos->network();
    sleep(1);
    foreach my $edge (@$edges) {
        next if $edge->{owner} eq $repos->id_profile->login;
        my $profile = $self->schema->resultset('Profiles')
            ->find( { login => $edge->{owner} } );
        next if !$profile;

        say "** create relation between ".$repos->name." and ".$profile->login;
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
