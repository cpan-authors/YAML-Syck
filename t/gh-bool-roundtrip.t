use strict;
use warnings;
use Test::More;
use Config;
use YAML::Syck qw(Dump Load);

BEGIN {
    if ($] < 5.035004) {
        plan skip_all => "SvIsBOOL requires Perl 5.36+";
    }
}

plan tests => 16;

# Perl 5.36+ provides native booleans (!!1 is PL_sv_yes with SvIsBOOL).
# The emitter should serialize them as YAML true/false (or JSON true/false),
# not as "1"/'' which are string/number representations.

# --- YAML ---

{
    my $yes = !!1;
    my $out = Dump({ val => $yes });
    like $out, qr/val: true\b/, 'boolean true emitted as YAML true';
    unlike $out, qr/val: 1\b/, 'boolean true NOT emitted as integer 1';
}

{
    my $no = !!0;
    my $out = Dump({ val => $no });
    like $out, qr/val: false\b/, 'boolean false emitted as YAML false';
    unlike $out, qr/val: ''/, 'boolean false NOT emitted as empty string';
}

# Roundtrip with ImplicitTyping
{
    local $YAML::Syck::ImplicitTyping = 1;
    my $yes = !!1;
    my $rt = Load(Dump($yes));
    ok $rt, 'boolean true roundtrips to truthy value';

    my $no = !!0;
    $rt = Load(Dump($no));
    ok !$rt, 'boolean false roundtrips to falsy value';
}

# Booleans inside arrays
{
    my $out = Dump([ !!1, !!0 ]);
    like $out, qr/- true\b/, 'true in array';
    like $out, qr/- false\b/, 'false in array';
}

# Non-booleans still use existing behavior
{
    my $out = Dump({ val => 1 });
    like $out, qr/val: 1\b/, 'plain integer 1 unchanged';
}

{
    my $out = Dump({ val => "" });
    like $out, qr/val: ''/, 'empty string unchanged';
}

# --- JSON ---

SKIP: {
    eval { require JSON::Syck };
    skip "JSON::Syck not available", 6 if $@;

    {
        my $out = JSON::Syck::Dump({ val => !!1 });
        like $out, qr/true/, 'JSON: boolean true present';
        unlike $out, qr/"true"/, 'JSON: boolean true not quoted as string';
    }

    {
        my $out = JSON::Syck::Dump({ val => !!0 });
        like $out, qr/false/, 'JSON: boolean false present';
        unlike $out, qr/"false"/, 'JSON: boolean false not quoted as string';
    }

    # JSON roundtrip
    {
        my $data = JSON::Syck::Load('{"a":true,"b":false}');
        my $json = JSON::Syck::Dump($data);
        like $json, qr/true/, 'JSON: true survives Load/Dump roundtrip';
        like $json, qr/false/, 'JSON: false survives Load/Dump roundtrip';
    }
}
