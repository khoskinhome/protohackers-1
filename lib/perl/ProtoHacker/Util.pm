package ProtoHacker::Util;
use strict; use warnings;

use B;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
    true false
    is_strict_numeric
);

use Scalar::Util qw(looks_like_number);

sub true  (){1}
sub false (){0}

sub is_strict_numeric {
    my ($value) = @_;

    # This is "flaky" way of finding out.
    # other perl actions could convert what was an
    # "NV" or "IV" into a stringified "PV".
    #
    # So when using this, say to check things the JSON
    # parser has parsed, it needs to be called before
    # other operations could have changed Perl's internal
    # representation of the number
    #
    # This was all to pass the protohacker testcases of
    # numbers that came over stringified.
    # Perl was doing it's magic ,
    #  "if it looks like a number well then it is a number !"
    #
    # The protohacker test seemingly wants stringified numbers
    # to be detected as "not a number".
    #
    # Perl being perl, well it's a bit "loose" with it's "types".

    return false if ! looks_like_number($value);

    my $sv_obj = B::svref_2object(\$value);
    my $flags = $sv_obj->FLAGS;

    if ($flags & B::SVf_POK) {
        # PV, it's 'probably' a string.
        return false;
    }

    if ($flags & B::SVf_NOK) {
        # NV, it's a numeric.
        return true;
    }

    if ($flags & B::SVf_IOK) {
        # IV, it's an integer.
        return true;
    }

    return true;
}

1;

