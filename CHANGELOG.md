# Changelog

All notable changes to Lean++ will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- `LeanPP.Std.List`: Mathlib-free re-implementation of `List.Sorted`
  (specialized to `Nat` for now) and `List.Perm` (polymorphic). These
  used to be inlined verbatim in `examples/insertSorted.leanpp` and
  any user file that wanted the same surface had to copy them. Now
  they ship as a real library module under `LeanPP/Std/`. Opens via
  `open LeanPP.Std.List`. `Perm.refl` is included as a helper that
  the example needed but couldn't construct from Mathlib without
  pulling in the dependency.
- `LeanPP.lean` re-exports `LeanPP.Std.List`, so `import LeanPP`
  alone is still enough.

### Changed

- `examples/insertSorted.leanpp` drops 12 lines of inlined `Sorted`
  / `Perm` definitions in favour of `open LeanPP.Std.List`. The
  example's surface contract is unchanged; this is a refactor that
  exercises the new library module.
- `LeanPP.Std.List.Sorted` generalized from `Sorted : List Nat →
  Prop` to `Sorted [LE α] : List α → Prop`. `Nat` instances flow
  through the global `[LE Nat]` instance unchanged; `List Int`,
  `List String`, etc. now work too.
- `examples/binarySearch.leanpp` drops its inlined
  `LeanPP.Examples.BinarySearch.Array.SortedAsc` definition in
  favour of `open LeanPP.Std.Array`. Same surface contract,
  3 fewer lines, shared library content.

### Added (continued)

- `LeanPP.Std.Array`: Mathlib-free `SortedAsc` predicate for
  `Array`, generalized over `[LE α] [Inhabited α]`. Counterpart to
  `LeanPP.Std.List` for random-access containers. `LeanPP.lean`
  re-exports it.
- `LeanPP.Std.Map`: the abstract `concept Map (α β M : Type)` is
  now a shared stdlib declaration, not a per-example redeclaration.
  Both `examples/BST.leanpp` and `examples/AssocMap.leanpp`
  `open LeanPP.Std` and witness the same concept, so the multi-
  instance story is now end-to-end: one spec, two carriers, a
  single `Map`-typed function body could run against either
  instance.
- `LeanPP.Std.Nat`: `Nat` helpers used by examples or commonly
  needed in algorithms.
  - `log2` (well-founded `n / 2` recursion).
  - `divCeil n d` (ceiling division, `d = 0` ↦ 0).
  - `divCeil_zero` / `divCeil_one` lemmas.
- `tests/lean/StdNatStress.lean`: 16 machine-checked assertions
  pinning `log2` / `divCeil` evaluation and the two lemma
  signatures.

## [0.1.6] — 2026-04-29

CI / build cleanliness pass: every annotation that had piled up
since v0.1.1 is gone. CI is now a single green check with zero
warnings; `lake build` is zero-warning too.

### Added

- `.github/dependabot.yml`: weekly grouped PRs for GitHub Actions
  bumps. Avoids hand-tracking the `actions/checkout` Node.js 20→24
  cutover and any future `leanprover/lean-action` releases. PRs are
  labelled `dependencies` + `github-actions` and use a `ci(deps)`
  commit prefix.
- Dependabot opened and merged its first PR end-to-end — `actions/
  checkout v4 → v6` — silencing the Node.js 20 deprecation
  annotation that had appeared on every CI run since v0.1.1.

### Fixed

- CI workflow now sets `use-github-cache: false` on
  `leanprover/lean-action@v1`. The action's cache key includes
  `github.sha`, so every commit produced a brand-new cache entry
  and the `actions/cache/save@v5` step failed against rate limits.
  Lean++'s `lake build` runs in ~50s on cold cache so the cache
  was saving little to begin with; opting out leaves the
  annotations panel clean.
- `LeanPP/Spec.lean`: `declUsesSorry`'s unused `env` parameter
  renamed to `_env` to silence the linter. The argument is kept in
  the signature for API symmetry with `declIsCurrentModule` (which
  does need the env). `lake build` now produces zero warnings.

[0.1.6]: https://github.com/nktkt/leanpp/releases/tag/v0.1.6

## [0.1.5] — 2026-04-29

UX patch release: a "just run it" CLI command and a README that
actually advertises what's shipped.

