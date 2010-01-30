package githubexplorer::Profile;
use 5.010;
use Moose::Role;
use Net::GitHub::V2::Users;

has banned_profiles =>
    ( isa => 'ArrayRef', is => 'ro', default => sub { [qw/gitpan/] } );

sub fetch_profile {
    my ( $self, $login, $depth ) = @_;

    return if grep {$_ =~ /$login/i} @{$self->banned_profiles};

    return if $depth > 2;
    my $profile = $self->_profile_exists($login);

    say "fetch profile for $login ($depth)...";
    my $github = Net::GitHub::V2::Users->new(
        owner => $login,
        login => $self->api_login,
        token => $self->api_token,
    );
    sleep(1);

    if ( !$profile ) {
        $profile = $self->_create_profile( $login, $github->show, $depth );
        sleep(1);
    }
    if ( $self->with_repo ) {
        $self->fetch_repositories( $profile, $github->list );
    }

    my $followers   = $github->followers();
    sleep(1);
    my $following   = $github->following();
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

    foreach my $f (@$following) {
        my $p = $self->fetch_profile( $f, $local_depth );
        next unless $p;
        $self->schema->txn_do(
            sub {
                $self->schema->resultset('Follow')
                    ->find_or_create(
                    { id_following => $p->id, id_follower => $profile->id } );
            },

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
