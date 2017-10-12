package PLN::PT::api::utils;
use Dancer2 appname => 'PLN::PT::api';

use JSON::MaybeXS;

# env configuration
my $FL4BIN = config->{'FL4BIN'};
my $FL4CFG = config->{'FL4CFG'};

sub fl4_command {
  my $lang = shift;
  $lang = 'pt' unless $lang;

  my $cfg = $FL4CFG->{uc($lang)};

  return "$FL4BIN -f $cfg ";
}

sub handle_opts {
  my $validator = {
      sense => sub { $_[0] =~ /^(?:no|none|all|mfs|ukb)$/ },
  };
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
      backend   => 'fl4',
      sense     => 'no',
    };

  for my $p (keys %$options) {
    if (param $p) {
      my $param = lc(param $p);
      $options->{$p} = $param if !exists($validator->{$p}) || $validator->{$p}($param);
    }
  }

  return $options;
}

sub my_encode {
  my ($data) = @_;

  my $o = JSON::MaybeXS->new(utf8 => 0);
  return $o->encode($data);
}

sub my_decode {
  my ($data) = @_;

  my $o = JSON::MaybeXS->new(utf8 => 0);
  return $o->decode($data);
}

sub get_body {
  my $body = request->body;

  $body =~ s/([\.\!\?]+)/ $1 /g;

  return $body;
}

true;