### Added

- `leanpp run FILE.leanpp`: transpile and elaborate a single
  `.leanpp` file in one step. Equivalent to
  `leanpp obligations FILE.leanpp` minus the auto-appended
  diagnostic commands — useful when the file already contains its
  own `#trust` / `#obligations` / `#laws` calls and you just want
  to see them. The transpiled output goes to a tempfile and is
  cleaned up on exit, so the source tree stays clean.
- README "A taste" is no longer a single `spec def abs` block. It
  is now a four-section tour (`spec def` / `concept` /
  `proofplan` / diagnostics) quoting verbatim blocks from
  `examples/*.leanpp` so each is reproducible via
  `bin/leanpp run`. README quickstart also mentions
  `bin/leanpp run`.

### Tests

- `tests/smoke_cli.sh` exercises `leanpp run` (success path against
  `examples/abs.leanpp`, non-zero exit on missing file). Suite is
  20 CLI smoke tests; combined regression is 36 / 36.

[0.1.5]: https://github.com/nktkt/leanpp/releases/tag/v0.1.5

## [0.1.4] — 2026-04-29

Test-infrastructure release. Adds three machine-checked stress
test files that pin down macro and tactic behavior independently
of the example suite, so a regression in `LeanPP.Auto`,
`LeanPP.Spec`, or the `concept` / `model` / `obligation` /
`@[law]` machinery surfaces as a clean elaboration failure
instead of silently degrading example outcomes.

### Added

- `tests/lean/AutoStress.lean`: 22 `example`s, one per branch of
  the `auto` and `auto_core` tactic portfolio (rfl, assumption,
  contradiction, decide, omega, simp_all, `leanpp_auto_simp_set`
  lemmas, `And.intro` split, `exact Nat.zero_le _`, `intros` +
  portfolio).
- `tests/lean/SpecDefStress.lean`: eight `spec def` declarations
  spanning the surface forms used across the example suite —
  no-clauses, requires-only, ensures-only, requires + ensures,
  multiple ensures, `decreases` (well-founded recursion),
  `decreases` + `ensures`, and a typeclass-dependent binder. Each
  block `#check`s both the generated `def` and the
  `@[obligation] theorem NAME.ensures_K`.
- `tests/lean/ConceptStress.lean`: nine blocks for the
  non-`spec def` surface — `concept` (data + Prop fields), `model`
  (structure alias), `obligation NAME : PROP`, `@[law]`,
  `@[law, unsolved]` dual-tagging, `#trust IDENT`, `#obligations`,
  `#laws`, and `implementation NAME refines NAME by tac`.
- `tests/run_all.sh` now elaborates every file under `tests/lean/`
  in addition to `examples/*.leanpp` and
  `examples/*.expected.lean`. Suite total: 34 / 34 (16 elaboration
  + 18 CLI smoke) covering ~50 individual machine-checked
  assertions across stress tests and examples.

[0.1.4]: https://github.com/nktkt/leanpp/releases/tag/v0.1.4

## [0.1.3] — 2026-04-29

Patch release on top of v0.1.2: two new examples that exercise
parts of the surface language not previously demonstrated, the
`BST.leanpp` migration to use `spec def` end-to-end now that
`decreases` is wired through, and a new "Known Phase 1 limitations"
section in `CONTRIBUTING.md`.

### Added

- `examples/Newton.leanpp`: integer log base 2 (`log2 n` recursing on
  `n / 2`) elaborated via `spec def` with `decreases n`. The
  decreasing measure is *load-bearing* — without it Lean rejects the
  recursion, since `n / 2` is not a syntactic subterm of `n`. This
  is the first MVP example that genuinely depends on v0.1.2's
  `decreases`-to-`termination_by` threading; existing examples used
  it for naturally-structural recursion where it was technically
  redundant. `native_decide` is used to evaluate the def at sample
  points (`log2 100 = 6`); plain `decide` cannot reduce well-founded
  recursion at the elaborator level.
- `examples/AssocMap.leanpp`: a second instance of the `Map` concept
  over `List (α × β)`. Counterpart to `BST.leanpp` — same abstract
  spec, different carrier. Both `find_empty` and `find_insert_eq`
  close trivially via `unfold; rfl` and `simp [List.lookup]`
  respectively, contrasting BST where the same laws are left as
  open obligations because they need case analysis on `Ord.compare`.
  Demonstrates the multi-instance story: the trust ledger surfaces
  the proof-effort difference between implementations of the same
  concept at-a-glance.
