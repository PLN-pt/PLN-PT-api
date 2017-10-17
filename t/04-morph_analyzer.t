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

my $r = $test->request( GET '/morph_analyzer/cavalgar' );
my $data = decode_json($r->content);

ok( scalar(@$data) == 5, 'sentence has 5 tokens' );
like( $data->[0]->{pos}, qr/^V/ ,         '1st token is a verb' );
like( $data->[0]->{prob}, qr/^0\.5\d+$/, '1st token prob is around 0.5' );
ok( $data->[0]->{lemma} eq 'cavalgar',   '1st token lemma is "cavalgar"' );

done_testing();

