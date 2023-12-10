use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib/perl";

use Test::Most;
use JSON;

use_ok 'ProtoHacker::Main';
use_ok 'ProtoHacker::Util';

use ProtoHacker::Util qw(
    is_strict_numeric
    true false
);

use ProtoHacker::Main qw(
    validate_request
    set_STRICT_NUMERIC
);

ok( is_strict_numeric(123) , "123 is a strict numeric");
ok( ! is_strict_numeric('123') , "'123' is not a strict numeric");

set_STRICT_NUMERIC(false);

# Test validate_request

throws_ok { validate_request() } qr/Undefined Request/,
    "undef request";

my $req = { number => 1001 };
throws_ok { validate_request($req) } qr/Missing method/,
    "missing request 'method'";

$req = { method => "blah", number => 1001 };
throws_ok { validate_request($req) } qr/method field is not 'isPrime'/,
    "request 'method' is not 'isPrime'";

$req = { method => "isPrime" };
throws_ok { validate_request($req) } qr/number field is not defined/,
    "request 'number' is not defined (1)";

$req = { method => "isPrime", number => undef };
throws_ok { validate_request($req) } qr/number field is not defined/,
    "request 'number' is not defined (2)";

$req = { method => "isPrime", number => "blahahah" };
throws_ok { validate_request($req) } qr/number field is not numeric/,
    "request 'number' is not numeric";

$req = { method => "isPrime", number => JSON::true };
throws_ok { validate_request($req) } qr/number field is a json boolean/,
    "request 'number' is json boolean";


# Stringified number testing ...

$req = { method => "isPrime", number => "101" };
lives_ok { validate_request($req) }
    'number field is not checked for strictness';

set_STRICT_NUMERIC(true);

throws_ok { validate_request($req) } qr/number field is not a strict numeric/,
    "request 'number' is not a strict numeric";


my $json_req = '{"method":"isPrime","number":10112345678912345678912345678912825356353727272799999999999999999999999999999999999999999999999999999999999999}';
$req = decode_json($json_req);

throws_ok { validate_request($req) } qr/number field is not a strict numeric/,
    "request HUGE 'number' is not a strict numeric";


$json_req = '{"method":"isPrime","number":10112345678912345678912345678912825356353727272799999999999999999999999999999999999999999999999999999999999999,"bignumber":true}';
$req = decode_json($json_req);

lives_ok { validate_request($req) }
    "request HUGE 'number' is identified as a bignumber";


$json_req = '{"method":"isPrime","number":"10112345678912345678912345678912825356353727272799999999999999999999999999999999999999999999999999999999999999","bignumber":true}';
$req = decode_json($json_req);

lives_ok { validate_request($req) }
    "request HUGE 'number' is identified as a bignumber";

done_testing();

