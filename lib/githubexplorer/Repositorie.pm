package githubexplorer::Repositorie;
use 5.010;
use Moose::Role;
use Net::GitHub::V2::Repositories;

sub fetch_repositories {
    my ( $self, $profile, $repo_list ) = @_;

    foreach my $repo (@$repo_list) {
        next if $self->_repo_exists( $profile, $repo->{name} );
        say "-> check " . $profile->login . "'s ".$repo->{name};
        # my $github = Net::GitHub::V2::Repositories->new(
        #     owner => $profile->login,
        #     repo  => $repo->{name},
        #     login => $self->api_login,
        #     token => $self->api_token,
        # );

  # my $langs = $github->languages();
  # sleep(1);
  # return unless grep {/perl/i} keys %$langs;
  # my $repo_desc = $github->show();
  # sleep(1);
  # $profile->perl_total_bytes( $profile->perl_total_bytes + $langs->{Perl} );
  # $self->schema->txn_do( sub { $profile->update } );
        $self->_create_repo( $profile, $repo );
    }
}


sub _repo_exists {
    my ( $self, $profile, $repo_name ) = @_;
    return
        if $self->schema->resultset('Repositories')
            ->find( { name => $repo_name, id_profile => $profile->id } );
}

sub _create_repo {
    my ( $self, $profile, $repo_desc ) = @_;

    my $repo_rs = $self->schema->resultset('Repositories')
        ->find( { id_profile => $profile->id, name => $repo_desc->{name} } );
    if ( !$repo_rs ) {
        my $repo_insert = {
            id_profile => $profile->id,
            map { $_ => $repo_desc->{$_} }
                (qw/description name homepage url watchers forks fork/)
        };
        $self->schema->txn_do(
            sub {
                $repo_rs = $self->schema->resultset('Repositories')
                    ->create($repo_insert);
            }
        );
    }
    $repo_rs;
}

1;
