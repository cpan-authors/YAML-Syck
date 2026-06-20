use strict;
use warnings;
use Test::More tests => 8;
use JSON::Syck qw(DumpInto Dump);

# Regression: DumpInto called multiple times on the same buffer used to
# re-run the JSON postprocessor on already-compacted output, eating value
# characters after ':' and ','.

{
    my $buf;
    DumpInto(\$buf, {a => 1});
    is($buf, '{"a":1}', 'first DumpInto produces correct JSON');

    DumpInto(\$buf, {b => 2});
    is($buf, '{"a":1}{"b":2}',
       'second DumpInto appends without corrupting first');
}

{
    my $buf;
    DumpInto(\$buf, {name => "hello", val => 42});
    DumpInto(\$buf, {arr => [1, 2, 3]});
    like($buf, qr/"val":42/, 'integer value survives multi-append');
    like($buf, qr/\[1,2,3\]/, 'array value survives multi-append');
}

{
    my $buf;
    for my $i (1 .. 5) {
        DumpInto(\$buf, {n => $i});
    }
    my $count = () = $buf =~ /\{"n":\d\}/g;
    is($count, 5, 'five successive DumpInto calls all intact');
}

# Pre-existing content is preserved
{
    my $buf = "PREFIX";
    DumpInto(\$buf, {x => "y"});
    is($buf, 'PREFIX{"x":"y"}', 'pre-existing content preserved');
}

# Colons and commas inside string values are not stripped
{
    my $buf;
    DumpInto(\$buf, {k => "a: b, c"});
    DumpInto(\$buf, {k2 => "d: e"});
    like($buf, qr/"a: b, c"/, 'colon/comma inside string preserved (first)');
    like($buf, qr/"d: e"/,    'colon/comma inside string preserved (second)');
}