- `CONTRIBUTING.md` gains a "Known Phase 1 limitations" section
  documenting two MVP rough edges so contributors hit them with
  context: `spec def` cannot live inside a `mutual ... end` block
  (Lean 4's mutual grammar rejects arbitrary `command_elab`
  declarations), and `decide` cannot reduce a well-founded
  `spec def` body — use `native_decide` or `simp [NAME]; rfl`.

### Changed

- `examples/BST.leanpp` migrates `find` and `insert` from plain `def`
  to `spec def` with `decreases sizeOf t`. With v0.1.2's
  `decreases`-to-`termination_by` threading the example now exercises
  `spec def` on a recursive carrier — the original v0.1.1 version
  hand-authored both the def and the spec separately because the
  macro could not yet handle non-trivial recursion. Functionality
  unchanged; the file shrinks by 8 lines and demonstrates an
  end-to-end `spec def` use that wasn't possible before v0.1.2.

### Tests

- 31 / 31 (13 elaboration + 18 CLI smoke). Two new elaboration
  entries: `Newton.leanpp` and `AssocMap.leanpp`.

[0.1.3]: https://github.com/nktkt/leanpp/releases/tag/v0.1.3

## [0.1.2] — 2026-04-29

Patch release on top of v0.1.1: a missing-feature fix in `spec def`
plus two CLI conveniences for state hygiene.

### Added

- `spec def` now threads its `decreases EXPR` clause through to the
  generated `def` as `termination_by EXPR`. The clause was already
  parsed in v0.1.0-mvp but its value was dropped; now it actually
  reaches Lean's well-founded-recursion checker. This unlocks
  `spec def` for non-structural recursion (e.g. recursing on a
  custom-ordered tree) where the user must supply a measure.
  `examples/insertSorted.leanpp` already had `decreases xs.length`
  in its surface form; with this fix it elaborates as well-founded
  rather than being silently discarded.
- `leanpp clean`: remove `**/*.transpiled.lean` from cwd recursively.
  With `--all`, also wipe `.lake/` and `build/`. Always reports what
  it touched.
- `leanpp doctor`: diagnose missing tools / project state / LeanPP
  reachability. Probes `lake env lean` with an `import LeanPP` test
  (and dereferences `LeanPP.Trust.obligationAttr`) to confirm the
  stdlib is on the search path. Exits non-zero on any issue. Useful
  as a post-clone smoke check.

### Tests

- `tests/smoke_cli.sh` covers both new commands. Suite is now
  29 / 29 (11 elaboration + 18 CLI).

[0.1.2]: https://github.com/nktkt/leanpp/releases/tag/v0.1.2

## [0.1.1] — 2026-04-28

Post-MVP polish: CI infrastructure, surface-syntax linter, env-walk
diagnostics, extended `auto`, two more examples, and an `unsolved`
attribute synonym that resolves the `obligation`-as-keyword conflict.

### Added

- GitHub Actions CI workflow (`.github/workflows/ci.yml`) that runs
  `lake build` and `tests/run.sh` on every push and PR. Uses
  `leanprover/lean-action@v1` to provision the toolchain pinned in
  `lean-toolchain`.
- README badges for CI, License, and Lean version.
- `CONTRIBUTING.md` covering setup, repository layout, the four
  non-negotiable rules, code style per language, and a prioritized
  what-to-work-on list keyed against `docs/ROADMAP.md`.
- `#laws` command (`LeanPP/Spec.lean`): enumerates every `@[law]`-tagged
  theorem in the current module, marked `[proved]` or `[open]` depending
  on whether it uses `sorryAx`. Mirrors the shape of `#obligations`.
- `#obligations` now filters to current-module decls (was scanning the
  full env, including imports). `#laws` does the same.
- `examples/Queue.leanpp`: FIFO queue concept with a two-list amortised
  implementation. Demonstrates `concept` with explicit carrier
  parameter, an `instance` discharging laws, `@[law]`-tagged free-
  standing theorems (one proved, one open), and `#laws` / `#trust IDENT`
  diagnostics in concert.
