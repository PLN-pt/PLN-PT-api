package PLN::PT::api::dep_parser;
use Dancer2 appname => 'PLN::PT::api';
use File::Temp;
use Path::Tiny;

use PLN::PT::api::utils;

use utf8::all;

# env configuration
my $TMPDIR = config->{'TMPDIR'};
my $SYNTAXNET_WRAPPER = config->{'SYNTAXNET'}->{'WRAPPER'};
my $SYNTAXNET_BACKEND = config->{'SYNTAXNET'}->{'BACKEND'};

# POST /dep_parser
sub route {
  my $text = request->body;
  my $options = PLN::PT::api::utils::handle_opts();

  my $raw = _get_dep_tree($text);

  my @final;
  for my $line (split /\n+/, $raw) {
    push @final, [split /\s+/, $line];
  }

  if ($options->{output} eq 'raw') {
    content_type "text/plain; charset='utf8'";
    return $raw;
  }
  if ($options->{output} eq 'json') {
    content_type "application/json; charset='utf8'";
    return encode_json([@final]);
  }
}

sub _get_dep_tree {
  my ($text) = @_;
  my $r;

  my $i = File::Temp->new( DIR => $TMPDIR, UNLINK => 0 );
  my $input = $i->filename;
  path($input)->spew_raw($text);

  # get dependecy tree from syntaxnet backend
  $r = `$SYNTAXNET_WRAPPER $SYNTAXNET_BACKEND $input`;

  return $r;
}

true;

