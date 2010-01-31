package githubexplorer::Schema::Result::Profiles;

use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/Core/);
__PACKAGE__->table('profiles');
__PACKAGE__->add_columns(
    id                => { data_type => 'integer', },
    login             => { data_type => 'varchar' },
    blog              => { data_type => 'varchar', is_nullable => 1 },
    company           => { data_type => 'varchar', is_nullable => 1 },
    created_at        => { data_type => 'timestamp' },
    email             => { data_type => 'varchar', is_nullable => 1 },
    followers_count   => { data_type => 'int' },
    following_count   => { data_type => 'int' },
    gravatar_id       => { data_type => 'varchar', is_nullable => 1 },
    location          => { data_type => 'varchar', is_nullable => 1 },
    name              => { data_type => 'varchar', is_nullable => 1 },
    public_gist_count => { data_type => 'int' },
    public_repo_count => { data_type => 'int' },
    depth             => { data_type => 'int' },
    done              => { data_type => 'boolean', default_value => 0 },
    perl_total_bytes =>
        { data_type => 'int', is_nullable => 1, default_value => 0 },
);

__PACKAGE__->set_primary_key('id');
__PACKAGE__->has_many( 'get_repos',
    'githubexplorer::Schema::Result::Repositories', 'id_profile' );

1;
