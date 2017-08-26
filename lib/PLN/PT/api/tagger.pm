package PLN::PT::api::tagger;
use Dancer2 appname => 'PLN::PT::api';
use File::Temp;
use Path::Tiny;

use PLN::PT::api::utils;

# env configuration
my $TMPDIR = config->{'TMPDIR'};
my $FL4BIN = config->{'FL4BIN'};
my $FL4CFG = config->{'FL4CFG'};

# POST /tagger
sub route {
  my $text = request->body;
  my $options = PLN::PT::api::utils::handle_opts();

  my $i = File::Temp->new( DIR => $TMPDIR );
  my $o = File::Temp->new( DIR => $TMPDIR );
  my ($input, $output) = ($i->filename, $o->filename);

  path($input)->spew_raw($text);
  my ($raw, $json) = tagger($input, $output, $options);
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
}

sub tagger {
  my ($input, $output, $options) = @_;
  my ($raw, $json);

  my $opts;
  $opts  = $options->{ner} ?  ' --ner' : ' --noner';
  $opts .= $options->{rtk} ?  ' --rtk' : ' --nortk';

  my $command = PLN::PT::api::utils::fl4_command($options->{lang});
  my $r = `$command --outlv tagged $opts < $input > $output`;

  # raw output
  $raw = path($output)->slurp_raw;
  $raw =~ s/^\s*\n//mg;

  # json output
  my @data = split /\n/, $raw;
  @data = grep {!/^$/} @data;
  @data = map {[split /\s+/]} @data;
  $json = PLN::PT::api::utils::my_encode([@data]);

  return ($raw, $json);
}

true;

