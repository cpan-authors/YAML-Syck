#!/usr/bin/perl
# yaml-merge-key.t
#
# Tests for YAML 1.0 merge key (<<):
#   - Basic merge from anchored mapping
#   - Multiple merges
#   - Override precedence (explicit keys win over merged keys)
#
# Spec reference: https://yaml.org/spec/1.0/ (merge key type)
# The merge key is recognized by implicit.c as type "merge".

use strict;
use warnings;
use Test::More;
use YAML::Syck;

$YAML::Syck::ImplicitTyping = 1;

# --- Basic merge ---
# Note: The << merge key is recognized by implicit.c but the Perl handler
# (perl_syck.h) stores it as a literal '<<' hash key rather than merging
# the referenced mapping's keys into the parent. This is a known limitation.

{
    my $yaml = <<'YAML';
---
defaults: &defaults
  color: red
  size: large

item:
  <<: *defaults
  name: widget
YAML
    my $data = Load($yaml);
    is( $data->{item}{name}, 'widget',
        'merge: explicit key present' );

    TODO: {
        local $TODO = 'merge key << not implemented in Perl handler — stores as literal key';
        is( $data->{item}{color}, 'red',
            'merge: inherited key from anchor' );
        is( $data->{item}{size}, 'large',
            'merge: second inherited key from anchor' );
    }
}

# --- Merge with override ---

{
    my $yaml = <<'YAML';
---
defaults: &defaults
  color: red
  size: large

item:
  <<: *defaults
  color: blue
  name: widget
YAML
    my $data = Load($yaml);
    is( $data->{item}{color}, 'blue',
        'merge override: explicit key wins over merged key' );
    is( $data->{item}{name}, 'widget',
        'merge override: additional explicit key present' );

    TODO: {
        local $TODO = 'merge key << not implemented in Perl handler — stores as literal key';
        is( $data->{item}{size}, 'large',
            'merge override: non-overridden key still inherited' );
    }
}

# --- Merge from multiple mappings ---

{
    my $yaml = <<'YAML';
---
base1: &base1
  a: 1
  b: 2

base2: &base2
  c: 3
  d: 4

combined:
  <<: [*base1, *base2]
  e: 5
YAML
    my $data = Load($yaml);

    is( $data->{combined}{e}, 5, 'multi-merge: explicit key present' );

    TODO: {
        local $TODO = 'merge from sequence of mappings not supported';
        is( $data->{combined}{a}, 1, 'multi-merge: key from first base' );
        is( $data->{combined}{c}, 3, 'multi-merge: key from second base' );
    }
}

# --- Merge key without ImplicitTyping ---

{
    local $YAML::Syck::ImplicitTyping = 0;

    my $yaml = <<'YAML';
---
defaults: &defaults
  color: red

item:
  <<: *defaults
  name: widget
YAML
    my $data = Load($yaml);
    # Without ImplicitTyping, << might be treated as a literal key
    # Test that the structure is still usable
    ok( defined $data->{item}, 'merge key structure loads without ImplicitTyping' );
}

# --- << as a plain string value (not merge context) ---

{
    my $yaml = <<'YAML';
---
operator: <<
YAML
    my $data = Load($yaml);
    # When << is a value (not a mapping key with alias), it should still be parsed
    ok( defined $data->{operator}, '<< as a plain value is defined' );
}

done_testing();
