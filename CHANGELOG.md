# Changelog

All notable changes to Lean++ will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

Nothing yet.

## [0.1.0-mvp] — 2026-04-28

First public release. Implements the Phase 1 MVP scope from
[`docs/ROADMAP.md`](docs/ROADMAP.md).

### Added

- **Surface language** (`LeanPP/Spec.lean`):
  - `spec def NAME (ARGS) : T requires P ensures Q [decreases E] := BODY`
    lowers to `def NAME` plus one `@[obligation] theorem NAME.ensures_k`
    per `ensures` clause, closed by `auto`.
  - `concept NAME (α : Type) where ...` using Lean's native
    `structFields` grammar.
  - `obligation NAME : PROP` lowers to `@[obligation] theorem NAME := by
    sorry`.
  - `#obligations` enumerates every `@[obligation]`-tagged declaration
    with solved/unsolved status.
- **Refinement DSL** (`LeanPP/Refine.lean`):
  - `model NAME (...) where ...` aliases `structure`.
  - `implementation IMPL refines MODEL by tac` lowers to a
    `theorem IMPL.refines_MODEL : Refines IMPL MODEL` discharged by the
    user-supplied tactic (with a `trivialRefines` default instance for
    MVP).
- **Automation** (`LeanPP/Auto.lean`):
  - `auto` portfolio tactic: `rfl | assumption | contradiction | decide |
    omega | simp_all | simp | trivial`.
  - `auto?` no-fail variant.
  - `proofplan NAME strategy: ...` registers a callable named tactic
    via dynamic macro emission. Strategies: `normalize algebra`,
    `rewrite using IDENT`, `rewrite using [IDENT, ...]`,
    `close by simp | auto | omega | decide`.
- **Trust model** (`LeanPP/Trust.lean`):
  - `register_option leanpp.profile : String` with values `safe |
    research | systems | education`.
  - `#profile <name>` command.
  - `#trust` prints a current-module ledger (filters out imports so
    Lean core noise is excluded).
  - `#trust IDENT` prints a focused entry with transitive axiom walk.
  - `#assertSafe` errors if any user decl uses `sorryAx` or a
    non-baseline axiom.
  - `@[obligation]` and `@[law]` tag attributes.
- **Foreign / FFI scaffolding** (`LeanPP/Foreign.lean`): `verified
  extern` syntax that pairs `@[extern]` with a sorry-backed contract
  theorem tagged `@[obligation, ffi_contract, verified_extern]`.
- **CLI** (`bin/`):
  - `leanpp new`, `leanpp transpile`, `leanpp transpile-all`,
    `leanpp build`, `leanpp trust`, `leanpp obligations`,
    `leanpp --version`, `leanpp --help`.
  - `leanpp-transpile`: header injection, `by implementation/proof`
    desugaring, multi-line `ensures` continuation, profile passthrough.
    Default output suffix `.transpiled.lean` matches `.gitignore`.
  - `lake++` wrapper: `lake++ build`, `lake++ trust`, `lake++ ci
    --safe-profile` (fails build when `sorry > 0` or `unsafe > 0`),
    plus stubs for `proof-cache`, `minimize-imports`,
    `explain-broken-proof`, `theorem-index`.
- **Examples** (`examples/*.leanpp`): `abs`, `insertSorted`,
  `binarySearch`, `simpleParser`, `Stack`, `concepts`, `proofplan`,
  `trust`. All 8 elaborate cleanly through transpile + LeanPP.
- **Documentation** (`docs/`): MANIFESTO, COMPATIBILITY, TRUST_MODEL,
  SYNTAX_RFC, TUTORIAL, ROADMAP, ARCHITECTURE, PROFILES, AI_PROTOCOL.
- **Tests** (`tests/`): `run_all.sh` (elaboration), `smoke_cli.sh`
  (CLI surface), `run.sh` (top-level runner). 20 / 20 pass.
- **CI**: GitHub Actions workflow runs `lake build` and `tests/run.sh`
  on push and PR.

### Phase 1 limitations (deferred to Phase 2)

- Inline `law` keyword inside `concept` / `model` bodies. The MVP uses
  `@[law] theorem ...` outside the body.
- `Refines` semantics: the stub class is always discharged by the
  default `trivialRefines` instance. Real refinement needs project-
  specific simulation relations.
- `lake++` proof-cache, minimize-imports, explain-broken-proof, and
  theorem-index are stubs.
- The `bin/leanpp trust` and `bin/leanpp obligations` CLI commands use
  grep-based scans. The Lean-side `#trust` / `#obligations` commands
  do proper environment walks.
- VS Code source map / language server integration is not in this
  release.

[Unreleased]: https://github.com/nktkt/leanpp/compare/v0.1.0-mvp...HEAD
[0.1.0-mvp]: https://github.com/nktkt/leanpp/releases/tag/v0.1.0-mvp
