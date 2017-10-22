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

is   scalar(@$data)       => 5              => 'sentence has 5 tokens';
is   $data->[0]->{form}   => 'A'            => '1st token form is "A"';
like $data->[0]->{prob}   =>  qr/^0\.6\d+$/ => '1st token prob is around 0.6' ;
is   $data->[0]->{lemma}  => 'o'            => '1st token lemma is "o"' ;
like $data->[0]->{pos}    => qr/^D/         => '1st token pos is a determinant' ;

is   $data->[-1]->{form}  => '.'            => '5th token form is "."' ;
like $data->[-1]->{prob}  =>, qr/^1$/       => '5th token prob is 1' ;
is   $data->[-1]->{lemma} => '.'            => '5th token lemma is "."' ;
like $data->[-1]->{pos}   => qr/^Fp$/       => '5th token pos is "Fp"' ;

ok   !exists($data->[1]{senses})            => "There isn't a senses attribute";

# Now with sense tagging

$r = $test->request( POST '/tagger?sense=ukb',
		     Content => Encode::encode_utf8('A Maria tem razão.') );
$data = decode_json($r->content);


is   scalar(@$data)             => 5             => 'sentence still has 5 tokens';
ok   exists($data->[3]{senses})                  => "there is a senses attribute";
like $data->[3]{senses}         => qr!\d-[vnra]! => "senses attribute matches";

done_testing();

