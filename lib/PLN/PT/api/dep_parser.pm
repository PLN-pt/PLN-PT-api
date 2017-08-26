package PLN::PT::api;
use Dancer2 appname => 'PLN::PT::api';
use File::Temp;
use Path::Tiny;

use PLN::PT::api::utils;

# env configuration
my $TMPDIR = config->{'TMPDIR'};
my $FL4BIN = config->{'FL4BIN'};
my $FL4CFG = config->{'FL4CFG'};

# POST /dep_parser
sub route {
  my $text = request->body;
  my $options = PLN::PT::api::utils::handle_opts();

  my $json = get_dep_tree($text);
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
}

sub get_dep_tree {
  my ($text) = @_;
  my $r;

  my $i = File::Temp->new( DIR => $TMPDIR, UNLINK => 0 );
  my $input = $i->filename;
  path($input)->spew_raw($text);

  # FIXME
  $r = `curl -H "Content-Type:text/plain" -s --data-binary \@$input http://127.0.0.1:7788`;

  return $r;
}

true;

