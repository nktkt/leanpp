# Lean++

[![CI](https://github.com/nktkt/leanpp/actions/workflows/ci.yml/badge.svg)](https://github.com/nktkt/leanpp/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Lean 4](https://img.shields.io/badge/Lean-4.30-blue.svg)](https://lean-lang.org/)

**Lean++ = Lean 4 + spec + automation + maintainability + verified SE + AI assistance, kernel-safe.**

Lean++ is an upper-compatible proof-engineering layer on top of Lean 4.
It never modifies or bypasses the Lean 4 kernel: every Lean++ program
lowers to ordinary Lean 4 source that the unmodified kernel checks. The
added value is in the *surface*: specification-first definitions,
reusable proof automation, a trust ledger for every build, and tooling
that scales to real software engineering.

This repository ships the Phase 1 MVP described in `docs/ROADMAP.md`.

## Status

| | |
|--|--|
| `lake build` | passes (9 jobs, 0 errors, 0 warnings) |
| `.leanpp` examples (E2E) | 8 / 8 pass |
| Elaboration tests | 9 / 9 pass |
| CLI smoke tests | 11 / 11 pass |
| Lean toolchain | `leanprover/lean4:v4.30.0-rc2` |
| Mathlib dependency | none (Lean core only) |

Run `bash tests/run.sh` to reproduce.

## What's in the MVP

- A `.leanpp` source format that is a strict superset of `.lean`.
- A small transpiler (`leanpp transpile`) that lowers `.leanpp` to
  `*.transpiled.lean` by injecting `import LeanPP`, desugaring the
  `by implementation BODY proof PROOF` block into the stdlib's
  `:= BODY` form, and wrapping bare `ensures EXPR` (using the magic
  `result` variable) into `ensures fun result => EXPR`. All other
  surface forms are passed through to Lean macros in the `LeanPP`
  stdlib.
- The `LeanPP` library (`LeanPP/*.lean`): Lean 4 macros for
  `spec def`, `concept`, `model`, `implementation … refines …`,
  `obligation`, `proofplan`, the `auto` tactic, and the `#trust` /
  `#trust IDENT` / `#obligations` / `#profile` / `#assertSafe`
  diagnostic commands.
- A `leanpp` CLI: `new`, `transpile`, `transpile-all`, `build`,
  `trust`, `obligations`.
- A `lake++` wrapper around `lake` adding `trust`, `ci --safe-profile`
  (which fails the build when `sorry > 0` or `unsafe > 0`), and stubs
  for `proof-cache`, `minimize-imports`, `explain-broken-proof`,
  `theorem-index`.
- A current-module trust ledger that counts non-baseline axioms,
  `sorry`, `unsafe`, and `@[extern]` usages plus tagged
  `@[obligation]` / `@[law]` declarations. Imports are filtered out so
  the ledger reflects only user code.

## Quickstart

```sh
# Scaffold a new project (does not require Lean installed).
bin/leanpp new my-proj
cd my-proj

# Edit Main.leanpp, then build.
leanpp build
leanpp trust

# Or, to try one of the bundled examples in this repo:
bin/leanpp run examples/abs.leanpp
bin/leanpp run examples/Queue.leanpp
```

The CLI works without Lean for `new`, `transpile`, and `--help`.
`build`, `trust`, and `obligations` require an installed `lake` (the
project uses Lean 4.30; `elan` will pick up `lean-toolchain` and pin
the right version automatically).

## A taste

A short tour of the surface language. Every block here is taken
verbatim from `examples/`; running `bin/leanpp run examples/...`
elaborates each one against the `LeanPP` stdlib.

### `spec def` — function with a postcondition

```lean
#profile safe

spec def abs (x : Int) : Nat
  ensures result ≥ 0
by
  implementation
    if x < 0 then Int.natAbs (-x) else Int.natAbs x
  proof
    auto
```

Lowers to `def abs` plus an `@[obligation] theorem abs.ensures_1`
that the `auto` portfolio (`rfl | assumption | contradiction |
decide | omega | simp_all | leanpp_auto_simp_set | trivial | ...`)
closes automatically.

### `concept` — abstract spec with multiple instances

```lean
concept Map (α : Type) (β : Type) (M : Type) where
  empty   : M
  find    : α → M → Option β
  insert  : α → β → M → M
```

Two implementations of the same concept, side by side
(`examples/BST.leanpp` + `examples/AssocMap.leanpp`), surface
their proof-effort gap on the trust ledger:

```
examples/BST.leanpp        Laws: 3 total, 2 open
examples/AssocMap.leanpp   Laws: 2 total, 0 open
```

### `proofplan` — declarative tactic combinator

```lean
proofplan group_normal
  strategy:
    normalize algebra
    rewrite using [Int.add_assoc, Int.zero_add]
    close by simp

theorem demo (a b : Int) : a + 0 + b = a + b := by
  group_normal
```

Lowers to a `macro` registration: `group_normal` becomes a
first-class tactic name that expands to the planned sequence.

### Diagnostics — `#trust`, `#laws`, `#obligations`

```lean
#trust safeDiv     -- focused per-decl trust ledger
#laws              -- @[law]-tagged theorems with proved/open status
#obligations       -- @[obligation]-tagged theorems with solved/unsolved status
```

Each command walks the elaborated environment and filters to the
current module so imported decls don't pollute the report. With
`#profile safe`, an `obligation` left as `sorry` blocks the build
via `lake++ ci --safe-profile`.

## Trust ledger

```lean
#trust              -- snapshot for the current module
#trust myFunction   -- focused entry for one declaration
#assertSafe        -- error if the current env contains any sorry / extra axiom
```

Sample output for a clean spec under `#profile safe`:

```
Trust Ledger: safeDiv
  kernel:     Lean 4 (unmodified)
  profile:    safe
  sorry:      no
  unsafe:     no
  extern:     no
  obligation: no
  law:        no
  axioms: 0
  baseline axioms: Classical.choice, Quot.sound, propext
```

## Layout

```
bin/leanpp, bin/lake++, bin/leanpp-transpile  -- CLI entry points
lakefile.lean, lean-toolchain                 -- Lake package definition
LeanPP.lean, LeanPP/*.lean                    -- Lean++ standard library
examples/*.leanpp                             -- runnable example specs
docs/*.md                                     -- design documents
tests/run.sh, tests/run_all.sh, tests/smoke_cli.sh  -- regression suite
```

## Further reading

- `docs/MANIFESTO.md` — the design rationale and four core principles.
- `docs/COMPATIBILITY.md` — Lean 4 source-compatibility rules.
- `docs/TRUST_MODEL.md` — kernel-safety story and the
  reconstruct-or-reject policy for external solvers / AI suggestions.
- `docs/SYNTAX_RFC.md` — surface-syntax RFC (per-construct semantics
  and lowering).
- `docs/TUTORIAL.md` — hands-on walkthrough using the MVP CLI.
- `docs/ROADMAP.md` — Phase 0 → Phase 5 plan with success metrics.
- `docs/ARCHITECTURE.md`, `docs/PROFILES.md`, `docs/AI_PROTOCOL.md` —
  layered design, profile semantics, and AI-as-suggestion policy.
- `examples/README.md` — what each `.leanpp` example demonstrates.

## Non-goals

Lean++ does **not** replace the Lean 4 kernel, ship Lean 3 compatibility,
trust AI output as proof, fork mathlib, or claim full automation. Its
value is the engineering layer: write specs naturally, generate
obligations automatically, keep proofs from breaking, make trust
boundaries visible, and use AI / SMT solvers safely as suggestions
that the Lean kernel re-verifies.

## License

MIT. See `LICENSE`.
