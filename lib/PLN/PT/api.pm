package PLN::PT::api;
use Dancer2;
use JSON::MaybeXS;
use File::Temp;
use Path::Tiny;
use Lingua::Jspell;
use Lingua::PT::Actants;
use Encode qw/encode/;
use Lingua::PT::PLNbase;
use Lingua::StopWords qw/getStopWords/;

our $VERSION = '0.1';

# env configuration
my $TMPDIR = config->{'TMPDIR'};
my $FL4BIN = config->{'FL4BIN'};
my $FL4CFG = config->{'FL4CFG'};

get '/' => sub {
  return 'PLN::PT::api -- http://pln.pt';
};

# get /morph
get '/morph/*' => sub {
  my ($word) = splat;
  my $options = _handle_opts();

  my $i = File::Temp->new( DIR => $TMPDIR );
  my $o = File::Temp->new( DIR => $TMPDIR );
  my ($input, $output) = ($i->filename, $o->filename);

  path($input)->spew_raw($word);
  my ($raw, $json) = _morph($input, $output, $options);

  my $ct = 'application/json';
  $ct = 'plain/text' if ($options->{output} eq 'raw');

  content_type "$ct; charset='utf8'";
  if ($options->{output} eq 'raw') {
    return $raw;
  }
  else {
    return $json;
  }
};

# POST /tokenizer
post '/tokenizer' => sub {
  my $text = request->body;
  my $options = _handle_opts();

  my $i = File::Temp->new( DIR => $TMPDIR );
  my $o = File::Temp->new( DIR => $TMPDIR );
  my ($input, $output) = ($i->filename, $o->filename);

  path($input)->spew_raw($text);
  my ($raw, $json) = _tokenizer($input, $output, $options);

  my $ct = 'application/json';
  $ct = 'plain/text' if ($options->{output} eq 'raw');

  content_type "$ct; charset='utf8'";
  if ($options->{output} eq 'raw') {
    return $raw;
  }
  else {
    return $json;
  }
};

# POST /tagger
post '/tagger' => sub {
  my $text = request->body;
  my $options = _handle_opts();

  my $i = File::Temp->new( DIR => $TMPDIR );
  my $o = File::Temp->new( DIR => $TMPDIR );
  my ($input, $output) = ($i->filename, $o->filename);

  path($input)->spew_raw($text);
  my ($raw, $json) = _tagger($input, $output, $options);
  #my ($type, $data) = _tagger($input, $output, $options);

  my $ct = 'application/json';
  $ct = 'plain/text' if ($options->{output} eq 'raw');

  content_type "$ct; charset='utf8'";
  if ($options->{output} eq 'raw') {
    return $raw;
  }
  else {
    return $json;
  }
};

# POST /word_analysis
post '/word_analysis' => sub {
  my $text = request->body;
  my $options = _handle_opts();;
  my $r;

  my $dict = Lingua::Jspell->new('pt');
  $r = [$dict->fea($text)];

  # raw
  if ($options->{output} eq 'raw') {
   content_type "text/plain; charset='utf8'";
   return Dumper($r);
  }

  # json
  if ($options->{output} eq 'json') {
    content_type "application/json; charset='utf8'";
    return encode_json($r);
  }
};

# POST /dep_parser
post '/dep_parser' => sub {
  my $text = request->body;
  my $options = _handle_opts();

  my $json = _get_dep_tree($text);
  my $data = decode_json($json);

  # nrc
  my @final;
  for my $e (@$data) {
    my @ls;
    for (@$e) {
      push @ls, [$_->{id}, $_->{form}, '_', $_->{upostag}, $_->{xpostag}, $_->{feats}, $_->{head}, $_->{deprel}, '_', '_'];

    }
    push @final, [@ls];
  }
  if (scalar(@final) == 1) {
    @final = @{$final[0]};
  }

  # raw
  my @lines = ();
  foreach (@{$data->[0]}) {
    push @lines, join("\t",
      $_->{id}, $_->{form}, '_', $_->{upostag}, $_->{xpostag},
      $_->{feats}, $_->{head}, $_->{deprel}, '_', '_' );
  }
  my $raw = join("\n", @lines);

  if ($options->{output} eq 'raw') {
    content_type "text/plain; charset='utf8'";
    return $raw;
  }
  if ($options->{output} eq 'json') {
    content_type "application/json; charset='utf8'";
    return encode_json([@final]);
  }
};

post '/actants' => sub {
  my $text = request->body;
  my $options = _handle_opts();
  my $r;

  my $t = _get_dep_tree($text);
  my $o = Lingua::PT::Actants->new( conll => $t );
  my @cores = $o->acts_cores;
  my @syns = $o->acts_syns(@cores);

  # raw
  my $raw = $o->pp_acts_syntagmas(@syns) . $o->pp_acts_cores(@cores);

  # json
  my $data = { syntagmas => [@syns], cores => [@cores] };
  my $json = _my_encode($data);

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
  my $options = _handle_opts();

  my $i = File::Temp->new( DIR => $TMPDIR );
  my $o = File::Temp->new( DIR => $TMPDIR );
  my ($input, $output) = ($i->filename, $o->filename);

  path($input)->spew_raw($text);
  my ($raw, $json) = _tagger($input, $output, {ner => 1});

  my $ct = 'application/json';
  $ct = 'plain/text' if ($options->{output} eq 'raw');
  content_type "$ct; charset='utf8'";

  my $data = _my_decode($json);
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

  return _my_encode($tf);
};

