# Lean++ Examples

This directory contains short, pedagogical Lean++ source files (`.leanpp`)
that exercise the surface syntax of the MVP: `spec def`, `ensures`,
`requires`, `concept`/`law`, `model`/`refines`, `proofplan`, `obligation`,
and the `#profile` / `#obligations` / `#trust` diagnostics.

These files are illustrative source. They are not meant to be compiled
directly with `lean`; instead they pass through `bin/leanpp transpile
FILE.leanpp` (concurrently being built) which lowers them to ordinary
Lean 4. See `abs.expected.lean` for the shape of the lowering target on the
canonical `abs` example.

| File | Demonstrates | E2E status |
|------|--------------|------------|
| abs.leanpp | spec def, ensures, auto | PASS (0 warnings) |
| insertSorted.leanpp | multiple ensures, recursion, decreases | PASS (sorry warning) |
| binarySearch.leanpp | array spec, option result, multi-line ensures, obligation | PASS (sorry warning) |
| simpleParser.leanpp | Option result, obligations, #obligations | PASS (sorry warning) |
| trust.leanpp | #profile safe, #obligations, #trust | PASS (sorry warning) |
| Stack.leanpp | model + implementation refines | PASS (0 warnings) |
| Queue.leanpp | concept with carrier + impl + @[law] + #laws + #trust IDENT | PASS (sorry warning) |
| BST.leanpp | inductive carrier + recursive find/insert + multi-attribute @[law, unsolved] + #laws + #obligations | PASS (sorry warnings) |
| AssocMap.leanpp | second `Map` instance over `List (α × β)`; both `find_empty` and `find_insert_eq` close, contrasting BST's open laws | PASS (0 warnings) |
| Newton.leanpp | well-founded recursion via `spec def + decreases n` on a non-structural measure (`log2 n` recursing on `n / 2`); `native_decide` evaluates the def | PASS (sorry warning) |
| concepts.leanpp | concept + @[law] + instance | PASS (0 warnings) |
| proofplan.leanpp | proofplan combinator (named tactic alias) | PASS (0 warnings) |

E2E status was measured by `bin/leanpp transpile FILE.leanpp` then
`lake env lean OUTPUT.lean`. PASS means zero `error:` lines; warnings are
`declaration uses sorry` from intentionally deferred proofs that are
recorded as `obligation`s.

## Phase 1 surface limitations (intentional, deferred to Phase 2)

- `concept` and `model` bodies do not have an inline `law` keyword;
  every field — data or proposition — is written as `name : type`. To
  tag a free-standing theorem as a structural law, use `@[law] theorem
  ...` (the `law` attribute is registered in `LeanPP.Trust`).
- `implementation NAME refines NAME` takes two plain identifiers (both
  expected to be types). The `Refines` class is a stub that the default
  `trivialRefines` instance always discharges; a real refinement
  semantics is project-specific.
- `proofplan` strategies cover `normalize algebra`, `rewrite using
  IDENT`, `rewrite using [IDENT, ...]`, `close by simp | auto | omega |
  decide`. The `close by ...` step tolerates the case where an earlier
  step already closed the goal.

## Running

From the repo root:

```
bin/leanpp transpile examples/abs.leanpp -o /tmp/abs.lean
lake env lean /tmp/abs.lean

bin/leanpp transpile examples/trust.leanpp -o /tmp/trust.lean
lake env lean /tmp/trust.lean
# prints `Obligations: ...` and `Trust Ledger (LeanPP MVP)`

bin/leanpp obligations    # grep-based scan of .lean files in cwd
bin/leanpp trust          # grep-based trust ledger for the project
```

## Reading order

If you are new to Lean++, read the examples in this order:

1. `abs.leanpp` and `abs.expected.lean` -- the canonical hello-world and
   what it lowers to.
2. `concepts.leanpp` -- algebraic structures with `concept` and `law`.
3. `insertSorted.leanpp` -- recursion with two `ensures` clauses.
4. `proofplan.leanpp` -- declarative proof strategies.
5. `Stack.leanpp` -- abstract `model` refined by a concrete implementation.
6. `binarySearch.leanpp` and `simpleParser.leanpp` -- larger specs whose
   proofs are deferred to Phase 2.
7. `trust.leanpp` -- the trust ledger and obligation diagnostics.

## Phase 2 notes

Several examples rely on local stubs (e.g. `Sorted`, `Perm`, `SortedAsc`)
to stay self-contained without Mathlib. In Phase 2 those stubs can be
removed in favour of the Mathlib definitions. The `sorry` proofs in
`binarySearch.leanpp` and `simpleParser.leanpp` are intentional and are
recorded as `obligation`s, so `#obligations` will surface them.
