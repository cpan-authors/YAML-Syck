use strict;
use warnings;
use FindBin;
BEGIN { push @INC, $FindBin::Bin }

use Test::More;
use JSON::Syck;

# Test that JSON::Syck::Load correctly decodes JSON escape sequences.
# This covers issue #30: JSON::Syck does not properly escape/unescape JSON strings.

my @load_tests = (
    # [ description, json_input, expected_bytes ]
    [ 'escaped double quote',    '"\\"hello\\""',  '"hello"' ],
    [ 'escaped backslash',       '"\\\\"',         '\\' ],
    [ 'escaped solidus',         '"\\/"',          '/' ],
    [ 'escaped backspace',       '"\\b"',          "\b" ],
    [ 'escaped form feed',       '"\\f"',          "\f" ],
    [ 'escaped newline',         '"\\n"',          "\n" ],
    [ 'escaped carriage return', '"\\r"',          "\r" ],
    [ 'escaped tab',             '"\\t"',          "\t" ],

    # \uXXXX unicode escapes
    [ 'unicode null \\u0000',    '"\\u0000"',      "\x00" ],
    [ 'unicode SOH \\u0001',     '"\\u0001"',      "\x01" ],
    [ 'unicode space \\u0020',   '"\\u0020"',      " " ],
    [ 'unicode A \\u0041',       '"\\u0041"',      "A" ],
    [ 'unicode tilde \\u007e',   '"\\u007e"',      "~" ],

    # Multi-byte UTF-8 from \uXXXX
    [ 'unicode e-acute \\u00e9', '"\\u00e9"',      "\xc3\xa9" ],       # UTF-8 for U+00E9
    [ 'unicode CJK \\u4e16',    '"\\u4e16"',      "\xe4\xb8\x96" ],   # UTF-8 for U+4E16 (世)

    # Mixed content
    [ 'solidus in URL',         '"http:\\/\\/example.com\\/"',  'http://example.com/' ],
    [ 'mixed escapes',          '"tab\\there\\nnewline"',       "tab\there\nnewline" ],
    [ 'unicode in text',        '"caf\\u00e9"',                 "caf\xc3\xa9" ],

    # Case-insensitive hex in \u
    [ 'uppercase hex \\u00E9',  '"\\u00E9"',      "\xc3\xa9" ],
    [ 'mixed case \\u00eF',    '"\\u00eF"',      "\xc3\xaf" ],

    # UTF-16 surrogate pairs (\uD800-\uDBFF + \uDC00-\uDFFF)
    [ 'surrogate pair U+1F600', '"\\uD83D\\uDE00"',  "\xF0\x9F\x98\x80" ],  # 😀
    [ 'surrogate pair U+1F4A9', '"\\uD83D\\uDCA9"',  "\xF0\x9F\x92\xA9" ],  # 💩
    [ 'surrogate pair U+10000', '"\\uD800\\uDC00"',   "\xF0\x90\x80\x80" ],  # first supplementary char

);

plan tests => scalar @load_tests;

for my $test (@load_tests) {
    my ($desc, $input, $expected) = @$test;
    my $got = JSON::Syck::Load($input);
    is $got, $expected, "Load: $desc";
}