# GET /stopwords
get '/stopwords' => sub {
  content_type "application/json; charset='utf8'";
  return to_json(_stopwords('PT'));
};

sub _tokenizer {
  my ($input, $output, $options) = @_;
  my ($raw, $json);

  my $outlv = 'token';
  $outlv = 'splitted' if ($options->{sentence}); # sentece split

  my $r;
  if ($options->{sentence}) {
    my @sentences = frases(path($input)->slurp_raw);
    path($output)->spew_raw(join("\n\n", @sentences));
  }
  else {
    my $command = _fl4_command($options->{lang});
    $r = `$command --outlv $outlv < $input > $output`;
  }

  # raw output
  $raw = path($output)->slurp_raw;
  $raw =~ s/^\s*\n//mg unless ($options->{sentence});

  # json output
  my @data;
  if ($options->{sentence}) {
    #@data = split /\n/, $raw;
    @data = split /\n\n*/m, $raw;
  }
  else {
    @data = split /\n/, $raw;
  }
  @data = grep {!/^$/} @data;
  $json = _my_encode([@data]);

  return ($raw, $json);
}

sub _tagger {
  my ($input, $output, $options) = @_;
  my ($raw, $json);

  my $opts;
  $opts  = $options->{ner} ?  ' --ner' : ' --noner';
  $opts .= $options->{rtk} ?  ' --rtk' : ' --nortk';

  my $command = _fl4_command($options->{lang});
  my $r = `$command --outlv tagged $opts < $input > $output`;

  # raw output
  $raw = path($output)->slurp_raw;
  $raw =~ s/^\s*\n//mg;

  # json output
  my @data = split /\n/, $raw;
  @data = grep {!/^$/} @data;
  @data = map {[split /\s+/]} @data;
  $json = _my_encode([@data]);

  return ($raw, $json);
}

sub _morph {
  my ($input, $output, $options) = @_;
  my ($raw, $json);

  my $command = _fl4_command($options->{lang});
  my $r = `$command --outlv morfo < $input > $output`;

  # raw output
  $raw = path($output)->slurp_raw;
  $raw =~ s/^\s*\n//mg;

  # json output
  my ($word,@data) = split /\s/, $raw;
  my @analysis = ();
  while (@data) {
    push @analysis, { lemma => $data[0], analysis => $data[1], prob => $data[2] };
    @data = @data[3..$#data];
  }
  $json = _my_encode([ $word, @analysis]);

  return ($raw, $json);
}



sub _fl4_command {
  my $lang = shift;
  $lang = 'pt' unless $lang;

  my $cfg = $FL4CFG->{uc($lang)};

  return "$FL4BIN -f $cfg ";
}

sub _handle_opts {

  # set defaults
  my $options = {
      lang      => 'pt',
      output    => 'json',
      use       => 'fl',
      ner       => 0,
      rtk       => 0,
      sentence  => 0,
      stopwords => 0,
      term      => 'form',
    };

  if (param 'lang') {
    $options->{lang} = lc(param 'lang');
  }
  if (param 'output') {
    $options->{output} = lc(param 'output');
  }
  if (param 'use') {
    $options->{use} = lc(param 'use');
  }
  if (param 'ner') {
    $options->{ner} = lc(param 'ner');
  }
  if (param 'rtk') {
    $options->{rtk} = lc(param 'rtk');
  }
  if (param 'sentence') {
    $options->{sentence} = lc(param 'sentence');
  }
  if (param 'stopwords') {
    $options->{stopwords} = lc(param 'stopwords');
  }
  if (param 'term') {
    $options->{term} = lc(param 'term');
  }

  return $options;
}

sub _get_dep_tree {
  my ($text) = @_;
  my $r;

  my $i = File::Temp->new( DIR => $TMPDIR, UNLINK => 0 );
  my $input = $i->filename;
  path($input)->spew_raw($text);

  # FIXME
  $r = `curl -H "Content-Type:text/plain" -s --data-binary \@$input http://127.0.0.1:7788`;

  return $r;
}

sub _stopwords {
  my ($lang) = @_;

  my $stopwords = getStopWords($lang, 'UTF-8');

  return [keys %$stopwords];
}

sub _my_encode {
  my ($data) = @_;

  my $o = JSON::MaybeXS->new(utf8 => 0);
  return $o->encode($data);
}

sub _my_decode {
  my ($data) = @_;

  my $o = JSON::MaybeXS->new(utf8 => 0);
  return $o->decode($data);
}

true;
