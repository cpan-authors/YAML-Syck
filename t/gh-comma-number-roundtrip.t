use strict;
use warnings;
use Test::More tests => 20;
use YAML::Syck;

# Comma-grouped numbers: YAML 1.0 allows commas as digit separators
# (e.g. 1,000 → 1000).  Perl's looks_like_number() doesn't recognise
# commas, so the Dumper must still quote these strings to prevent the
# implicit resolver from stripping the commas on reload.

local $YAML::Syck::ImplicitTyping = 1;

my @comma_strings = (
    [ '1,000',       'integer with comma' ],
    [ '1,000,000',   'integer with two commas' ],
    [ '-1,000',      'negative comma integer' ],
    [ '+1,000',      'positive-sign comma integer' ],
    [ '1,000.5',     'float with comma' ],
    [ '10,000.123',  'float with comma and decimals' ],
    [ '1,00',        'non-standard comma grouping' ],
    [ '100,0',       'trailing comma group' ],
);

for my $t (@comma_strings) {
    my ( $str, $label ) = @$t;

    my $dumped = YAML::Syck::Dump($str);
    my $loaded = YAML::Syck::Load($dumped);

    is( $loaded, $str, "round-trip preserves $label ($str)" );
    like( $dumped, qr/['"]/, "Dump quotes $label ($str)" );
}

# Verify legitimate integers remain unquoted
for my $n ( 42, 0, -1, 999999999 ) {
    my $dumped = YAML::Syck::Dump($n);
    unlike( $dumped, qr/['"]/, "integer $n emitted unquoted" );
}
