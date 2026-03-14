# YAML-Syck C/XS Layer Code Review

**Date**: 2026-03-14
**Scope**: Memory safety, correctness, and security of the C/XS parser and emitter
**Reviewer**: Koan (autonomous agent)

---

## Summary

YAML-Syck bundles libsyck 0.61, a C YAML parser from 2005, with Perl XS bindings.
The codebase is mature but shows its age: manual memory management throughout,
generated lexer/parser code, and several latent issues ranging from a heap overflow
to incorrect base64 decoding.

**Note**: The original mission was "Review database schema" which does not apply to
this project (YAML-Syck is a YAML/JSON parser with zero database code). This review
covers the C/XS layer instead, focusing on areas most likely to cause real-world bugs.

---

## Findings

### HIGH: Heap buffer overflow in emitter tag buffer

**File**: `perl_syck.h:1286` (allocation), `perl_syck.h:963` (overflow)

The emitter allocates a fixed 512-byte buffer for YAML type tags:

```c
// perl_syck.h:1286
New(801, bonus->tag, 512, char);
```

During emission of blessed Perl objects, the class name is appended without bounds checking:

```c
// perl_syck.h:906-963
*tag = '\0';
strcat(tag, OBJECT_TAG);       // "tag:!perl:" (10 chars)
strcat(tag, "array:");         // up to 7 chars for type prefix
strcat(tag, ref);              // CLASS NAME - UNBOUNDED
```

A Perl object blessed into a class with a name longer than ~490 characters will
overflow this heap-allocated buffer. While unusual, this is reachable from untrusted
input when round-tripping YAML that contains `!perl/hash:Very::Long::Class::Name`.

**Severity**: High (heap corruption, potential code execution)
**Fix**: Use `snprintf` or dynamically size the buffer based on `strlen(ref)`.

---

### MEDIUM: Base64 decoder double-writes on padding

**File**: `emitter.c:93-99`

The base64 padding handler has a logic error:

```c
if (a != -1 && b != -1) {
    if (s + 2 < send && s[2] == '=')
        *end++ = a << 2 | b >> 4;              // line 95
    if (c != -1 && s + 3 < send && s[3] == '=') {
        *end++ = a << 2 | b >> 4;              // line 97 - DUPLICATE of line 95
        *end++ = b << 4 | c >> 2;              // line 98
    }
}
```

When input has `==` padding (1-byte final block), line 95 writes byte 1. Then the
second `if` on line 96 cannot fire (c would be -1 for `=`), so this is safe.

But when input has single `=` padding (2-byte final block), line 95's condition
`s[2] == '='` is false, then line 96 fires and writes 2 bytes — which is correct.
However, there's a subtle issue: if `s[2]` is the `=` AND `c != -1` (which
contradicts), the first byte gets written twice. The conditions are mutually
exclusive in practice, but the code structure is fragile and confusing.

**Severity**: Medium (confusing logic, potential for incorrect decode on malformed input)
**Fix**: Restructure as `if/else if` to make mutual exclusivity explicit.

---

### MEDIUM: Base64 decoder unbounded newline skip

**File**: `emitter.c:83`

```c
while (s[0] == '\r' || s[0] == '\n') { s++; }
```

This loop skips whitespace but does not check `s < send`, so it can read past the
end of the input buffer if the input ends with newlines. In practice the input
comes from `syck_strndup` which null-terminates, so `\0` would stop the loop.
But relying on null-termination for a function that explicitly takes a length
parameter is fragile.

**Severity**: Medium (potential out-of-bounds read on pathological input)
**Fix**: Add `s < send` guard to the while condition.

---

### MEDIUM: `strtok` mutates type_id in-place

**File**: `perl_syck.h:335, 365, 430, 483, 530, 582`

Multiple locations use `strtok(id, "/:")` where `id` points to `n->type_id`.
`strtok` replaces delimiters with `\0`, permanently corrupting the `type_id` string.

