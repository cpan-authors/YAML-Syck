use strict;
use warnings;
use Test::More tests => 14;

use JSON::Syck qw(Dump);

# Floating-point numbers must emit unquoted in JSON
is( Dump(3.14),    '3.14',    'float 3.14 emitted unquoted' );
is( Dump(-3.14),   '-3.14',   'negative float emitted unquoted' );
is( Dump(0.001),   '0.001',   'small float emitted unquoted' );

# Large integers (> 9 digits) must emit unquoted
is( Dump(10000000000),    '10000000000',    'large int emitted unquoted' );
is( Dump(9999999999999999), '9999999999999999', 'very large int emitted unquoted' );
is( Dump(-10000000000),   '-10000000000',   'large negative int emitted unquoted' );

# NaN and Inf are not valid JSON — emit as null
SKIP: {
    my $nan = 9e999 - 9e999;
    skip 'no NaN support', 1 unless $nan != $nan;
    is( Dump($nan), 'null', 'NaN emits as null' );
}

SKIP: {
    my $inf = 9e999;
    skip 'no Inf support', 2 unless $inf == $inf && $inf > 1e308;
    is( Dump($inf),  'null', 'Inf emits as null' );
    is( Dump(-$inf), 'null', '-Inf emits as null' );
}

# Strings that look like numbers must stay quoted
is( Dump("3.14"),  '"3.14"',  'string "3.14" stays quoted' );
is( Dump("1e10"),  '"1e10"',  'string "1e10" stays quoted' );
is( Dump("42"),    '"42"',    'string "42" stays quoted' );

# Numbers inside a data structure
is( Dump({pi => 3.14159}),    '{"pi":3.14159}',    'float in hash emitted unquoted' );
is( Dump([1, 2.5, "three"]),  '[1,2.5,"three"]',    'mixed array: nums unquoted, strings quoted' );
