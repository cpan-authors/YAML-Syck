# YAML 1.0 Spec Compliance Audit

YAML-Syck declares itself a YAML 1.0 parser (`syck.h` defines `SYCK_YAML_MAJOR=1`,
`SYCK_YAML_MINOR=0`). This document maps the YAML 1.0 specification
(https://yaml.org/spec/1.0/) to the existing test suite and identifies coverage gaps.

## Audit Table

| Spec Section | Feature | Test File(s) | Coverage | Drift | Notes |
|---|---|---|---|---|---|
| **Scalars** | | | | | |
| Scalars | Plain scalars | `t/2-scalars.t`, `t/yaml-implicit-typing.t` | Covered | None | Tested as part of roundtrip and implicit typing |
| Scalars | Single-quoted scalars | `t/2-scalars.t` (SingleQuote flag) | Covered | None | Tests roundtrip with `$SingleQuote` flag |
| Scalars | Double-quoted scalars | `t/2-scalars.t` (lines 278-303) | Covered | None | Tests escape sequences: `\t`, `\r`, `\a`, `\e`, `\\ ` |
| Scalars | Literal block (`\|`) | `t/yaml-block-scalars.t` | Covered | None | Preserves newlines, strip/keep chomping, sequences |
| Scalars | Folded block (`>`) | `t/yaml-block-scalars.t` | Covered | None | Folds newlines to spaces, blank line preservation, chomping |
| Scalars | Chomping (`\|+`, `\|-`, `>+`, `>-`) | `t/yaml-block-scalars.t` | Covered | None | Clip (default), strip (`-`), keep (`+`) all tested |
| **Collections** | | | | | |
| Collections | Block sequences | `t/1-basic.t`, `t/2-scalars.t`, `t/3-objects.t` | Covered | None | Extensively tested throughout |
| Collections | Block mappings | `t/1-basic.t`, `t/2-scalars.t`, `t/3-objects.t` | Covered | None | Extensively tested throughout |
| Collections | Flow sequences | `t/yaml-nested-flow.t`, `t/gh-25-inline-array-no-space.t` | Covered | None | Including nested and no-space variants |
| Collections | Flow mappings | `t/yaml-nested-flow.t` | Covered | None | Tested with nested structures |
| Collections | Empty collections | `t/yaml-empty-collections.t` | Covered | None | Root and nested empty arrays/hashes |
| **Implicit Typing** | | | | | |
| Implicit Typing | Null (`~`, `null`) | `t/yaml-implicit-typing.t` | Covered | None | All case variants: `~`, `null`, `Null`, `NULL` |
| Implicit Typing | Boolean (yes/no/true/false/on/off) | `t/yaml-implicit-typing.t` | Covered | None (1.0) | Wide set matches 1.0 spec. 1.1 narrowed this — see Drift section |
| Implicit Typing | Integer (decimal) | `t/yaml-implicit-typing.t`, `t/2-scalars.t` | Covered | None | Including boundary values |
| Implicit Typing | Integer (hex `0x`) | `t/yaml-implicit-typing.t` | Covered | None | `0x1A`, `0xff`, `0xDEAD` |
| Implicit Typing | Integer (octal `0`) | `t/yaml-implicit-typing.t` | Covered | None | `01`, `010`, `0777` |
| Implicit Typing | Integer (base-60) | `t/yaml-implicit-typing.t`, `t/gh-132-base60-safety.t` | Covered | None (1.0) | `1:0`=60, `1:30`=90 — 1.0 feature |
| Implicit Typing | Float (decimal) | `t/yaml-implicit-typing.t` | Covered | None | `1.5`, `-3.14`, `+2.5` |
| Implicit Typing | Float (scientific) | `t/yaml-implicit-typing.t` | Covered | None | Requires explicit sign: `1.0e+3` |
| Implicit Typing | Float (special: inf/nan) | `t/yaml-implicit-typing.t`, `t/gh-26-implicit-type-roundtrip.t` | Covered | None | `.inf`, `.nan` and case variants |
| Implicit Typing | Float (base-60) | `t/yaml-implicit-typing.t` | Covered | None (1.0) | `1:30.5`=90.5 — 1.0 feature |
| Implicit Typing | Integers with commas (`1,000`) | `t/yaml-implicit-typing.t` (not-integer check) | Partial | None (1.0) | `1,000` not tested as integer; `implicit.c` supports commas via `syck_str_blow_away_commas()` |
| Implicit Typing | Merge key (`<<`) | `t/yaml-merge-key.t` (20 tests) | Covered | None | Single mapping merge, sequence-of-mappings merge, override precedence, ImplicitTyping gate |
| Implicit Typing | Timestamps | `t/yaml-timestamps.t` | Covered | None | Date, spaced, ISO 8601 formats; ImplicitTyping gate; quoted bypass |
| **Anchors & Aliases** | | | | | |
| Anchors | `&anchor` / `*alias` | `t/yaml-alias.t`, `t/1-basic.t`, `t/2-scalars.t` | Covered | None | Scalars, arrays, hashes, circular refs |
| **Tags** | | | | | |
| Tags | Global tags (`!!type`) | `t/3-objects.t`, `t/4-perl_tag_scheme.t` | Covered | None | Perl tag scheme: `!!perl/hash:Class` etc. |
| Tags | Local tags (`!type`) | `t/3-objects.t` | Covered | None | `!foo`, `!hs/Foo`, `!haskell.org/Foo` |
| Tags | Tag URI domain | — | N/A | None | `syck.h` defines `YAML_DOMAIN "yaml.org,2002"` (shared by 1.0 and 1.1) |
| **Documents** | | | | | |
| Documents | Document start (`---`) | `t/1-basic.t`, `t/2-scalars.t` | Covered | None | Tested throughout |
| Documents | Multi-document streams | `t/2-scalars.t` (line 191), `t/1-basic.t`, `t/yaml-multi-document.t` | Covered | None | Simple and complex multi-doc streams, inline values after `---`, plain scalars, `...` terminator |
| Documents | Document end (`...`) | `t/2-scalars.t` (line 247-248), `t/yaml-multi-document.t` | Covered | None | Roundtrip quoting of `...` as key; `...` as document terminator between documents |
| **Directives** | | | | | |
| Directives | `%YAML` directive | `t/yaml-directives.t` | Covered | None | Legacy `#YAML:1.0` and `%YAML:1.0` headers; headless mode; emitter `use_version=1` |
| Directives | `%TAG` directive | `t/yaml-directives.t` | Covered | None (1.0) | `%TAG` lines gracefully skipped (not expanded); consistent with 1.0 which lacks 1.1-style `%TAG` |
| **Escape Sequences** | | | | | |
| Escape Sequences | Double-quoted escapes | `t/2-scalars.t`, `t/bug/rt-41141.t` | Covered | None | `\t`, `\r`, `\a`, `\e`, `\\ `, control chars |
| **Comments** | | | | | |
| Comments | `#` comments | `t/yaml-comments.t` | Covered | None | Full-line, inline, nested, multi-line, and document-start comments |
| **Binary** | | | | | |
| Binary | `!binary` / base64 | `t/2-scalars.t` (lines 194-198) | Covered | None | Uses `ImplicitBinary` flag |
| **Unicode** | | | | | |
| Unicode | UTF-8 encoding | `t/yaml-utf.t`, `t/yaml-bytes-utf8.t`, `t/gh-28-wide-char-dumpfile.t` | Covered | None | Load/Dump with UTF-8 flag, wide chars |

## Drift Analysis (1.0 vs 1.1/1.2)

YAML-Syck is genuinely 1.0-aligned. The following analysis checks key areas where
1.0 and 1.1 diverge:

### Boolean values
- **1.0**: Wide set — yes/no/on/off/true/false, all case variants (y, Y, YES, Yes, etc.)
- **1.1**: Narrowed set, restricted case patterns
- **YAML-Syck behavior**: Matches 1.0. All case variants resolve to booleans with `ImplicitTyping` enabled.
- **Drift**: None.

### Integers with commas
- **1.0**: Allows commas in integers (e.g., `1,000` = 1000)
- **1.1**: Does not allow commas
- **YAML-Syck behavior**: The C code (`implicit.c`) recognizes comma-separated integers and `syck_str_blow_away_commas()` strips them during conversion. This is 1.0 behavior.
- **Drift**: None.

### Base-60 (sexagesimal) values
- **1.0**: Supported for both integers and floats (e.g., `1:30` = 90)
- **1.1**: Supported (kept from 1.0)
- **1.2**: Removed
- **YAML-Syck behavior**: Fully supported per `implicit.c` and tested in `t/yaml-implicit-typing.t`.
- **Drift**: None. (Would be a 1.2 incompatibility if targeting 1.2, but correctly follows 1.0.)

### Scientific notation
- **1.0**: Requires explicit sign after `e` (e.g., `1.0e+3`, not `1.0e3`)
- **1.1**: Allows implicit positive sign
- **YAML-Syck behavior**: Tests in `t/yaml-implicit-typing.t` confirm explicit sign is required — values like `1.0e3` (no sign) are treated as strings.
- **Drift**: None.

### `%TAG` directive
- **1.0**: Uses transfer method notation (`!` and `!!` as shorthand for tag URIs)
- **1.1**: Formalized `%TAG` directive with handle/prefix pairs
- **YAML-Syck behavior**: `%TAG` directive lines are now skipped in the document header (not treated as content). Tag prefix expansion is not implemented — `!`/`!!` shorthands resolve using YAML 1.0 defaults. The emitter can output `--- %YAML:1.0` header.
- **Drift**: None. Graceful skipping of `%TAG` is consistent with 1.0 which did not have the 1.1-style `%TAG` directive.

### Tag URI domain
- **1.0/1.1 shared**: `yaml.org,2002`
- **YAML-Syck**: Uses `YAML_DOMAIN "yaml.org,2002"` — correct for both.
- **Drift**: None.

### Overall finding
**YAML-Syck is genuinely YAML 1.0 compliant in its type system.** No 1.1 or 1.2 drift
was found. The implicit typing rules (booleans, base-60, commas in integers, scientific
notation sign requirement) all match the 1.0 specification. `%TAG` directive lines are
gracefully skipped (not expanded), which is consistent with the 1.0 spec's simpler
directive model. All previously identified test coverage gaps have been addressed.

## Previously Identified Coverage Gaps (all addressed)

| Area | Test File | Tests | Known Limitations |
|---|---|---|---|
| Block scalars (literal, folded, chomping) | `t/yaml-block-scalars.t` | 13 | None |
| Multi-document streams and `...` marker | `t/yaml-multi-document.t` | 34 | None |
| Comments | `t/yaml-comments.t` | 9 | None |
| Merge key (`<<`) | `t/yaml-merge-key.t` | 20 | None |
| Timestamps | `t/yaml-timestamps.t` | 13 | None |
| Directives (`%YAML`, `%TAG`) | `t/yaml-directives.t` | 15 | `%TAG` directives skipped (not expanded); consistent with 1.0 spec |

