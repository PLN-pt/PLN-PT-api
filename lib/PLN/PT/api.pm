package PLN::PT::api;
use Dancer2;
use File::Temp;
use Path::Tiny;
use Lingua::Jspell;
use Lingua::PT::Actants;
use Lingua::PT::PLNbase;
use Lingua::StopWords qw/getStopWords/;

use PLN::PT::api::utils;
use PLN::PT::api::tokenizer;
use PLN::PT::api::tagger;
use PLN::PT::api::dep_parser;
use PLN::PT::api::morph_analyzer;
use PLN::PT::api::stopwords;
use PLN::PT::api::actants;
use PLN::PT::api::tf;

our $VERSION = '0.1';

# env configuration
my $TMPDIR = config->{'TMPDIR'};
my $FL4BIN = config->{'FL4BIN'};
my $FL4CFG = config->{'FL4CFG'};

# home
get '/' => sub { return 'PLN::PT::api -- http://pln.pt'; };

# routes
get  '/morph_analyzer/*' => \&PLN::PT::api::morph_analyzer::route;
get  '/stopwords'        => \&PLN::PT::api::stopwords::route;
post '/tokenizer'        => \&PLN::PT::api::tokenizer::route;
post '/tagger'           => \&PLN::PT::api::tagger::route;
post '/dep_paser'        => \&PLN::PT::api::dep_paser::route;
post '/actants'          => \&PLN::PT::api::actants::route;
post '/tf'               => \&PLN::PT::api::tf::route;

true;

