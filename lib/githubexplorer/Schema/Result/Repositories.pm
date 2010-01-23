package githubexplorer::Schema::Result::Repositories;

use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/Core/);
__PACKAGE__->table('repositories');
__PACKAGE__->add_columns(
    id          => { data_type => 'integer', is_auto_increment => 1 },
    description => { data_type => 'text',    is_nullable       => 1 },
    name        => { data_type => 'varchar' },
    homepage    => { data_type => 'varchar', is_nullable       => 1 },
    url         => { data_type => 'varchar', is_nullable       => 1 },
    watchers    => { data_type => 'int' },
    forks       => { data_type => 'int' },
    id_profile  => { data_type => 'int',     is_foreign_key    => 1 },
);

__PACKAGE__->set_primary_key('id');
__PACKAGE__->belongs_to( 'id_profile',
    'githubexplorer::Schema::Result::Profiles' );
__PACKAGE__->add_unique_constraint( [qw/name id_profile/] );

1;
