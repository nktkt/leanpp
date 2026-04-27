# Lean 4 Source Compatibility

Lean++ commits to **100% source compatibility** with Lean 4. This document
specifies what that means concretely, what Lean++ may add, and what it
must never change.

If a future Lean++ release breaks any rule below, that release is
considered non-conformant.

---

## The Rule (one sentence)

> Every well-formed `.lean` file is a well-formed Lean++ input, and every
> theorem accepted by Lean++ is a theorem accepted by the unmodified Lean 4
> kernel.

---

## Two file extensions, one language

| Extension | Contents | Tooling |
|-----------|----------|---------|
| `.lean` | Plain Lean 4. No Lean++ surface syntax required. | `lean`, `lake`, `lake++`. |
| `.leanpp` | Lean 4 plus Lean++ surface syntax (`spec def`, `obligation`, `proofplan`, ...). | `leanpp transpile`, `lake++`. |

`.leanpp` files are **lowered** to ordinary `.lean` files by the Lean++
elaborator/transpiler. The lowered form is what the Lean kernel sees. The
relationship is:

```
.leanpp  ──[lowering]──▶  .lean  ──[Lean 4 elaborator]──▶  .olean
```

A project may freely mix `.lean` and `.leanpp` files. They share namespaces
and imports.

See [ARCHITECTURE.md](./ARCHITECTURE.md) for the full pipeline.

---

## What Lean++ MAY add

Lean++ extensions are strictly **additive**. They never reinterpret existing
Lean syntax. The categories of allowed extension are:

### 1. New surface syntax (only in `.leanpp`)

New top-level forms such as:

- `spec def`
- `concept`
- `law`
- `model` / `implementation ... refines ...`
- `obligation NAME : PROP`
- `proofplan`

These exist only inside `.leanpp` and lower to ordinary Lean 4
`def` / `theorem` / `class` / `structure` / `macro` declarations. See
[SYNTAX_RFC.md](./SYNTAX_RFC.md).

### 2. New tactics

Tactics like `auto` and named `proofplan` calls are new tactic identifiers.
They are implemented as ordinary Lean 4 macros / elaborators. They never
shadow built-in tactics.

### 3. New commands

User-level commands such as:

- `#obligations`
- `#trust`
- `#profile`
- `#find theorem`

Each is registered through the standard Lean 4 command extension mechanism.

### 4. New attributes

Attributes such as `@[law]` (mark a theorem as part of a structure's law
set) or trust-ledger annotations are registered through the standard Lean
attribute system.

### 5. Tooling and metadata

- `lake++` — a Lake plugin / wrapper providing `proof-cache`, `trust`,
  `ci`, `explain-broken-proof`, `minimize-imports`, `theorem-index`. It
  invokes plain `lake` underneath.
- Source maps for editor tooling (so `.leanpp` errors point back at
  original lines).

None of these touch the kernel or the elaborator's term representation.

---

## What Lean++ MUST NOT change

These are the immutable parts of the Lean 4 platform.

| Component | Status |
|-----------|--------|
| Lean 4 kernel | Never modified, never replaced, never bypassed. |
| Term / expression representation (`Expr`) | Unchanged. |
| Type checker | Unchanged. |
| Reduction rules / definitional equality | Unchanged. |
| Axioms (`Classical.choice`, `propext`, `Quot.sound`) | Unchanged. The `axiom` set is exactly Lean 4's. |
| Existing Lean 4 syntax meaning | Unchanged. No reinterpretation of existing keywords. |
| `import` resolution | Unchanged. Lean++ does not introduce parallel module systems. |
| mathlib | Used as-is. Not forked, not patched. |

Any future Lean++ feature that would require changing one of these is
out-of-scope by definition.

---

## Mixing rules

- A `.leanpp` file may `import` any `.lean` or `.leanpp` file.
- A `.lean` file may `import` the *lowered* form of a `.leanpp` file. This
  is automatic: lowering produces a normal `.lean` (or `.olean`) artefact.
- Lean 4 tools (LSP, mathlib's CI) work on the lowered output.
- `lake++` is a strict superset of `lake`: any `lake <cmd>` is a valid
  `lake++ <cmd>`.

---

## Profile rules and compatibility

Profiles change *what is accepted*, not *what is sound*. Concretely:

- `#profile safe` may **reject** a file that contains `sorry` even though
  Lean 4 itself would accept it. This is a stricter mode, not a different
  semantics.
- A profile cannot make the kernel accept anything it would otherwise
  reject.
- A file with no `#profile` directive defaults to `research` (the most
  permissive trackable mode), preserving plain-Lean behavior except for
  the addition of trust-ledger reporting.

See [PROFILES.md](./PROFILES.md).

---

## Migration guarantees

For a Lean 4 project adopting Lean++:

1. The project compiles unchanged under `lake++ build`.
2. No file needs renaming.
3. No `import` needs changing.
4. mathlib continues to work.
5. Lean++ surface syntax can be introduced **file-by-file** by renaming
   `.lean` → `.leanpp` only where desired.
6. Reverting Lean++ is just as easy: lower all `.leanpp` files to `.lean`
   via `leanpp transpile`, drop the Lean++ tooling, and you are back to a
   plain Lean 4 project.

---

## What changes vs. plain Lean 4 (additive only)

| Area | Plain Lean 4 | Lean++ |
|------|--------------|--------|
| File extensions | `.lean` | `.lean` and `.leanpp` |
| Function definitions | `def`, `theorem` | also `spec def` (lowered to `def` + `theorem`) |
| Class-like bundles | `class`, `structure` | also `concept` (a `class` + bundled `law`s) |
| Refinement | (manual) | `model` / `refines` syntax |
| Proof obligations | (manual) | `obligation` + `#obligations` |
| Tactic libraries | `simp`, `omega`, ... | also `auto`, `proofplan` |
| Trust audit | (none built-in) | `#trust`, `lake++ trust` |
| Profiles | (none) | `#profile safe / research / systems / education` |
| Build tool | `lake` | `lake` + `lake++` |

Note that the left column always still works. The right column adds.

---

## Versioning

- Lean++ tracks Lean 4 by `lean-toolchain`. A given Lean++ release pins a
  specific Lean 4 version.
- Lean++ syntax is versioned (Lean++ 0.x experimental, Lean++ 1.0 stable).
- A breaking change to **Lean++ surface syntax** is allowed before 1.0; a
  breaking change to **kernel compatibility** is never allowed.

---

## Related

- [MANIFESTO.md](./MANIFESTO.md) — overall principles
- [TRUST_MODEL.md](./TRUST_MODEL.md) — what soundness means here
- [SYNTAX_RFC.md](./SYNTAX_RFC.md) — concrete added syntax
- [ARCHITECTURE.md](./ARCHITECTURE.md) — how `.leanpp` flows to `.lean`
