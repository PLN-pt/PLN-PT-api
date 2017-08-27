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

# POST /tf
post '/tf' => sub {
  my $text = request->body;
  my $options = PLN::PT::api::utils::handle_opts();

  my $i = File::Temp->new( DIR => $TMPDIR );
  my $o = File::Temp->new( DIR => $TMPDIR );
  my ($input, $output) = ($i->filename, $o->filename);

  path($input)->spew_raw($text);
  my ($raw, $json) = PLN::PT::api::tagger::tagger($input, $output, {ner => 1});

  my $ct = 'application/json';
  $ct = 'plain/text' if ($options->{output} eq 'raw');
  content_type "$ct; charset='utf8'";

  my $data = PLN::PT::api::utils::my_decode($json);
  my $tf = {};
  my $stopwords = _stopwords('PT');
  foreach (@$data) {
    my $t;
    if ($options->{term} eq 'lemma') {
      $t = $_->[1];
    }
    else {
      $t = $_->[0];
    }

    # use form for 'conjunctions'
    $t = $_->[0] if ($_->[2] =~ m/\+/);
    # use form for dates
    $t = $_->[0] if ($_->[2] =~ m/^W/);

    # $t = lc($t) unless $_->[2] =~ m/^NP/; FIXME
    next if $_->[2] =~ m/^F/;
    if ($options->{stopwords}) {
      next if grep {$_ eq lc($t)} @$stopwords;
    }

    $tf->{$t}++;
  }

  return PLN::PT::api::utils::my_encode($tf);
};

true;

