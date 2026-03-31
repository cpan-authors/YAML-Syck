# YAML-Syck

Fast YAML 1.0 and JSON serialization for Perl using the bundled libsyck C library.
This is an XS-based CPAN distribution.

## Build and Test

```bash
perl Makefile.PL    # generates Makefile, checks for C compiler
make                # compiles C source and XS code
make test           # runs the full test suite
```

A C compiler is required. The build compiles bundled libsyck C files (`*.c`) and
the XS glue (`Syck.xs` -> `Syck.c`) into a shared object.

To run a single test file:

```bash
prove -bv t/1-basic.t
```

## Project Layout

- `lib/YAML/Syck.pm` - main module; version is defined here (`VERSION_FROM`)
- `lib/JSON/Syck.pm` - JSON interface using the same libsyck engine
- `lib/YAML/Loader/Syck.pm`, `lib/YAML/Dumper/Syck.pm` - YAML framework adapters
- `Syck.xs` - XS bindings (Perl-to-C glue)
- `perl_syck.h` - bulk of the Perl/C integration logic
- `*.c`, `*.h` - bundled libsyck C library (do not modify without care)
- `ppport.h` - Perl portability header (regenerate via `Devel::PPPort`)
- `t/` - test suite (45+ files); bug regressions live in `t/bug/`
- `inc/ExtUtils/HasCompiler.pm` - build-time compiler detection

## Key Files for Changes

- `Changes` - changelog; update before each release
- `MANIFEST` - list of files included in the CPAN tarball. The ordering is controlled by
  `make manifest` (after a clean `perl Makefile.PL`). When adding entries manually, preserve
  the existing order and do not re-sort unless the file is regenerated via `make manifest`.
- `MANIFEST.SKIP` - patterns for files excluded from the tarball.
- `cpanfile` - dependency declarations for CI
- `.github/workflows/testsuite.yml` - GitHub Actions CI

## CI

GitHub Actions runs on push/PR across Ubuntu, macOS, and Windows.
Linux tests run against all Perl versions from 5.8 through devel using `perldocker`.
CI sets `AUTOMATED_TESTING=1` which enables memory leak tests (`t/leak.t` requires `Devel::Leak`).

## Releasing

1. Update version in `lib/YAML/Syck.pm` and `lib/JSON/Syck.pm`
2. Update `Changes` with the new version, date, and entries since the last commit which is tagged in git with v$VERSION
3. Create a local commit (don't push it) to capture these changes but don't tag or push it yet. 
4. Run `perl Makefile.PL && make manifest` to make sure `MANIFEST` does not update. If it does, then a previous commit did something wrong and we should stop.
5. At this point no uncommitted files or even files not in the repo should be present. If there are then stop. 
6. Run `make disttest` to be sure that the generated tarball can still build and test isolated from repo files we don't ship. 
7. There will be a local directory from the `make disttest` run. clean that up by running `git clean -dxf .`
9. `make dist` to create the tarball
10. It will be manually uploaded to CPAN.

## Coding Conventions

- Perl minimum version: 5.8
- Tests use `Test::More`
- Bug regression tests go in `t/` and are named after the GitHub issue (`t/gh-*.t`)
- C code follows libsyck style; Perl-side logic is in `perl_syck.h`
- `$YAML::Syck::*` global variables control serialization behavior (see POD in `lib/YAML/Syck.pm`)
- a .perltidyrc file exists in the base of the repo and we enforce tidiness in any .pm file.

## Repository

- Bug tracker: https://github.com/toddr/YAML-Syck/issues
- License: MIT
