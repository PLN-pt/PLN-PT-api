package PLN::PT::api::morph_analyzer;
use Dancer2 appname => 'PLN::PT::api';
use File::Temp;
use Path::Tiny;
use Lingua::Jspell;

use PLN::PT::api::utils;
use utf8::all;

our $VERSION = '0.1';

# env configuration
my $TMPDIR = config->{'TMPDIR'};
my $FL4BIN = config->{'FL4BIN'};
my $FL4CFG = config->{'FL4CFG'};

sub route {
  my ($word) = splat;
  my $options = PLN::PT::api::utils::handle_opts();

  my $i = File::Temp->new( DIR => $TMPDIR, EXLOCK => 0 );
  my $o = File::Temp->new( DIR => $TMPDIR, EXLOCK => 0 );
  my ($input, $output) = ($i->filename, $o->filename);

  path($input)->spew_utf8($word);
  my ($raw, $json) = morph_analyzer($input, $output, $options);

  my $ct = 'application/json';
  $ct = 'plain/text' if ($options->{output} eq 'raw');

  content_type "$ct; charset='utf8'";
  if ($options->{output} eq 'raw') {
    return $raw;
  }
  else {
    return $json;
  }
}


# POST /word_analysis
post '/word_analysis' => sub {
  my $text = request->body;
  my $options = PLN::PT::api::utils::handle_opts();;
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

sub morph_analyzer {
  my ($input, $output, $options) = @_;
  my ($raw, $json);

  if ($options->{backend} eq 'jspell') {
    my $dict = Lingua::Jspell->new('pt');

    my $r = [$dict->fea(path($input)->slurp)];
    $json = PLN::PT::api::utils::my_encode($r);
    return ('', $json);
  }

  if ($options->{backend} eq 'fl4') {
    my $command = PLN::PT::api::utils::fl4_command($options->{lang});
    my $r = `$command --outlv morfo < $input > $output`;

    # raw output
    $raw = path($output)->slurp;
    $raw =~ s/^\s*\n//mg;

    # json output
    my ($word,@data) = split /\s/, $raw;
    my @analysis = ();
    while (@data) {
      push @analysis, {
          lemma    => $data[0],
          analysis => $data[1],
          prob     => $data[2]
        };
      @data = @data[3..$#data];
    }
    $json = PLN::PT::api::utils::my_encode([@analysis]);

    return ($raw, $json);
  }
}

true;

