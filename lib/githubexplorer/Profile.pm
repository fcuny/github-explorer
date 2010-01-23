package githubexplorer::Profile;
use 5.010;
use Moose::Role;
use Net::GitHub::V2::Users;

sub fetch_profile {
    my ( $self, $login, $depth ) = @_;

    return if $depth > 3;
    my $profile = $self->_profile_exists($login);

    say "fetch profile for $login ($depth)...";
    sleep(1);
    my $github = Net::GitHub::V2::Users->new(
        owner => $login,
        login => $self->api_login,
        token => $self->api_token,
    );
    sleep(2);

    if ( !$profile ) {
        $profile = $self->_create_profile( $login, $github->show, $depth );
        if ( $self->with_repo ) {
            foreach my $repo ( @{ $github->list } ) {
                $self->fetch_repo( $profile, $repo->{name} );
            }
        }
        sleep(1);
    }
    my $followers   = $github->followers();
    my $local_depth = $depth + 1;
    foreach my $f (@$followers) {
        my $p = $self->fetch_profile( $f, $local_depth );
        next unless $p;
        $self->schema->txn_do(
            sub {
                $self->schema->resultset('Follow')
                    ->find_or_create(
                    { id_following => $profile->id, id_follower => $p->id } );
            }
        );
    }
    $profile;
}

sub _profile_exists {
    my ( $self, $login ) = @_;
    my $profile
        = $self->schema->resultset('Profiles')->find( { login => $login } );
    return $profile;
}

sub _create_profile {
    my ( $self, $user_name, $profile, $depth ) = @_;

    $profile->{depth} = $depth;

    my $profile_rs;

    $self->schema->txn_do(
        sub {
            $profile_rs
                = $self->schema->resultset('Profiles')->create($profile);
        }
    );
    say '-> '.$profile_rs->login . "'s profile created";
    return $profile_rs;
}

1;
