package PLN::PT::api::stopwords;
use Dancer2 appname => 'PLN::PT::api';
use Lingua::StopWords qw/getStopWords/;

use PLN::PT::api::utils;
use utf8::all;

sub route {
  content_type "application/json; charset='utf8'";

  # FIXME get lang from options
  return to_json(stopwords('PT'));
};

sub stopwords {
  my ($lang) = @_;

  my $stopwords = getStopWords($lang, 'UTF-8');

  return [keys %$stopwords];
}

true;