```c
char *lang = strtok(id, "/:");    // mutates n->type_id
char *type = strtok(NULL, "");
```

Since nodes are freed shortly after handler execution, this doesn't cause
use-after-mutation bugs in normal flow. But it makes the code brittle:
if anyone adds logging or error handling that reads `type_id` after parsing,
they'll get a truncated string with no obvious reason.

**Severity**: Medium (correctness hazard, maintenance trap)
**Fix**: Use `strchr`/`strrchr` instead of `strtok`, or work on a copy.

---

### LOW: Memory leak in `syck_hdlr_add_anchor` on double-anchor

**File**: `handler.c:35-43`

When a node already has an anchor and a second anchor is applied:

```c
if (n->anchor != NULL) {
    return n;    // returns early, 'a' is leaked
}
n->anchor = a;
```

The newly allocated anchor string `a` is never freed. This leak occurs only
on malformed YAML (`&anchor1 &anchor2 value`), so impact is low.

**Severity**: Low (memory leak on invalid input only)
**Fix**: `S_FREE(a)` before the early return.

---

### LOW: Static mutable state in base64 decoder

**File**: `emitter.c:65-66`

```c
static int first = 1;
static int b64_xtable[256];
```

The lookup table is initialized lazily with a `static` flag. This is not
thread-safe: two threads calling `syck_base64dec` simultaneously on first
use could race on initialization. Unlikely to cause issues in Perl (GIL),
but technically undefined behavior.

**Severity**: Low (thread-safety, unlikely in practice with Perl's GIL)

---

### INFO: Deprecated blessing patterns

**File**: `perl_syck.h:439-440, 591-592`

```c
/* FIXME deprecated - here compatibility with @Foo::Bar style blessing */
while ( *type == '@' ) { type++; }
```

These date from YAML.pm 0.35 compatibility. They strip `@` and `%` prefixes
from type names. The FIXME comments are over a decade old. Consider removing
if YAML.pm 0.35 compat is no longer needed.

---

### INFO: Multiple XXX/TODO/FIXME markers

Found 11 unresolved markers across the codebase:

| File | Line | Note |
|------|------|------|
| `perl_syck.h` | 302 | `XXX no sv_catsv!` |
| `perl_syck.h` | 322 | `XXX seems to be necessary` (SvREFCNT_inc) |
| `perl_syck.h` | 688 | `TODO: need test case to prove this does not work` |
| `perl_syck.h` | 1225 | `XXX TODO XXX` (format type emission) |
| `perl_syck.h` | 1380 | `XXX: needs to handle magic?` |
| `emitter.c` | 486 | `TODO: Invalid tag (no colon after domain)` |
| `emitter.c` | 818 | `XXX scalar_fold overloaded to mean utf8` |
| `token.c` | 574 | `XXX: Comment lookahead` |
| `token.c` | 2006 | `FIXME` (DoubleQuote newline handling) |

---

## Architecture Notes

The dual-include pattern of `perl_syck.h` (once with `YAML_IS_JSON=1`, once without)
is clever but makes the code hard to navigate. A reader must mentally track which
`#ifdef` branch they're in. Modern approaches would use separate source files with
shared helpers.

The `SYMID` type is used to store both integer IDs and cast Perl `SV*` pointers
(`(SYMID)sv`), which is a type-safety concern on architectures where
`sizeof(SYMID) != sizeof(void*)`.

---

## Recommendations

1. **Fix the tag buffer overflow** (HIGH) — this is the most impactful finding.
   Dynamic allocation based on class name length is the correct fix.
2. **Add bounds check to base64 newline skip** — simple one-line fix.
3. **Replace `strtok` with non-destructive parsing** — improves maintainability.
4. **Free leaked anchor in double-anchor case** — trivial fix.
5. Consider a fuzz testing pass with AFL or libFuzzer on the parser — the codebase
   has the profile of code that benefits enormously from fuzzing (C, manual memory
   management, complex input parsing).
