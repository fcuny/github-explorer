package githubexplorer;
use 5.010;
use YAML::Syck;
use Moose;
use githubexplorer::Schema;
use githubexplorer::Gexf;
use IO::All;

with qw/githubexplorer::Profile githubexplorer::Repository
    githubexplorer::Network/;

has seed => (
    isa      => 'ArrayRef',
    is       => 'rw',
    required => 1,
    lazy     => 1,
    default  => sub {
        my $self     = shift;
        my $profiles = $self->schema->resultset('Profiles')
            ->search( { done => { '!=', 1 } }, { order_by => 'login desc' } );
        my @seeds;
        while ( my $p = $profiles->next ) {
            push @seeds, $p->login;
        }
        return \@seeds;
    }
);
has api_login    => ( isa => 'Str|Undef', is => 'ro', required => 1 );
has api_token    => ( isa => 'Str|Undef', is => 'ro', required => 1 );
has connect_info => ( isa => 'ArrayRef',  is => 'ro', required => 1 );
has with_repo    => ( isa => 'Bool',      is => 'ro', default  => sub {0} );
has schema => (
    isa       => 'githubexplorer::Schema',
    is        => 'rw',
    predicate => 'has_schema'
);

sub deploy {
    my ($self) = @_;
    $self->_connect() unless $self->has_schema;
    $self->schema->deploy;
}

sub _connect {
    my $self = shift;
    $self->schema(
        githubexplorer::Schema->connect( @{ $self->connect_info } ) );
}

sub harvest_profiles {
    my ( $self, $depth ) = @_;
    $self->_connect() unless $self->has_schema;
    $depth //= 1;
    foreach my $login ( @{ $self->seed } ) {
        $self->fetch_profile( $login, $depth );
    }
}

sub harvest_repo {
    my $self = shift;
    $self->_connect unless $self->has_schema;
    my $profiles = $self->schema->resultset('Profiles')->search();
    while ( my $p = $profiles->next ) {
        $self->fetch_repositories($p);
    }
}

sub gen_graph {
    my $self = shift;
    $self->_connect unless $self->has_schema;
    my $graph = githubexplorer::Gexf->new( schema => $self->schema );
    $graph->gen_gexf;
}

sub graph_repo {
    my $self = shift;
    $self->_connect unless $self->has_schema;
    my $repos
        = $self->schema->resultset('Repositories')->search( { fork => 0 } );
    while ( my $r = $repos->next ) {
        $self->fetch_network($r);
    }
}

sub gen_seed {
    my $self = shift;
    $self->_connect unless $self->has_schema;
    my $profiles = $self->schema->resultset('Profiles')
        ->search( { blog => { '!=' => undef }, blog => { '!=' => '' } } );

    open my $fh, '>', 'seed.csv';
    while ( my $pr = $profiles->next ) {
        my %languages;
        my $forks = $self->schema->resultset('Fork')
            ->search( { profile => $pr->id } );
        while ( my $fork = $forks->next ) {
            my $languages = $self->schema->resultset('RepoLang')
                ->search( { repository => $fork->repos->id } );
            while ( my $lang = $languages->next ) {
                $languages{ $lang->language->name } += $lang->size;
            }
        }
        my @sorted_lang
            = sort { $languages{$b} <=> $languages{$a} } keys %languages;
        my $main_lang = shift @sorted_lang;
        my $other_lang = join( '|', @sorted_lang );
        my $str
            = $pr->blog
            . ";;;github;"
            . ($main_lang || '') . ";"
            . ($other_lang || '') . ";"
            . ($pr->country || ''). "\n";
        print $fh $str;
    }
    close $fh;
}

sub stats_by_country {
    my $self = shift;
    $self->_connect unless $self->has_schema;
    my $repositories = $self->schema->resultset('Repositories')->search();

    my $countries;
    while (my $repos = $repositories->next) {
        next if !$repos->id_profile->country;
        my $languages = $self->schema->resultset('RepoLang')
            ->search( { repository => $repos->id } );
        while ( my $lang = $languages->next ) {
            $countries->{ $repos->id_profile->country }->{$lang->language->name} += $lang->size;
        }
    }
    foreach my $country (keys %$countries) {
        my $total = $self->schema->resultset('Profiles')->search({country => $country})->count;
        $countries->{$country}->{total_dev} = $total;
        my $total_bytes;
        map {$total_bytes += $countries->{$country}->{$_}} keys %{$countries->{$country}};
        foreach my $lang (keys %{$countries->{$country}}) {
            $countries->{$country}->{"pct_".$lang} = ($countries->{$country}->{$lang} / $total_bytes) * 100;
        }
    }
    my @sorted_countries = sort {$countries->{$b}->{total_dev} <=> $countries->{$a}->{total_dev}} keys %$countries;

    my $final;
    for ( 0 .. 19) {
        push @$final, {$sorted_countries[$_] => $countries->{$sorted_countries[$_]} };
    }
    warn Dump $final;
    DumpFile('countries.yaml', $final);
}

1;