- `bin/leanpp obligations FILE.leanpp` and
  `bin/leanpp trust FILE.leanpp [--ident IDENT]`: env-walk path that
  transpiles the file, appends `#obligations` / `#laws` / `#trust`
  commands, and runs `lake env lean` so the diagnostics inspect the
  *real* elaborated environment instead of grepping source. Without a
  file argument both commands keep their grep-based source-scan
  fallback for fast project-wide overview / lake-less environments.
- `bin/leanpp-transpile` now ships a surface-syntax linter:
  - Catches misspelled clause keywords inside `spec def` bodies
    (`ensure` → `ensures`, `require` → `requires`,
    `decrease` → `decreases`, `implmentation` →
    `implementation`, …) and emits editor-friendly diagnostics
    `file.leanpp:LINE:COL: warning: ...`.
  - Catches `specdef` / `spec_def` / `spec  def` (extra space) typos
    at top level as errors.
  - Errors when a `spec def ... by` block has no `implementation`
    sub-block.
  - `--strict` flag escalates warnings to errors and skips writing
    output. `--no-lint` disables the check.
- `tests/smoke_cli.sh` exercises the lint (catches `ensure`,
  `specdef`, and `--strict` exit code). Suite is now 26 / 26 PASS
  (10 elaboration + 16 CLI).

### Changed

- `auto` is now a two-stage portfolio: an `auto_core` of cheap closers
  (`rfl | assumption | contradiction | decide | omega | simp_all |
  leanpp_auto_simp_set | trivial | apply And.intro <;> auto_core ;
  done | exact Nat.zero_le _`) and a wrapper that retries `auto_core`
  after `intros` so quantified ensures-clauses can close.
  `leanpp_auto_simp_set` is a small Nat / Int simp lemma list
  (`Nat.zero_le`, `Nat.le_refl`, `Nat.add_zero`, `Nat.zero_add`,
  `Nat.div_le_self`, `Nat.mod_le`, `Nat.div_mul_le_self`,
  `Int.natAbs_neg`).
- `spec def`'s generated proof now tries `auto`, then `unfold NAME;
  auto`, then `intros; unfold NAME; auto`, then `sorry`. Each branch
  is wrapped in `(...; done)` so `first` cannot accept a branch that
  simplifies the goal but leaves it open. This was a real bug: the
  prior `first | auto | (intros; auto) | sorry` would silently swallow
  partial progress and emit `unsolved goals` instead of falling
  through to a `sorry`-backed obligation.

### Fixed

- The `safeDiv.ensures_1` postcondition in `examples/trust.leanpp`
  (`result * d ≤ n` where `result = n / d`) now closes automatically
  via `Nat.div_mul_le_self` after the spec macro inserts `unfold
  safeDiv`. Sorry-warning count across the example suite drops from
  10 to 9.

### Examples

- `examples/BST.leanpp`: an unbalanced binary search tree as a `Map`.
  Demonstrates the full Lean++ stack on a recursive structure:
  `concept Map`, an `inductive BST`, ordinary recursive `def`s for
  `find` / `insert`, an `instance` discharging the concept, and
  three `@[law]` theorems (one proved, two open and dual-tagged
  `@[law, unsolved]`). Includes `#laws`, `#obligations`, and
  per-decl `#trust` calls. Test suite is now 11 elaboration + 16
  CLI smoke = 27 / 27.
- `@[unsolved]` attribute synonym for `@[obligation]` (`LeanPP/Trust.lean`).
  Both attributes are recognized by `#obligations`, the trust
  ledger, and `bin/leanpp obligations`. The synonym exists because
  `obligation` is also a top-level command keyword (`obligation
  NAME : PROP`), and Lean's attribute parser refuses to parse it
  inside an `@[...]` list without the `«obligation»` guillemet
  escape. `unsolved` is a non-keyword alias that fits naturally,
  e.g. `@[law, unsolved] theorem foo : ... := by sorry`.

[0.1.1]: https://github.com/nktkt/leanpp/releases/tag/v0.1.1

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

[Unreleased]: https://github.com/nktkt/leanpp/compare/v0.1.6...HEAD
[0.1.0-mvp]: https://github.com/nktkt/leanpp/releases/tag/v0.1.0-mvp
