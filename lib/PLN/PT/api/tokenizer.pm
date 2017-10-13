package PLN::PT::api::tokenizer;
use Dancer2 appname => 'PLN::PT::api';
use File::Temp;
use Path::Tiny;

use PLN::PT::api::utils;
use PLN::PT::api::tagger;

# env configuration
my $TMPDIR = config->{'TMPDIR'};
my $FL4BIN = config->{'FL4BIN'};
my $FL4CFG = config->{'FL4CFG'};

# POST /tokenizer
sub route {
  my $text = request->body;
  my $options = PLN::PT::api::utils::handle_opts();

  my $i = File::Temp->new( DIR => $TMPDIR, EXLOCK => 0 );
  my $o = File::Temp->new( DIR => $TMPDIR, EXLOCK => 0 );
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

  if ($options->{sentence}) {
    my ($raw, $json) = PLN::PT::api::tagger::tagger($input, $output, $options);
    my $data = PLN::PT::api::utils::my_decode($json);

    # hand split sentences
    my @final;
    my @curr = ();
    my $ignore_first = 1;
    for (reverse(@$data)) {
      if ($_->[2] =~ m/^(Fp|Fat|Fit)$/) {
        if ($ignore_first) {
          $ignore_first = 0;
          push @curr, $_->[0];
          next;
        }
        else {
          push @final, [reverse(@curr),$_->[0]];
          @curr = ();
        }
      }
      push @curr, $_->[0];
    }
    push @final, [reverse(@curr)] if scalar(@curr) > 0;
    for (@final) {
      $_ = join(' ', @$_);
    }
    @final = reverse(@final);

    $raw = join("\n", @final);
    $json = PLN::PT::api::utils::my_encode([@final]);

    return ($raw, $json);
  }

  my $outlv = 'token';

  my $command = PLN::PT::api::utils::fl4_command($options->{lang});
  my $r = `$command --outlv $outlv < $input > $output`;

  # raw output
  $raw = path($output)->slurp_raw;
  $raw =~ s/^\s*\n//mg unless ($options->{sentence});

  # json output
  my @data = split /\n/, $raw;
  @data = grep {!/^$/} @data;
  $json = PLN::PT::api::utils::my_encode([@data]);

  return ($raw, $json);
}

true;

