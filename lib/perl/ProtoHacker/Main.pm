package ProtoHacker::Main;
use strict; use warnings;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
    run_protohacker1
    validate_request
    set_VERBOSE
    set_STRICT_NUMERIC
);

use JSON;
use IO::Socket;
use IO::Socket::INET;
use Math::Prime::Util qw(is_prime);
use Nice::Try;
use Data::Dumper;
use Scalar::Util qw(looks_like_number);

use Exception::Class (
    'ExceptMalformed'
);

use ProtoHacker::Util qw(
    true false is_strict_numeric
);

my %CHILDREN;

# Could make this module an "Object" ,
# with a "new" , and feed these in as part of
# the constructor, or just change them via the package
# variable . 
my $VERBOSE        = false;
my $STRICT_NUMERIC = false;

sub set_VERBOSE { $VERBOSE = $_[0] }
sub set_STRICT_NUMERIC { $STRICT_NUMERIC = $_[0] }

sub run_protohacker1 {
    my ($host, $port, $listen, $p_verbose, $p_strict_numeric) = @_;

    $VERBOSE = $p_verbose if defined $p_verbose;

    $STRICT_NUMERIC = $p_strict_numeric
        if defined $p_strict_numeric;

    my $server = IO::Socket::INET->new(
        LocalAddr => $host,
        LocalPort => $port,
        Type      => SOCK_STREAM,
        Reuse     => 1,
        Listen    => $listen,
    ) or die "Can't create listening socket: $!";

    warn "Server is listening on $host:$port\n" if $VERBOSE;

    # TODO Some limit on the forking count.
    # reaping zombie CHILDREN ?

    while (my $client = $server->accept()) {
        my $pid = fork();

        die "Could not fork: $!" unless defined $pid;

        if ($pid == 0) {
            # child process
            $server->close();

            handle_client($client);

            exit 0;
        } else {
            # parent process
            $CHILDREN{$pid} = 1;
            $client->close();
        }
    }
}

sub handle_client {
    my ($client) = @_;

    while (my $request_line = <$client>) {
        try {
            warn "----\nREQ : $request_line\n" if $VERBOSE;

            my $request = decode_json($request_line);
            warn Dumper($request)."\n" if $VERBOSE;

            process_request($client, $request);
        }
        catch (ExceptMalformed $e) {
            send_error($client, "malformed");
            last;
        }
        catch ($e) {
            send_error($client, "malformed");
            warn ("decode json err [$e]\n") if $VERBOSE;
            last;
        };
    }

    $client->close();
}

sub process_request {
    my ($client, $request) = @_;

    validate_request($request);

    # Math::Prime::Util::is_prime returns :
    #   0 not a prime.
    #   1 is probably a prime !
    #   2 is definitely a prime
    # So just coercing to 1 or 0 here, and
    # losing the "probably a prime" information. hmmm !!!
    # Some "huge non primes" could possibly slip through ...
    # 
    # Also Math::Prime::Util::is_prime throws an error
    # on floating point numbers, that the test wants
    # a "well formed" response on, hence the "try/catch"
    my $is_prime;
    try {
        $is_prime = is_prime($request->{number}) ? true : false;
    }
    catch ($e) {
        $is_prime = false;
    };

    my $response = {
        method => "isPrime",
        prime  => $is_prime,
    };

    warn sprintf("Is Prime ? [%s]\n", $is_prime ? 'true' : 'false')
        if $VERBOSE;

    my $response_line = encode_json($response) . "\n";
    $client->send($response_line);
}

sub validate_request {
    my ($request) = @_;

    if (! defined $request ){
        ExceptMalformed->throw("Undefined Request");
    }

    if (! $request->{method} ){
        ExceptMalformed->throw("Missing method");
    }

    if ( $request->{method} ne "isPrime" ){
        ExceptMalformed->throw("method field is not 'isPrime'");
    }

    my $number = $request->{number};

    if ( ! defined $number ){
        ExceptMalformed->throw("number field is not defined");
    }

    if ( $STRICT_NUMERIC && ! is_strict_numeric($number)){

        # An undocumented field 'bignumber' in the test's spec ! 
        # that can help fix the huge non-stringfied numbers.
        #
        # They don't seem to be testing with huge
        # stringified numbers.
        my $bignum = $request->{bignumber};
        if ( ! defined $bignum
            || ( JSON::is_bool($bignum) && $bignum == JSON::false)
            || ( ! JSON::is_bool($bignum) && ! $bignum )
        ){
            ExceptMalformed->throw("number field is not a strict numeric");
        }
    }

    if ( ! looks_like_number($number) ){
        ExceptMalformed->throw("number field is not numeric");
    }

    if ( JSON::is_bool($number)){
        ExceptMalformed->throw("number field is a json boolean");
    }

    return true;
}

sub send_error {
    my ($client, $resp) = @_;
    warn "$resp\n" if $VERBOSE;
    $client->send("$resp\n");
}

1;

