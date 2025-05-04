use strict;
use warnings;
use Test::More tests => 8;
use YAML::Syck;

# Test string with various special characters
my $test_str = "with \t tabs and carriage \r returns";

# Test dumping and loading
my $yaml = Dump($test_str);
my $loaded = Load($yaml);

# Verify the string roundtrips correctly
is($loaded, $test_str, "String with special chars roundtrips correctly");

# Test literal backslashes
my $backslash_str = "with \\t tabs and carriage \\r returns";
$yaml = Dump($backslash_str);
$loaded = Load($yaml);
is($loaded, $backslash_str, "String with literal backslashes roundtrips correctly");

# Test mixed special chars and literal backslashes
my $mixed_str = "with \t tabs and \\r literal returns";
$yaml = Dump($mixed_str);
$loaded = Load($yaml);
is($loaded, $mixed_str, "String with mixed special chars and literal backslashes roundtrips correctly");

# Test in a hash
my $hash = {
    special => "with \t tabs and carriage \r returns",
    literal => "with \\t tabs and carriage \\r returns",
    mixed => "with \t tabs and \\r literal returns"
};

$yaml = Dump($hash);
$loaded = Load($yaml);

is($loaded->{special}, $hash->{special}, "Special chars in hash value roundtrip correctly");
is($loaded->{literal}, $hash->{literal}, "Literal backslashes in hash value roundtrip correctly");
is($loaded->{mixed}, $hash->{mixed}, "Mixed chars in hash value roundtrip correctly");

# Test in an array
my $array = [
    "with \t tabs and carriage \r returns",
    "with \\t tabs and carriage \\r returns",
    "with \t tabs and \\r literal returns"
];

$yaml = Dump($array);
$loaded = Load($yaml);

is($loaded->[0], $array->[0], "Special chars in array element roundtrip correctly");
is($loaded->[1], $array->[1], "Literal backslashes in array element roundtrip correctly");

