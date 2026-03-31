requires 'XSLoader' => 0;

on "test" => sub {
    requires "Test::More" => "0";
    requires "Devel::Leak" => "0" if $] >= 5.010;
};
