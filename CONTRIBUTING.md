# Contributing to Lean++

Thanks for your interest. Lean++ is in early development; this document
describes how to set up, what to work on, and what to keep in mind.

## Setup

You need:

- [`elan`](https://github.com/leanprover/elan) (the Lean version manager)
- Python 3.8 or newer (for the CLI)
- `bash` (for the test runners)

Clone, build, test:

```sh
git clone https://github.com/nktkt/leanpp.git
cd leanpp
lake build
bash tests/run.sh
```

`elan` will read `lean-toolchain` and install the right Lean version
automatically. The full suite (build + 20 tests) finishes in under a
minute on a recent laptop and in about 35 seconds in CI.

## Repository layout

```
bin/                CLI entry points (Python + bash)
LeanPP.lean         stdlib aggregator
LeanPP/             stdlib modules (Spec, Trust, Auto, Refine, Foreign, Project)
examples/           runnable .leanpp programs + abs.expected.lean reference
docs/               design documents and tutorials
tests/              regression suite (run_all.sh, smoke_cli.sh, run.sh)
.github/workflows/  CI configuration
```

## Non-negotiable rules

These are the principles the project must not violate. Pull requests
that break them will be rejected:

1. **The Lean 4 kernel is never modified or bypassed.** Lean++ is
   strictly additive: new tactics, new commands, new attributes. The
   kernel checks every term we produce.
2. **`.lean` files are valid Lean++.** Do not introduce changes that
   break source compatibility.
3. **AI / external solver output is a suggestion, not a proof.** Any
   external proof artifact must be reconstructed and re-verified by
   the kernel before being accepted. See `docs/TRUST_MODEL.md` and
   `docs/AI_PROTOCOL.md`.
4. **Don't ship `sorry` under `#profile safe`.** The `lake++ ci
   --safe-profile` gate enforces this.

## Code style

- **Lean 4 (`LeanPP/*.lean`)**: stay within Lean core; **no Mathlib**,
  **no aesop**. Macros should `elabCommand` ordinary Lean 4 commands.
  Prefer high-level `syntax` + `elab_rules` / `macro_rules` over manual
  `Syntax` construction. Document every public macro with a `/-- … -/`
  doc-string.
- **Python (`bin/leanpp`, `bin/leanpp-transpile`)**: stdlib only, no
  pip dependencies. Type-hinted, `argparse`-driven, robust to missing
  files / missing `lake`.
- **Bash (`bin/lake++`, `tests/*.sh`)**: `set -u`, quote variables,
  use `mktemp -d` for transient state.
- **Docs**: plain markdown, English. No emoji unless the user
  explicitly asks. Keep code blocks self-contained.

## Workflow

1. Fork the repo.
2. Create a topic branch (`feat/foo`, `fix/bar`).
3. Make the change. Run `bash tests/run.sh` locally. Add tests when
   you fix a bug or add a feature.
4. Commit with a descriptive message.
5. Open a PR against `main`. CI must be green.
6. PR description should state which Phase the change targets and
   reference the relevant section of `docs/SYNTAX_RFC.md` or
   `docs/ROADMAP.md` if it touches surface syntax or scope.

## What to work on

Roughly in priority order — see `docs/ROADMAP.md` for the full plan.

### Phase 1 follow-ups (small, well-scoped)

- ~~Make `bin/leanpp obligations` invoke `#obligations` via `lake env
  lean` instead of grepping `.lean` files.~~ Shipped: pass
  `FILE.leanpp` as a positional arg to invoke the env-walk path
  (`#obligations` + `#laws`); no-arg keeps the grep fallback.
- ~~Same for `bin/leanpp trust` (use `#trust`).~~ Shipped: pass
  `FILE.leanpp [--ident IDENT]` for env-walk; no-arg keeps the source
  scan.
- ~~Add a `#laws` command that lists every `@[law]`-tagged theorem.~~
  Shipped in `LeanPP.Spec`.
- ~~Improve `auto` portfolio (e.g. `Nat`-specific closers) without
  pulling in Mathlib.~~ Shipped: two-stage `auto` (bare + `intros`),
  `leanpp_auto_simp_set` of Nat / Int facts, `apply And.intro <;>
  auto_core` for conjunctions, and `unfold NAME` step in the
  generated `spec def` proof.
- ~~Better error messages from the transpiler when a `.leanpp` file
  has malformed `spec def` blocks.~~ Shipped: typo lint
  (`ensure`/`require`/etc.) and structural checks
  (`spec def by` without `implementation`, `specdef` typos at top
  level), plus a `--strict` flag to escalate.
- More `.leanpp` examples covering common data structures (hashmap,
  AVL tree). Queue and (unbalanced) BST are shipped; AVL / red-black
  balanced variants and a hashmap remain on the wishlist.

### Phase 2 (in `docs/ROADMAP.md`)

- Inline `law` keyword inside `concept` / `model` bodies. Requires a
  custom indent-aware parser.
- Real refinement semantics: replace the `Refines` stub class with a
  per-model simulation relation that the macro generates from field
  declarations.
- Proof cache (`lake++ proof-cache get/put/clear`).
- Refactoring-aware proof repair (`lake++ explain-broken-proof`).
- Semantic theorem search (`#find theorem`).
- Mathlib integration as an opt-in extension package.

### Phase 3+

- SMT certificate reconstruction.
- Verified FFI contracts.
- VS Code extension with source maps.
- AI suggestion protocol implementation.

## Reporting bugs / proposing features

Open an issue. Include:

- Lean toolchain version (`lean --version`).
- The smallest `.leanpp` snippet that reproduces the problem.
- The actual vs. expected behavior.

For surface-syntax proposals, mark the issue `proposal:` and quote
the relevant section of `docs/SYNTAX_RFC.md` you want to change.

## License

By contributing you agree that your contributions are licensed under
the MIT License (see `LICENSE`).
