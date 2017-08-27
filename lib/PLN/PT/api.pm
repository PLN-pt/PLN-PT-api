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

our $VERSION = '0.1';

# env configuration
my $TMPDIR = config->{'TMPDIR'};
my $FL4BIN = config->{'FL4BIN'};
my $FL4CFG = config->{'FL4CFG'};

get '/' => sub {
  return 'PLN::PT::api -- http://pln.pt';
};

# POST /tokenizer
post '/tokenizer' => \&PLN::PT::api::tokenizer::route;

# POST /tagger
post '/tagger' => \&PLN::PT::api::tagger::route;

# GET /morph_analyzer
get '/morph_analyzer/*' => \&PLN::PT::api::morph_analyzer::route;

# POST /tagger
post '/dep_paser' => \&PLN::PT::api::dep_paser::route;

post '/actants' => sub {
  my $text = request->body;
  my $options = PLN::PT::api::utils::handle_opts();
  my $r;

  my $t = _get_dep_tree($text);
  my $o = Lingua::PT::Actants->new( conll => $t );
  my @cores = $o->acts_cores;
  my @syns = $o->acts_syns(@cores);

  # raw
  my $raw = $o->pp_acts_syntagmas(@syns) . $o->pp_acts_cores(@cores);

  # json
  my $data = { syntagmas => [@syns], cores => [@cores] };
  my $json = PLN::PT::api::utils::my_encode($data);

  if ($options->{output} eq 'raw') {
    content_type "text/plain; charset='utf8'";
    return $raw;
  }
  if ($options->{output} eq 'json') {
    content_type "application/json; charset='utf8'";
    return $json;
  }
};

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

# GET /stopwords
get '/stopwords' => sub {
  content_type "application/json; charset='utf8'";
  return to_json(_stopwords('PT'));
};

sub _stopwords {
  my ($lang) = @_;

  my $stopwords = getStopWords($lang, 'UTF-8');

  return [keys %$stopwords];
}

true;

