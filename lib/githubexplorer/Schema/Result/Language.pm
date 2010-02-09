package githubexplorer::Schema::Result::Language;

use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/Core/);
__PACKAGE__->table('languages');

__PACKAGE__->add_columns( name => { data_type => 'varchar' }, );

__PACKAGE__->set_primary_key('name');

1;
