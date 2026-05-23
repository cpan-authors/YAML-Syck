use strict;
use warnings;
use Test::More tests => 18;
use YAML::Syck qw(Dump Load);

# Pure NV (float) values should be emitted unquoted so they roundtrip
# correctly as numbers.  Previously, only IV (integer) values were
# unquoted; NV values were single-quoted, turning them into strings.

# --- YAML ---

{
    my $out = Dump({ val => 3.14 });
    like( $out, qr/val: 3\.14\b/, "NV 3.14 emitted unquoted" );
    unlike( $out, qr/'3\.14'/, "NV 3.14 not single-quoted" );
}

{
    my $out = Dump({ val => -0.5 });
    like( $out, qr/val: -0\.5\b/, "negative NV emitted unquoted" );
}

{
    my $out = Dump({ val => 100.0 });
    like( $out, qr/val: 100\b/, "NV 100.0 emitted unquoted" );
}

{
    my $out = Dump([ 1.5, 2.5, 3.5 ]);
    like( $out, qr/- 1\.5\b/, "NV in sequence emitted unquoted" );
}

# Integers should still work
{
    my $out = Dump({ val => 42 });
    like( $out, qr/val: 42\b/, "IV still emitted unquoted" );
}

# Strings that look like floats should still be quoted (POK-only)
{
    my $str = "3.14";
    my $out = Dump({ val => $str });
    like( $out, qr/val: '?3\.14/, "string '3.14' handled (not NV)" );
}

# Roundtrip with ImplicitTyping
{
    local $YAML::Syck::ImplicitTyping = 1;

    is( Load(Dump(3.14)),   3.14,   "float 3.14 roundtrips" );
    is( Load(Dump(-0.5)),   -0.5,   "float -0.5 roundtrips" );
    is( Load(Dump(1e10)),   1e10,   "float 1e10 roundtrips" );
    is( Load(Dump(0.001)),  0.001,  "float 0.001 roundtrips" );
}

# --- JSON ---

SKIP: {
    eval { require JSON::Syck };
    skip "JSON::Syck not available", 7 if $@;

    {
        my $out = JSON::Syck::Dump({ val => 3.14 });
        like( $out, qr/3\.14/,     "JSON: NV 3.14 present" );
        unlike( $out, qr/"3\.14"/, "JSON: NV 3.14 not quoted as string" );
    }

    {
        my $out = JSON::Syck::Dump({ val => -0.5 });
        like( $out, qr/-0\.5/, "JSON: negative NV present" );
    }

    {
        my $out = JSON::Syck::Dump([ 1.5, 2.5 ]);
        like( $out, qr/1\.5/, "JSON: NV in array" );
    }

    # JSON roundtrip
    {
        my $data = { pi => 3.14159, neg => -2.5, zero => 0.0 };
        my $json = JSON::Syck::Dump($data);
        my $back = JSON::Syck::Load($json);
        is( $back->{pi},   3.14159, "JSON: float pi roundtrips" );
        is( $back->{neg},  -2.5,   "JSON: negative float roundtrips" );
        is( $back->{zero}, 0,      "JSON: zero float roundtrips" );
    }
}
