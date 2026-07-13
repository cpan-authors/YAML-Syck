use strict;
use warnings;
use Test::More;
use YAML::Syck;

# GH #212: YAML-Syck 1.46 broke round-trip of unquoted numeric values.
# Load stores all scalars as POK-only strings, and Dump (since #200)
# quotes POK-only values that look like numbers.  The fix: Load now
# sets numeric flags on plain (unquoted) scalars that look like numbers,
# so Dump emits them unquoted — restoring round-trip while preserving
# the #200 fix for actually-quoted strings.

my @roundtrip_cases = (
    [ "---\nfoo: 1\n",           "simple integer 1" ],
    [ "---\nfoo: 42\n",          "simple integer 42" ],
    [ "---\nfoo: 0\n",           "zero" ],
    [ "---\nabc: 1\ndef: 2\n",   "multiple integer values" ],
    [ "---\nfoo: 100\n",         "three-digit integer" ],
    [ "---\nfoo: -5\n",          "negative integer" ],
    [ "---\nfoo: 999999999\n",   "large 9-digit integer" ],
);

for my $case (@roundtrip_cases) {
    my ($yaml, $desc) = @$case;
    my $data = YAML::Syck::Load($yaml);
    my $rt   = YAML::Syck::Dump($data);
    is $rt, $yaml, "round-trip: $desc";
}

# Quoted strings must still stay quoted (the #200 fix).
{
    my $data = { port => "8080" };
    my $yaml = YAML::Syck::Dump($data);
    like $yaml, qr/'8080'/, "POK-only string '8080' stays quoted in Dump";
}

# haarg's exact reproducer from the issue
{
    my $string = "---\nabc: 1\ndef: 2\n";
    my $rt = YAML::Syck::Dump(YAML::Syck::Load($string));
    is $rt, $string, "haarg's reproducer: Load/Dump round-trip";
}

# Quoted values in YAML must remain strings (no numification)
{
    my $yaml = "---\nfoo: '42'\n";
    my $data = YAML::Syck::Load($yaml);
    my $dump = YAML::Syck::Dump($data);
    like $dump, qr/'42'/, "single-quoted '42' stays quoted after round-trip";
}

{
    my $yaml = qq{---\nfoo: "42"\n};
    my $data = YAML::Syck::Load($yaml);
    my $dump = YAML::Syck::Dump($data);
    like $dump, qr/'42'/, "double-quoted \"42\" stays quoted after round-trip";
}

done_testing;
