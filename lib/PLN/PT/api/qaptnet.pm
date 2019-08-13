package PLN::PT::api::qaptnet;
use Dancer2 appname => 'PLN::PT::api';

use PLN::PT::api::utils;
use utf8::all;

use LWP::UserAgent;

sub route {
  content_type "application/json; charset='utf8'";

  my $json = request->body;
  my $req = HTTP::Request->new(POST => config->{qaptnet_backend}.'/query');
  $req->header( 'Content-Type' => 'application/json' );
  $req->content($json);

  my $res = LWP::UserAgent->new->request($req);
  if ($res->is_success) {
    return $res->decoded_content;
  }
  else {
    print STDERR "Request to qaptnet backend failed.";
  }
}

true;

