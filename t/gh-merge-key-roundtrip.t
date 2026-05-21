use strict;
use warnings;
use Test::More tests => 10;
use YAML::Syck;

# GitHub: merge key (<<) roundtrip fix
# The emitter must quote "<<" string keys so they don't get
# misinterpreted as merge keys on re-load with ImplicitTyping.
# The parser must only treat unquoted << as a merge key, not
# quoted "<<" or '<<'.

$YAML::Syck::SortKeys = 1;

# 1-2: Dump quotes << key; roundtrip preserves it
{
    my $data = { "<<" => "value", name => "test" };
    my $yaml = Dump($data);
    like $yaml, qr/["']<<["']/, 'Dump quotes << key';

    local $YAML::Syck::ImplicitTyping = 1;
    my $back = Load($yaml);
    is $back->{"<<"}, "value", '<< key survives roundtrip with ImplicitTyping';
}

# 3: << with hashref value does not silently merge
{
    my $data = { "<<" => { extra => 42 }, name => "test" };
    my $yaml = Dump($data);
    local $YAML::Syck::ImplicitTyping = 1;
    my $back = Load($yaml);
    ok exists $back->{"<<"}, '<< key with hashref value preserved (no silent merge)';
}

# 4-5: Real unquoted merge key still works
{
    local $YAML::Syck::ImplicitTyping = 1;
    my $yaml = "---\ndefaults: &def\n  color: blue\n  size: large\nitem:\n  <<: *def\n  name: widget\n";
    my $data = Load($yaml);
    is $data->{item}{color}, "blue", 'unquoted << still triggers merge (color)';
    is $data->{item}{name}, "widget", 'unquoted << merge preserves explicit key';
}

# 6-7: Double-quoted << in input is a regular key
{
    local $YAML::Syck::ImplicitTyping = 1;
    my $yaml = qq{---\n"<<": regular_value\nname: test\n};
    my $data = Load($yaml);
    ok exists $data->{"<<"}, 'double-quoted "<<" is a regular key';
    is $data->{"<<"}, "regular_value", 'double-quoted "<<" value preserved';
}

# 8: Single-quoted << in input is a regular key
{
    local $YAML::Syck::ImplicitTyping = 1;
    my $yaml = "---\n'<<': single_q\n";
    my $data = Load($yaml);
    ok exists $data->{"<<"}, "single-quoted '<<' is a regular key";
}

# 9: << as a value (not key) roundtrips fine
{
    my $data = { key => "<<" };
    my $yaml = Dump($data);
    local $YAML::Syck::ImplicitTyping = 1;
    my $back = Load($yaml);
    is $back->{key}, "<<", '<< as value roundtrips correctly';
}

# 10: Merge with sequence of mappings still works
{
    local $YAML::Syck::ImplicitTyping = 1;
    my $yaml = <<'END';
---
first: &a
  alpha: 1
second: &b
  beta: 2
merged:
  <<: [*a, *b]
  gamma: 3
END
    my $data = Load($yaml);
    is $data->{merged}{alpha}, 1, 'merge with sequence of mappings still works';
}
