use strict;
use warnings;
use Test::More tests => 11;

use YAML::Syck;

ok( YAML::Syck->VERSION );
is( Dump("Hello, world"),       "--- Hello, world\n" );
is( Load("--- Hello, world\n"), "Hello, world" );

# RT 34073 / GH #35 - "--\n" is valid YAML (plain scalar), not a parse error
{
    my $out = eval { Load("--\n") };
    is( $@, '', "Load of '--' does not die" );
    is( $out, '--', "Load of '--' returns plain scalar" );
}

TODO: {
    my $out = eval { Load("") };
    is( $out, undef, "Bad data fails load" );

    local $TODO = 'Load fails on empty string';
    isnt( $@, '', "Bad data dies on Load" );
}

TODO: {
    my $out = eval { Load("feefifofum\n\n\ndkjdkdk") };

    local $TODO = 'Load fails on empty string';
    isnt( $@, '', "Bad data dies on Load" );
    is( $out, undef, "Bad data fails load" );
}

{
    my $out = eval { Load("---\n- ! >-\n") };

    is( $@, '', "! >- (empty tag + block scalar) parses without error (RT 23850)" );
    is_deeply( $out, [''], "! >- returns array with empty string (RT 23850)" );
}
