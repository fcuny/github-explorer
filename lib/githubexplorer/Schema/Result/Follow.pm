package githubexplorer::Schema::Result::Follow;

use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/Core/);
__PACKAGE__->table('follow');

__PACKAGE__->add_columns(
    id_follower  => { data_type => 'int', },
    id_following => { data_type => 'int' },
);
__PACKAGE__->set_primary_key(qw/id_follower id_following/);
__PACKAGE__->belongs_to( 'id_follower',
    'githubexplorer::Schema::Result::Profiles' );
__PACKAGE__->belongs_to( 'id_following',
    'githubexplorer::Schema::Result::Profiles' );

1;
