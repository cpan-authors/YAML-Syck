use strict;
use warnings;
use Test::More;
use YAML::Syck;

# The !!bool explicit tag was silently ignored — values like "!!bool true"
# loaded as the plain string "true" instead of the boolean value 1.
# The fix adds a handler for the bare "bool" type_id alongside the existing
# "bool#yes" / "bool#no" handlers used by implicit typing.

plan tests => 29;

{
    local $YAML::Syck::ImplicitTyping = 0;

    # True values
    for my $v (qw( true True TRUE yes Yes YES y Y on On ON )) {
        my $loaded = Load("--- !!bool $v\n");
        ok( $loaded, "!!bool $v is true (ImplicitTyping off)" );
    }

    # False values
    for my $v (qw( false False FALSE no No NO n N off Off OFF )) {
        my $loaded = Load("--- !!bool $v\n");
        ok( !$loaded, "!!bool $v is false (ImplicitTyping off)" );
    }

    # Non-boolean value falls back to string
    my $garbage = Load("--- !!bool garbage\n");
    is( $garbage, 'garbage', '!!bool with non-boolean value returns string' );

    # In a mapping
    my $map = Load("---\nenabled: !!bool true\ndisabled: !!bool false\n");
    ok( $map->{enabled},  '!!bool true in mapping' );
    ok( !$map->{disabled}, '!!bool false in mapping' );

    # In a sequence
    my $seq = Load("---\n- !!bool yes\n- !!bool no\n");
    ok( $seq->[0],  '!!bool yes in sequence' );
    ok( !$seq->[1], '!!bool no in sequence' );
}

{
    local $YAML::Syck::ImplicitTyping = 1;

    # !!bool should override implicit typing
    my $loaded = Load("--- !!bool true\n");
    ok( $loaded, '!!bool true works with ImplicitTyping on' );

    my $loaded_false = Load("--- !!bool off\n");
    ok( !$loaded_false, '!!bool off works with ImplicitTyping on' );
}
