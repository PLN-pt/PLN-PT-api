use strict;
use warnings;
use Test::More;
use Plack::Test;
use HTTP::Request::Common;

use PLN::PT::api;

my $test = Plack::Test->create( PLN::PT::api->to_app );

my $r = $test->request( GET '/' );
is $r->header('Location') => "http://pln.pt";

done_testing();

