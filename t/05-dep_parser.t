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

my $r = $test->request( POST '/dep_parser',
          Content => Encode::encode_utf8('A Maria tem razão .') );
my $data = decode_json($r->content);

ok( scalar(@$data) == 5, 'sentence has 5 tokens' );
ok( $data->[0]->{id} eq '1',                 '1st token id is "1"' );
ok( $data->[0]->{form} eq 'A',               '1st token form is "A"' );
ok( $data->[0]->{lemma} eq '_',              '1st token lemma is "_"' );
ok( $data->[0]->{upostag} eq 'DET',          '1st token upostag is "DET"' );
ok( split(/\|/, $data->[0]->{xpostag}) == 4, '1st token has 4 xpostags' );
ok( split(/\|/, $data->[0]->{feats}) == 8,   '1st token has 8 feats' );
ok( $data->[0]->{head} eq '2',               '1st token head is "2"' );
ok( $data->[0]->{deprel} eq 'det',           '1st token deprel is "det"' );
ok( $data->[0]->{deps} eq '_',               '1st token deps is "_"' );
ok( $data->[0]->{misc} eq '_',               '1st token misc is "_"' );
ok( $data->[-1]->{id} eq '5',                 '5th token id is "5"' );
ok( $data->[-1]->{form} eq '.',               '5th token form is "."' );
ok( $data->[-1]->{lemma} eq '_',              '5th token lemma is "_"' );
ok( $data->[-1]->{upostag} eq 'PUNCT',        '5th token upostag is "PUNCT"' );
ok( split(/\|/, $data->[-1]->{xpostag}) == 1, '5th token has 1 xpostags' );
ok( split(/\|/, $data->[-1]->{feats}) == 1,   '5th token has 1 feat' );
ok( $data->[-1]->{head} eq '3',               '5th token head is "3"' );
ok( $data->[-1]->{deprel} eq 'punct',         '5th token deprel is "punct"' );
ok( $data->[-1]->{deps} eq '_',               '5th token deps is "_"' );
ok( $data->[-1]->{misc} eq '_',               '5th token misc is "_"' );

done_testing();

