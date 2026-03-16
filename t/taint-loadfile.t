#!/usr/bin/perl -T
# Test that LoadFile returns untainted data under taint mode (GH #29)

use strict;
use warnings;

use FindBin;
BEGIN {
    # Untaint $FindBin::Bin for use in @INC under taint mode
    my ($dir) = $FindBin::Bin =~ /^(.*)$/s;
    push @INC, $dir;
}

use TestYAML;
use Test::More;
use Scalar::Util qw(tainted);
use File::Temp   qw(tempfile);

plan tests => 5;

# Write a test YAML file
my ($fh, $filename) = tempfile( SUFFIX => '.yml', UNLINK => 1 );
print $fh "---\nfoo: bar\nbaz: 42\n";
close $fh;

# Sanity: reading from a file under -T produces tainted data
{
    open my $tfh, '<', $filename or die "Cannot open $filename: $!";
    my $raw = do { local $/; <$tfh> };
    close $tfh;
    ok( tainted($raw), 'raw file read is tainted under -T (sanity check)' );
}

# LoadFile with filename should return untainted data
{
    my $data = YAML::Syck::LoadFile($filename);
    ok( !tainted($data->{foo}), 'LoadFile(filename) returns untainted hash values' );
    ok( !tainted($data->{baz}), 'LoadFile(filename) returns untainted numeric values' );
}

# LoadFile with filehandle should return untainted data
{
    open my $lfh, '<', $filename or die "Cannot open $filename: $!";
    my $data = YAML::Syck::LoadFile($lfh);
    close $lfh;
    ok( !tainted($data->{foo}), 'LoadFile(filehandle) returns untainted hash values' );
    ok( !tainted($data->{baz}), 'LoadFile(filehandle) returns untainted numeric values' );
}
