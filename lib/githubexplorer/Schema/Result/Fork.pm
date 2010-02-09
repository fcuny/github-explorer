package githubexplorer::Schema::Result::Fork;

use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/Core/);
__PACKAGE__->table('fork');

__PACKAGE__->add_columns(
    profile_origin => { data_type => 'int', },
    profile_dest   => { data_type => 'int' },
    repo_origin    => { data_type => 'int' },
    repo_dest      => { data_type => 'int' },
);

__PACKAGE__->set_primary_key(
    qw/repo_origin repo_dest profile_origin profile_dest/ );

__PACKAGE__->belongs_to( 'profile_origin',
    'githubexplorer::Schema::Result::Profiles' );
__PACKAGE__->belongs_to( 'profile_dest',
    'githubexplorer::Schema::Result::Profiles' );

__PACKAGE__->belongs_to( 'repo_origin',
    'githubexplorer::Schema::Result::Repositories' );
__PACKAGE__->belongs_to( 'repo_dest',
    'githubexplorer::Schema::Result::Repositories' );

1;

