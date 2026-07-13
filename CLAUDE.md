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

## Security & CVE Work

When fixing a CVE (or any reported memory-safety defect) in the bundled libsyck
C code:

- **Write one unit test per CVE.** Name it `t/cve-<id>-<slug>.t` (e.g.
  `t/cve-2026-13713-anchor-node-uaf.t`). Each test documents the CWE, the exact
  trigger input, and what the unpatched behavior looks like, so a researcher can
  read a single file and understand the risk.
- **Make the test fail provably without the fix, if at all possible.** Call
  `Load()` on the trigger directly in the test body (one CVE per file, so a
  crash only takes down that file, which the harness reports as failed). Wrap it
  in `eval {}` so the *patched* behaviour — an ordinary parse-error croak — is a
  pass; a C-level `abort()`/signal is not catchable and fails the file. Do not
  fork a child `perl` to reproduce; keep it in-process. (`fork()` without exec
  would give tidier TAP but is unsafe on Windows, where pseudo-fork shares the
  process and a crash kills the parent.) Depending on the defect:
  - Crashes on a normal build (double-free, wild write): the unpatched file
    aborts (`wstat` shows the signal) and passes once patched. Provable anywhere.
  - Observably wrong output (e.g. an OOB read that leaks bytes into a decoded
    result): assert the corrected, deterministic output — fails unpatched on a
    normal build.
  - Silent (non-crashing UAF / one-byte over-read): cannot fail a normal build;
    the direct `Load()` just returns. It is proven by the **ASan CI job**
    (`asan` in `.github/workflows/testsuite.yml`), where the same in-process
    `Load()` aborts under AddressSanitizer. Say so in the test's comments.
- The `asan` CI job builds the XS with `-fsanitize=address` and runs both the
  suite and the documented CVE trigger inputs; it is the authoritative check for
  the silent defects. macOS cannot run it (stock perl can't instrument a
  `dlopen`'d XS module) — it is Linux-only.
- Add every new `t/cve-*.t` to `MANIFEST` (see the MANIFEST notes above).

## Coding Conventions

- Perl minimum version: 5.8
- Tests use `Test::More`
- Bug regression tests go in `t/` and are named after the GitHub issue (`t/gh-*.t`)
- CVE regression tests go in `t/` and are named `t/cve-<id>-<slug>.t` (see
  Security & CVE Work above)
- C code follows libsyck style; Perl-side logic is in `perl_syck.h`
- `$YAML::Syck::*` global variables control serialization behavior (see POD in `lib/YAML/Syck.pm`)
- a .perltidyrc file exists in the base of the repo and we enforce tidiness in any .pm file.

## Repository

- Bug tracker: https://github.com/toddr/YAML-Syck/issues
- License: MIT
