package githubexplorer::Repository;
use 5.010;
use Moose::Role;
use Net::GitHub::V2::Repositories;
use Try::Tiny;

sub fetch_repositories {
    my ( $self, $profile ) = @_;

    my $github_profile = Net::GitHub::V2::Users->new(
        owner => $profile->login,
        login => $self->api_login,
        token => $self->api_token,
    );

    my $repo_list = $github_profile->list();

    if ( ref $repo_list ne 'ARRAY' ) {
        sleep(60);
        return;
    }

    foreach my $repos (@$repo_list) {
        next if $self->_repo_exists( $profile, $repos->{name} );
        say "-> check " . $profile->login . "'s " . $repos->{name};
        if ( $repos->{forks} == 0 ) {
            say "<- not forked, skip";
            next;
        }
        my $repo_rs;
        unless ( $repo_rs = $self->_repo_exists( $profile, $repos->{name} ) )
        {
            $repo_rs = $self->_create_repo( $profile, $repos );
            say "== repository " . $repos->{name} . " created";
        }
        sleep(1);
        my $api_repos = Net::GitHub::V2::Repositories->new(
            owner => $profile->login,
            repo  => $repos->{name},
            login => $self->api_login,
            token => $self->api_token,
        );
        my $langs = $api_repos->languages;
        if ( ref $langs ne 'HASH' ) {
            sleep(60);
            next;
        }

        foreach my $lang ( keys %$langs ) {
            my $lang_rs = $self->_lang_exists($lang);
            try {
                $self->schema->resultset('RepoLang')->create(
                    {
                        repository => $repo_rs->id,
                        language   => $lang_rs->name,
                        size       => $langs->{$lang},
                    }
                );
            };
        }
        sleep(1);
    }
    sleep(1);
}

sub _lang_exists {
    my ( $self, $lang ) = @_;
    $self->schema->resultset('Language')->find_or_create({name => $lang});
}

sub _repo_exists {
    my ( $self, $profile, $repo_name ) = @_;
    $self->schema->resultset('Repositories')
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
