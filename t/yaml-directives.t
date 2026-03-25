#!/usr/bin/perl
# yaml-directives.t
#
# Tests for YAML 1.0 directives:
#   - %YAML directive (version indicator)
#   - %TAG directive (tag shorthand)
#   - Legacy #YAML:1.0 header compat
#
# Spec reference: https://yaml.org/spec/1.0/#id2561449
#
# Note: The emitter can output "--- %YAML:1.0" when use_version=1
# (emitter.c line 381). The parser converts "#YAML:1.0" to "%YAML:1.0"
# (perl_syck.h line 802-804) for backwards compat with YAML.pm <= 0.35.

use strict;
use warnings;
use Test::More;
use YAML::Syck;

# --- Legacy #YAML:1.0 header ---

{
    my $yaml = "--- #YAML:1.0\nkey: value\n";
    my $data = Load($yaml);
    is( $data->{key}, 'value',
        'legacy #YAML:1.0 header is parsed correctly' );
}

# --- %YAML:1.0 header ---

{
    my $yaml = "--- \%YAML:1.0\nkey: value\n";
    my $data = Load($yaml);
    is( $data->{key}, 'value',
        '%YAML:1.0 header is parsed correctly' );
}

# --- Document without directive ---

{
    my $yaml = "---\nkey: value\n";
    my $data = Load($yaml);
    is( $data->{key}, 'value',
        'document without directive loads normally' );
}

# --- Headless mode (no --- header) ---

{
    local $YAML::Syck::Headless = 1;
    my $yaml = Dump({ key => 'value' });
    unlike( $yaml, qr/^---/m,
        'Headless mode suppresses --- header' );
    my $data = Load($yaml);
    is( $data->{key}, 'value',
        'headless output roundtrips' );
}

# --- Complex document with #YAML:1.0 header ---

{
    my $yaml = <<'YAML';
--- #YAML:1.0
name: test
items:
  - one
  - two
nested:
  key: value
YAML
    my $data = Load($yaml);
    is( $data->{name}, 'test', 'complex doc with #YAML:1.0 header' );
    is_deeply( $data->{items}, ['one', 'two'], 'sequence after directive' );
    is( $data->{nested}{key}, 'value', 'nested mapping after directive' );
}

# --- %TAG directive (not supported by parser) ---

TODO: {
    local $TODO = '%TAG directive parsing not supported by bundled libsyck';

    my $yaml = "%TAG ! tag:example.com,2000:\n---\n!foo bar\n";
    my $data = eval { Load($yaml) };
    # The parser treats %TAG as content rather than a directive,
    # so we check that the result is a scalar (not a misparse as a mapping key)
    ok( defined $data && !ref($data),
        '%TAG directive parsed correctly as directive, not content' );
}

done_testing();
