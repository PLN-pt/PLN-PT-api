package PLN::PT::api::actants;
use Dancer2 appname => 'PLN::PT::api';
use Lingua::PT::Actants;

use PLN::PT::api::utils;

sub route {
  my $text = request->body;
  my $options = PLN::PT::api::utils::handle_opts();
  my $r;

  my $t = _get_dep_tree($text);
  my $o = Lingua::PT::Actants->new( conll => $t );
  my @cores = $o->acts_cores;
  my @syns = $o->acts_syns(@cores);

  # raw
  my $raw = $o->pp_acts_syntagmas(@syns) . $o->pp_acts_cores(@cores);

  # json
  my $data = { syntagmas => [@syns], cores => [@cores] };
  my $json = PLN::PT::api::utils::my_encode($data);

  if ($options->{output} eq 'raw') {
    content_type "text/plain; charset='utf8'";
    return $raw;
  }
  if ($options->{output} eq 'json') {
    content_type "application/json; charset='utf8'";
    return $json;
  }
}

true;

