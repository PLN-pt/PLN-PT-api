use strict;
use warnings;
use Test::More;
use Plack::Test;
use HTTP::Request::Common;

use PLN::PT::api;

my $test = Plack::Test->create( PLN::PT::api->to_app );

my $r = $test->request( GET '/' );
ok( $r->is_success, 'GET / - successful request' );
is( $r->content, 'PLN::PT::api -- http://pln.pt', 'GET / - correct content' );

$r = $test->request( POST '/tokenizer', Content => 'A Maria tem razão.' );
my $data = _my_decode($r->content);
ok( scalar(@$data) == 5, 'sentence has 5 tokens' );
ok( $data->[0] eq 'A', 'first token in "A"' );
ok( $data->[-1] eq '.', 'last token in "."' );

$r = $test->request( POST '/tagger', Content => 'A Maria tem razão.' );
$data = _my_decode($r->content);
ok( scalar(@$data) == 5, 'sentence has 5 tokens' );
ok( $data->[0]->[1] eq 'o', 'first token lemma is "o"' );
ok( $data->[0]->[2] eq 'DA0FS0', 'first token tag is "DA0FS0"' );
ok( $data->[-1]->[1] eq '.', 'last token lemma is "."' );
ok( $data->[-1]->[2] eq 'Fp', 'last token tag is "Fp"' );

done_testing();

sub _my_decode {
  my $json = shift;

  return JSON::MaybeXS->new(utf8 => 1)->decode($json);
}

