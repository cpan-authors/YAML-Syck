use strict;
use warnings;
use Test::More tests => 8;
use YAML::Syck;

# GH #27 / RT 23850: YAML_ITRANSFER (non-specific tag '!') before
# block scalar indicators ('>-', '|-', '>', '|') caused a parse error.

{
    my $out = eval { Load("---\n- ! >-\n") };
    is( $@, '', '! >- parses without error' );
    is_deeply( $out, [''], '! >- returns empty string in array' );
}

{
    my $out = eval { Load("---\n- ! |-\n") };
    is( $@, '', '! |- parses without error' );
    is_deeply( $out, [''], '! |- returns empty string in array' );
}

{
    my $out = eval { Load("---\n- ! >\n  hello\n") };
    is( $@, '', '! > with content parses without error' );
    is_deeply( $out, ["hello\n"], '! > folds content correctly' );
}

{
    my $out = eval { Load("---\n- ! |\n  hello\n") };
    is( $@, '', '! | with content parses without error' );
    is_deeply( $out, ["hello\n"], '! | preserves content literally' );
}
