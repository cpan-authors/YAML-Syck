#!/usr/bin/perl -w

use strict;
use Test::More tests => 8;
use YAML::Syck qw(Load);

# GH: Load() in list context should return empty list for empty/undef input,
# not croak with "Can't use an undefined value as an ARRAY reference"

# Empty string
{
    my @docs = Load("");
    is( scalar @docs, 0, "Load('') in list context returns empty list" );
}

# Undef
{
    my @docs = Load(undef);
    is( scalar @docs, 0, "Load(undef) in list context returns empty list" );
}

# Scalar context still returns undef
{
    my $doc = Load("");
    ok( !defined $doc, "Load('') in scalar context returns undef" );
}

# Single document in list context
{
    my @docs = Load("--- foo\n");
    is( scalar @docs, 1, "single doc in list context returns 1 element" );
    is( $docs[0], 'foo', "single doc value is correct" );
}

# Multi-document in list context
{
    my @docs = Load("--- foo\n--- bar\n");
    is( scalar @docs, 2, "multi-doc in list context returns 2 elements" );
    is( $docs[0], 'foo', "first doc is correct" );
    is( $docs[1], 'bar', "second doc is correct" );
}
