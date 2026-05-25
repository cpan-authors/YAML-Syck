---
name: bump-version
description: Bump $VERSION in every .pm under lib/, update the POD =head1 VERSION prose in the main module, and regenerate README.md via pod2markdown if README.md exists. Layout-agnostic across CPAN modules. Takes the new version (e.g. /bump-version 3.104) and optionally --date YYYY-MM-DD (defaults to today).
---

# bump-version

End-to-end version bump for a CPAN module release:

1. Rewrites `our $VERSION = '...'` in every `.pm` file under `lib/`.
2. Detects the main module (Makefile.PL `VERSION_FROM` → `dist.ini` `main_module`/`name` → `META.json`/`META.yml` `name`) and updates the `=head1 VERSION` POD prose within it.
3. Regenerates `README.md` via `pod2markdown <main-module> > README.md`, but only if `README.md` already exists *and* looks like it was generated from the main module's POD (majority of its `# HEADER` lines match the module's `=head1` headers). A hand-written README is left alone.

## How to invoke

```bash
perl .claude/skills/bump-version/bump_version.pl <new-version>
perl .claude/skills/bump-version/bump_version.pl --date 2026-06-01 3.104
perl .claude/skills/bump-version/bump_version.pl --dry-run 3.104
perl .claude/skills/bump-version/bump_version.pl --main-module lib/Foo.pm 1.23
perl .claude/skills/bump-version/bump_version.pl --no-readme 3.104
```

Flags:

- `--dry-run` / `-n` — preview every change without writing or running pod2markdown.
- `--date YYYY-MM-DD` — release date used in the POD prose. Defaults to today.
- `--main-module PATH` — override main module detection.
- `--no-readme` — skip the pod2markdown regeneration.

## Argument format

- Version must match `/^\d+\.\d+(_\d+)?$/` (e.g. `3.104`, `3.104_01`).
- Date must be `YYYY-MM-DD`; rendered as `Month D YYYY` in POD (e.g. `2026-06-01` → `June 1 2026`).

## Behavior notes

- `.pm` files with no `$VERSION` declaration are reported as skipped (e.g. an XS shim that delegates to `$Parent::VERSION`).
- Files already at the target version are reported as unchanged.
- Existing whitespace and quote style around `$VERSION = '...'` are preserved.
- POD update is best-effort: looks for `<prose> version X.YY[, released on <date>].` inside `=head1 VERSION`. If nothing matches, reports `no matching prose line` and leaves the file alone — fix the POD manually then re-run `pod2markdown <main-module> > README.md`.
- `pod2markdown` must be on `$PATH` when README regeneration runs.

## Out of scope

`Changes`, `RELEASE`, and `META*` files are maintainer/build-tool controlled and intentionally not touched.
