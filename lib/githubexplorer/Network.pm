package githubexplorer::Network;
use 5.010;
use Moose::Role;
use Net::GitHub::V2::Repositories;
use YAML::Syck;

sub fetch_network {
    my ( $self, $repos ) = @_;

    # check fork
    my $check = $self->schema->resultset('Fork')->search({repos=>
            $repos->id});
    return if $check->count > 0;

    say ">> start on ".$repos->name;
    my $api_repos = Net::GitHub::V2::Repositories->new(
        owner => $repos->id_profile->login,
        repo  => $repos->name,
        login => $self->api_login,
        token => $self->api_token,
    );

    my $edges = $api_repos->network();
    if (ref $edges ne 'ARRAY') {
        sleep 60;
        return;
    }
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
