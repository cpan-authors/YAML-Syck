use strict;
use FindBin;
BEGIN { push @INC, $FindBin::Bin }

use TestYAML ();
use JSON::Syck;
use Test::More tests => 14;

# __jsonclass__ support should be off by default
{
    my $json = '{"__jsonclass__": ["Foo::Bar", [1, 2]], "name": "test"}';
    my $data = JSON::Syck::Load($json);
    is ref($data), 'HASH', 'without LoadJsonClass, result is plain hash';
    ok exists $data->{'__jsonclass__'}, 'without LoadJsonClass, __jsonclass__ key preserved';
}

# LoadJsonClass callback
{
    local $JSON::Syck::LoadJsonClass = sub {
        my ($hash) = @_;
        my $class_info = delete $hash->{'__jsonclass__'};
        my $class = $class_info->[0];
        return bless $hash, $class;
    };

    my $json = '{"__jsonclass__": ["My::Object"], "color": "red"}';
    my $data = JSON::Syck::Load($json);
    is ref($data), 'My::Object', 'LoadJsonClass blesses into correct class';
    is $data->{color}, 'red', 'LoadJsonClass preserves properties';
    ok !exists $data->{'__jsonclass__'}, 'LoadJsonClass callback removed __jsonclass__ key';
}

# LoadJsonClass with constructor params
{
    local $JSON::Syck::LoadJsonClass = sub {
        my ($hash) = @_;
        my $class_info = delete $hash->{'__jsonclass__'};
        my ($class, $params) = @$class_info;
        my $obj = bless { params => $params, %$hash }, $class;
        return $obj;
    };

    my $json = '{"__jsonclass__": ["Foo::Bar", [1, "hello"]], "extra": true}';
    my $data = JSON::Syck::Load($json);
    is ref($data), 'Foo::Bar', 'LoadJsonClass with params: correct class';
    is_deeply $data->{params}, [1, "hello"], 'LoadJsonClass with params: params passed';
    is $data->{extra}, 1, 'LoadJsonClass with params: extra properties preserved';
}

# LoadJsonClass processes nested structures
{
    local $JSON::Syck::LoadJsonClass = sub {
        my ($hash) = @_;
        my $class_info = delete $hash->{'__jsonclass__'};
        return bless $hash, $class_info->[0];
    };

    my $json = '{"items": [{"__jsonclass__": ["Item"], "id": 1}, {"__jsonclass__": ["Item"], "id": 2}]}';
    my $data = JSON::Syck::Load($json);
    is ref($data), 'HASH', 'nested: outer is plain hash';
    is ref($data->{items}[0]), 'Item', 'nested: first item blessed';
    is ref($data->{items}[1]), 'Item', 'nested: second item blessed';
}

# DumpJsonClass callback
{
    local $JSON::Syck::DumpJsonClass = sub {
        my ($obj) = @_;
        my $class = ref $obj;
        my %props = %$obj;
        return { '__jsonclass__' => [$class], %props };
    };

    my $obj = bless { color => "blue" }, "My::Widget";
    my $json = JSON::Syck::Dump($obj);
    my $data = JSON::Syck::Load($json);
    is ref($data), 'HASH', 'DumpJsonClass produces valid JSON';
    is_deeply $data->{'__jsonclass__'}, ['My::Widget'], 'DumpJsonClass includes class info';
    is $data->{color}, 'blue', 'DumpJsonClass preserves properties';
}
