#!/usr/bin/env perl
use strict;
use warnings;
use File::Find ();

my $dry_run = 0;
my $date_arg;
my $main_override;
my $skip_readme = 0;
my @args;
while (@ARGV) {
    my $a = shift @ARGV;
    if    ($a eq '--dry-run'    || $a eq '-n') { $dry_run = 1 }
    elsif ($a eq '--no-readme')                { $skip_readme = 1 }
    elsif ($a eq '--date')                     { $date_arg = shift @ARGV }
    elsif ($a =~ /\A--date=(.+)\z/)            { $date_arg = $1 }
    elsif ($a eq '--main-module')              { $main_override = shift @ARGV }
    elsif ($a =~ /\A--main-module=(.+)\z/)     { $main_override = $1 }
    else                                        { push @args, $a }
}

my $new_version = shift @args;
defined $new_version && length $new_version
    or die "Usage: $0 [--dry-run] [--date YYYY-MM-DD] [--main-module PATH] [--no-readme] <new-version>\n";

$new_version =~ /\A[0-9]+\.[0-9]+(?:_[0-9]+)?\z/
    or die "Invalid version '$new_version' (expected e.g. 3.104 or 3.104_01)\n";

-d 'lib' or die "No lib/ directory in $ENV{PWD} -- run from repo root.\n";

my $release_date = format_release_date($date_arg);
my $main_module  = $main_override // detect_main_module();

my @pm_files;
File::Find::find(
    sub { push @pm_files, $File::Find::name if /\.pm\z/ && -f $_ },
    'lib',
);
@pm_files = sort @pm_files;

my ($changed, $already, @no_match);

