package githubexplorer::Schema::Result::RepoLang;

use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/Core/);
__PACKAGE__->table('repolang');

__PACKAGE__->add_columns(
    repository => { data_type => 'int', },
    language   => { data_type => 'varchar', },
    size       => { data_type => 'int' },
);

__PACKAGE__->set_primary_key(qw/repository language/);
__PACKAGE__->belongs_to( 'repository',
    'githubexplorer::Schema::Result::Repositories' );
__PACKAGE__->belongs_to( 'language',
    'githubexplorer::Schema::Result::Language' );

1;
