package PLN::PT::api;
use Dancer2;
use PLN::PT::api::utils;
use PLN::PT::api::tokenizer;
use PLN::PT::api::tagger;
use PLN::PT::api::dep_parser;
use PLN::PT::api::morph_analyzer;
use PLN::PT::api::stopwords;
use PLN::PT::api::actants;
use PLN::PT::api::tf;

our $VERSION = '0.1';

BEGIN {
  mkdir config->{TMPDIR} unless -d config->{TMPDIR};
};


# home
get '/' => sub { redirect "http://pln.pt" };

# routes
get  '/morph_analyzer/*' => \&PLN::PT::api::morph_analyzer::route;
get  '/stopwords'        => \&PLN::PT::api::stopwords::route;
post '/tokenizer'        => \&PLN::PT::api::tokenizer::route;
post '/tagger'           => \&PLN::PT::api::tagger::route;
post '/dep_paser'        => \&PLN::PT::api::dep_paser::route;
post '/actants'          => \&PLN::PT::api::actants::route;
post '/tf'               => \&PLN::PT::api::tf::route;

true;

