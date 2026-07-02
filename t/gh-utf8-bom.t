use strict;
use warnings;
use Test::More;
use YAML::Syck;
use JSON::Syck;
use File::Temp qw(tempfile);

my $BOM = "\xEF\xBB\xBF";

# --- YAML Load ---

{
    my $data = YAML::Syck::Load("${BOM}key: value\n");
    is_deeply($data, { key => 'value' }, 'YAML: BOM stripped from map input');
}

{
    my $data = YAML::Syck::Load("${BOM}---\nkey: value\n");
    is_deeply($data, { key => 'value' }, 'YAML: BOM stripped before --- doc start');
}

{
    my $data = YAML::Syck::Load("${BOM}- a\n- b\n");
    is_deeply($data, [ 'a', 'b' ], 'YAML: BOM stripped from sequence input');
}

{
    my $data = YAML::Syck::Load("${BOM}hello\n");
    is($data, 'hello', 'YAML: BOM stripped from scalar input');
}

{
    my @docs = YAML::Syck::Load("${BOM}---\na: 1\n---\nb: 2\n");
    is(scalar @docs, 2, 'YAML: BOM stripped in multi-document stream');
    is_deeply($docs[0], { a => 1 }, 'YAML: first doc correct after BOM');
    is_deeply($docs[1], { b => 2 }, 'YAML: second doc correct after BOM');
}

{
    my $data = YAML::Syck::Load("${BOM}");
    is($data, undef, 'YAML: BOM-only input returns undef');
}

{
    my $data = YAML::Syck::Load("key: value\n");
    is_deeply($data, { key => 'value' }, 'YAML: no BOM still works (sanity check)');
}

# --- YAML LoadFile ---

{
    my ($fh, $filename) = tempfile(UNLINK => 1, SUFFIX => '.yaml');
    print $fh "${BOM}key: value\n";
    close $fh;
    my $data = YAML::Syck::LoadFile($filename);
    is_deeply($data, { key => 'value' }, 'YAML: LoadFile strips BOM');
}

# --- JSON Load ---

{
    my $data = JSON::Syck::Load("${BOM}{\"key\": \"value\"}");
    is_deeply($data, { key => 'value' }, 'JSON: BOM stripped from object input');
}

{
    my $data = JSON::Syck::Load("${BOM}[1, 2, 3]");
    is_deeply($data, [ 1, 2, 3 ], 'JSON: BOM stripped from array input');
}

{
    my $data = JSON::Syck::Load("${BOM}\"hello\"");
    is($data, 'hello', 'JSON: BOM stripped from string input');
}

{
    my $data = JSON::Syck::Load("{\"key\": \"value\"}");
    is_deeply($data, { key => 'value' }, 'JSON: no BOM still works (sanity check)');
}

# --- Edge cases ---

{
    my $data = YAML::Syck::Load("${BOM}${BOM}key: value\n");
    is_deeply($data, { "${BOM}key" => 'value' }, 'YAML: only first BOM is stripped');
}

done_testing;
