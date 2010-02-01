package githubexplorer::Schema::Result::Follow;

use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/Core/);
__PACKAGE__->table('follow');

__PACKAGE__->add_columns(
    origin => { data_type => 'int', },
    dest   => { data_type => 'int' },
);
__PACKAGE__->set_primary_key(qw/origin dest/);
__PACKAGE__->belongs_to( 'origin',
    'githubexplorer::Schema::Result::Profiles' );
__PACKAGE__->belongs_to( 'dest', 'githubexplorer::Schema::Result::Profiles' );

1;
