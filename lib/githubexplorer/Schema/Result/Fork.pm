package githubexplorer::Schema::Result::Fork;

use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/Core/);
__PACKAGE__->table('fork');

__PACKAGE__->add_columns(
    profile => { data_type => 'int', },
    repos   => { data_type => 'int' },
);

__PACKAGE__->set_primary_key(qw/repos profile/);

__PACKAGE__->belongs_to( 'profile',
    'githubexplorer::Schema::Result::Profiles' );

__PACKAGE__->belongs_to( 'repos',
    'githubexplorer::Schema::Result::Repositories' );

1;

