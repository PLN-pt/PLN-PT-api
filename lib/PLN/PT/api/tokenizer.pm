package PLN::PT::api::tokenizer;
use Dancer2 appname => 'PLN::PT::api';
use File::Temp;
use Path::Tiny;

use PLN::PT::api::utils;

# env configuration
my $TMPDIR = config->{'TMPDIR'};
my $FL4BIN = config->{'FL4BIN'};
my $FL4CFG = config->{'FL4CFG'};

# POST /tokenizer
sub route {
  my $text = request->body;
  my $options = PLN::PT::api::utils::handle_opts();

  my $i = File::Temp->new( DIR => $TMPDIR );
  my $o = File::Temp->new( DIR => $TMPDIR );
  my ($input, $output) = ($i->filename, $o->filename);

  path($input)->spew_raw($text);
  my ($raw, $json) = tokenizer($input, $output, $options);

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

sub tokenizer {
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
    my $command = PLN::PT::api::utils::fl4_command($options->{lang});
    $r = `$command --outlv $outlv < $input > $output`;
    print "$command --outlv $outlv < $input > $output\n";
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
  $json = PLN::PT::api::utils::my_encode([@data]);

  return ($raw, $json);
}

true;

