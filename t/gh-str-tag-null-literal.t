use strict;
use warnings;
use Test::More tests => 16;
use YAML::Syck;

# Explicit !!str tag must always produce a string, even when the value
# is a YAML null literal (~).  Before this fix, !!str ~ returned undef
# because the null-literal check ran regardless of the explicit tag.

$YAML::Syck::ImplicitTyping = 1;

# Core bug: !!str ~ must be the string "~", not undef
{
    my $result = Load("!!str ~\n");
    is( $result, '~', '!!str ~ produces string "~"' );
    ok( defined $result, '!!str ~ is defined (not undef)' );
}

# !!str with other null-adjacent values
{
    is( Load("!!str null\n"), 'null', '!!str null produces string "null"' );
    is( Load("!!str ''\n"),   '',     '!!str with empty quotes produces empty string' );
}

# !!str with values that would otherwise be typed
{
    is( Load("!!str true\n"),  'true',  '!!str true produces string "true"' );
    is( Load("!!str false\n"), 'false', '!!str false produces string "false"' );
    is( Load("!!str 42\n"),    '42',    '!!str 42 produces string "42"' );
    is( Load("!!str 3.14\n"),  '3.14',  '!!str 3.14 produces string "3.14"' );
    is( Load("!!str .inf\n"),  '.inf',  '!!str .inf produces string ".inf"' );
}

# Plain ~ without tag must still be undef
{
    my $result = Load("~\n");
    ok( !defined $result, 'plain ~ is still undef' );
}

# !!null must still produce undef
{
    ok( !defined Load("!!null ~\n"),    '!!null ~ is undef' );
    ok( !defined Load("!!null null\n"), '!!null null is undef' );
}

# !!str ~ inside a mapping
{
    my $data = Load("key: !!str ~\n");
    is( ref $data, 'HASH', '!!str ~ in map: result is a hash' );
    is( $data->{key}, '~', '!!str ~ in map: value is string "~"' );
}

# !!str ~ inside a sequence
{
    my $data = Load("- !!str ~\n");
    is( ref $data, 'ARRAY', '!!str ~ in seq: result is an array' );
    is( $data->[0], '~', '!!str ~ in seq: value is string "~"' );
}
