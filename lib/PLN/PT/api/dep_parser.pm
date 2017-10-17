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

  my @analysis;
  for my $line (split /\n+/, $raw) {
    my @l = split /\s+/, $line;
    push @analysis, {
        id      => $l[0],
        form    => $l[1],
        lemma   => $l[2],
        upostag => $l[3],
        xpostag => $l[4],
        feats   => $l[5],
        head    => $l[6],
        deprel  => $l[7],
        deps    => $l[8],
        misc    => $l[9],
      };
  }

  if ($options->{output} eq 'raw') {
    content_type "text/plain; charset='utf8'";
    return $raw;
  }
  if ($options->{output} eq 'json') {
    content_type "application/json; charset='utf8'";
    return PLN::PT::api::utils::my_encode([@analysis]);
  }
}

sub _get_dep_tree {
  my ($text) = @_;
  my $r;

  my $i = File::Temp->new( DIR => $TMPDIR, UNLINK => 1 );
  my $input = $i->filename;
  path($input)->spew_raw($text);

  # get dependecy tree from syntaxnet backend
  $r = `$SYNTAXNET_WRAPPER $SYNTAXNET_BACKEND $input`;

  return $r;
}

true;