for my $file (@pm_files) {
    my $content = slurp($file);
    my $orig    = $content;

    my $hits = $content =~ s{
        ^( \s* our \s+ \$VERSION \s* = \s* ['"] )
        [^'"]+
        ( ['"] )
    }{$1$new_version$2}mxg;

    if (!$hits) {
        push @no_match, $file;
        next;
    }

    if ($content eq $orig) {
        $already++;
        print "  = $file (already $new_version)\n";
        next;
    }

    spew($file, $content) unless $dry_run;
    $changed++;
    print "  " . ($dry_run ? "[dry] " : "") . "updated $file\n";
}

my $pod_status;
if (!defined $main_module) {
    $pod_status = "skipped (could not detect main module; pass --main-module)";
}
elsif (!-f $main_module) {
    $pod_status = "skipped ($main_module does not exist)";
}
else {
    $pod_status = update_pod_version($main_module, $new_version, $release_date, $dry_run);
}
print "\nPOD =head1 VERSION", (defined $main_module ? " in $main_module" : ""), ": $pod_status\n";

my $readme_status;
if ($skip_readme) {
    $readme_status = "skipped (--no-readme)";
}
elsif (!-f 'README.md') {
    $readme_status = "skipped (no README.md present in repo)";
}
elsif (!defined $main_module || !-f $main_module) {
    $readme_status = "skipped (no main module to render)";
}
elsif (!readme_looks_pod_generated('README.md', $main_module)) {
    $readme_status = "skipped (README.md does not appear to be generated from $main_module)";
}
elsif ($dry_run) {
    $readme_status = "[dry] would regenerate via pod2markdown $main_module > README.md";
}
else {
    my $rc = system("pod2markdown $main_module > README.md");
    $readme_status = $rc == 0
        ? "regenerated via pod2markdown"
        : "FAILED (pod2markdown exited rc=$rc)";
}
print "README.md: $readme_status\n";

print "\n";
print "Scanned ", scalar(@pm_files), " .pm file(s) under lib/.\n";
print($dry_run ? "Would update" : "Updated", " $changed file(s) to $new_version.\n");
print "$already file(s) already at $new_version.\n" if $already;
if (@no_match) {
    print "\nSkipped (no \$VERSION declaration):\n";
    print "  $_\n" for @no_match;
}
exit 0;

sub slurp {
    my ($f) = @_;
    open my $fh, '<', $f or die "open $f: $!";
    local $/;
    return scalar <$fh>;
}

sub spew {
    my ($f, $data) = @_;
    open my $fh, '>', $f or die "write $f: $!";
    print $fh $data;
}

sub format_release_date {
    my ($iso) = @_;
    my @months = qw(January February March April May June
                    July August September October November December);
    my ($y, $m, $d);
    if (defined $iso) {
        ($y, $m, $d) = $iso =~ /\A([0-9]{4})-([0-9]{2})-([0-9]{2})\z/
            or die "Invalid --date '$iso' (expected YYYY-MM-DD)\n";
    }
    else {
        my @t = localtime;
        ($y, $m, $d) = ($t[5] + 1900, $t[4] + 1, $t[3]);
    }
    $m >= 1 && $m <= 12 or die "Invalid month in date: $m\n";
    return sprintf("%s %d %d", $months[$m - 1], $d + 0, $y);
}

sub detect_main_module {
    # 1. Makefile.PL VERSION_FROM
    if (-f 'Makefile.PL') {
        my $c = slurp('Makefile.PL');
        if ($c =~ /['"]? VERSION_FROM ['"]? \s* (?:=>|,) \s* ['"]([^'"]+)['"]/x) {
            return $1 if -f $1;
        }
    }
    # 2. dist.ini (Dist::Zilla)
    if (-f 'dist.ini') {
        my $c = slurp('dist.ini');
        if ($c =~ /^ \s* main_module \s* = \s* (\S+)/mx) {
            return $1 if -f $1;
        }
        if ($c =~ /^ \s* name \s* = \s* (\S+)/mx) {
            my $path = dist_name_to_path($1);
            return $path if -f $path;
        }
    }
    # 3. META.json / META.yml
    for my $meta ('META.json', 'META.yml') {
        next unless -f $meta;
        my $c = slurp($meta);
        if ($c =~ /["']? name ["']? \s* [:=] \s* ["']? ([\w:-]+) ["']?/x) {
            my $path = dist_name_to_path($1);
            return $path if -f $path;
        }
    }
    return undef;
}

# README.md is treated as generated from the main module if the majority of its
# top-level markdown headers (# HEADER) match =head1 headers in the main module.
# This catches the common pod2markdown output even when the file has hand-added
# preamble (e.g. CI badges) above the generated content.
sub readme_looks_pod_generated {
    my ($readme_path, $main_module) = @_;
    my $readme = slurp($readme_path);
    my $module = slurp($main_module);

    my @pod_heads;
    while ($module =~ /^=head1 \s+ (\S [^\n]*?) \s*$/mxg) {
        push @pod_heads, $1;
    }
    return 0 if @pod_heads < 2;

    my $matches = 0;
    for my $h (@pod_heads) {
        $matches++ if $readme =~ /^\# \s+ \Q$h\E \s*$/mx;
    }
    return $matches >= 3 || ($matches >= 2 && $matches * 2 >= @pod_heads);
}

sub dist_name_to_path {
    my ($name) = @_;
    $name =~ s{::}{-}g;
    (my $rel = $name) =~ s{-}{/}g;
    return "lib/$rel.pm";
}

# Within the =head1 VERSION POD section of the main module, update the version
# (and a "released on <date>" clause if present). Best-effort; if no matching
# prose line is found, return a status string and leave the file alone.
sub update_pod_version {
    my ($file, $newver, $date, $dry) = @_;
    my $content = slurp($file);
    my $orig    = $content;

    # Locate the =head1 VERSION section (up to the next =head1 or EOF).
    unless ($content =~ /(^=head1 \s+ VERSION \s*\n)(.*?)(?=^=head\d|\z)/msx) {
        return "no =head1 VERSION section found";
    }
    my $head    = $1;
    my $body    = $2;
    my $offset  = $-[2];
    my $orig_body = $body;

    # Try to update a line of the form:
    #   <Name or prose> version <X.YY>[, released on <date>].
    my $hits = $body =~ s{
        ^( [^\n]*? \b version \s+ )    # prose up through "version "
        [0-9]+ \. [0-9]+ (?: _[0-9]+ )?  # the version
        ( , \s+ released \s+ on \s+ [^.\n]+ )?  # optional date clause
        ( \. \s* )$
    }{
        my $head_text   = $1;
        my $date_clause = $2;
        my $tail        = $3;
        my $rep = $head_text . $newver;
        $rep .= ", released on $date" if defined $date_clause;
        $rep . $tail;
    }mxe;

    if (!$hits) {
        return "no matching prose line in =head1 VERSION";
    }
    if ($body eq $orig_body) {
        return "already $newver";
    }

    substr($content, $offset, length($orig_body)) = $body;
    spew($file, $content) unless $dry;
    return ($dry ? "would update" : "updated") . " ($newver, $date)";
}
