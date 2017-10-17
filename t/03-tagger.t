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

my $r = $test->request( POST '/tagger',
          Content => Encode::encode_utf8('A Maria tem razão.') );
my $data = decode_json($r->content);

ok( scalar(@$data) == 5, 'sentence has 5 tokens' );
ok( $data->[0]->{form} eq 'A',          '1st token form is "A"' );
like($data->[0]->{prob}, qr/^0\.6\d+$/, '1st token prob is around 0.6' );
ok( $data->[0]->{lemma} eq 'o',         '1st token lemma is "0"' );
like( $data->[0]->{pos}, qr/^D/,        '1st token pos is a determinant' );
ok( $data->[-1]->{form} eq '.',         '5th token form is "."' );
like($data->[-1]->{prob}, qr/^1$/,      '5th token prob is 1' );
ok( $data->[-1]->{lemma} eq '.',        '5th token lemma is "."' );
like( $data->[-1]->{pos}, qr/^Fp$/,     '5th token pos is "Fp"' );

done_testing();

