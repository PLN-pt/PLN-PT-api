use strict;
use warnings;
use Test::More;
use Plack::Test;
use HTTP::Request::Common;

use PLN::PT::api;
use JSON::XS;
use Encode ();
use utf8::all;
use utf8;

my $test = Plack::Test->create( PLN::PT::api->to_app );

my $r = $test->request( POST '/tokenizer',
          Content => Encode::encode_utf8('A Maria tem razão.') );
my $data = decode_json($r->content);

ok( scalar(@$data) == 5, 'sentence has 5 tokens' );
ok( $data->[0] eq 'A',     '1st token in "A"' );
ok( $data->[1] eq 'Maria', '2nd token in "Maria"' );
ok( $data->[2] eq 'tem',   '3rd token in "tem"' );
ok( $data->[3] eq 'razão', '4th token in "razão"' );
ok( $data->[4] eq '.',     '5th token in "."' );

$r = $test->request( POST '/tokenizer?sentence=1',
  Content => Encode::encode_utf8('A Maria tem razão. A Maria tem razão.') );
$data = decode_json($r->content);

ok( scalar(@$data) == 2, 'content has 2 sentences' );

done_testing();

