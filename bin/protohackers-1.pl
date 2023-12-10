#!/usr/bin/perl
use strict; use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib/perl";

use ProtoHacker::Main qw(
    run_protohacker1
);

use Getopt::Long;

GetOptions ("port=i"            => \my $port,
            "host=s"            => \my $host,
            "listen-count=s"    => \my $listen,
            "verbose"           => \my $verbose,
            "strict-numeric"    => \my $strict_numeric,
            "help"              => \my $help,
            )
or die("Error in command line arguments . see --help\n");

if ( $help ) {

    ($help = <<"    EOHELP") =~ s/^ {4}//gm;
    Protohacker Problem 1
    See : https://protohackers.com/problem/1
    ----------------------
    Options are :

        --host , default of localhost

        --port , default of 9090

        --listen , default of 5

        --verbose , default of false.

        --strict-numeric , default of false.
            This is for using B module to see if JSON numbers
            really came in as strings (see the code)

        --help , this help !

    EOHELP

    die $help;
}

$host   //= 'localhost';
$port   //= 9090;
$listen //= 5;

run_protohacker1($host, $port, $listen, $verbose, $strict_numeric);
