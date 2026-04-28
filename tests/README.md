# Lean++ MVP test suite

Two complementary suites that together cover the MVP surface end-to-end.

## Suites

| Script | What it covers |
|--------|----------------|
| `run_all.sh` | Builds the LeanPP stdlib via `lake build`, transpiles every `.leanpp` example, elaborates each generated `.lean` against the stdlib, elaborates hand-written `*.expected.lean` reference files, and elaborates every `tests/lean/*.lean` stress test. Asserts zero `error:` lines. |
| `smoke_cli.sh` | Exercises the user-facing CLI: `leanpp --version`, `--help`, `transpile`, `obligations`, `trust`, `new`, `clean`, `doctor`, lint; and `lake++` (no-arg usage, `ci --safe-profile`, stubs). |

`run.sh` runs both in sequence.

## Usage

From the repository root:

```
bash tests/run.sh           # run everything
bash tests/run_all.sh       # elaboration only
bash tests/smoke_cli.sh     # CLI surface only
```

## Expected output (current MVP)

`run_all.sh`:
```
=== Lean++ MVP test suite ===
Building stdlib...
  PASS  lake build
Transpiling and elaborating .leanpp examples...
  PASS  abs.leanpp
  PASS  binarySearch.leanpp
  PASS  concepts.leanpp
  PASS  insertSorted.leanpp
  PASS  proofplan.leanpp
  PASS  simpleParser.leanpp
  PASS  Stack.leanpp
  PASS  trust.leanpp
Elaborating hand-written *.expected.lean reference files...
  PASS  abs.expected.lean
=== Summary ===
  passed: 9
  failed: 0
```

`smoke_cli.sh`: 11 checks covering both `leanpp` and `lake++`.

## tests/lean/

Lean 4 stress tests. Each file is a self-contained `import LeanPP`
script of `example`s that exercise specific stdlib features.

| File | Coverage |
|------|----------|
| `AutoStress.lean` | One `example` per branch of the `auto` portfolio: rfl, assumption, contradiction, decide, omega, simp_all, leanpp_auto_simp_set lemmas, And.intro split, Nat.zero_le, intros + portfolio. Catches regressions in `LeanPP.Auto`. |
| `SpecDefStress.lean` | Eight `spec def` declarations covering the surface forms used across `examples/*.leanpp`: no clauses, requires only, ensures only, requires + ensures, multiple ensures, decreases, decreases + ensures, typeclass-dependent binder. Each block `#check`s both the generated `def` and the `@[obligation] theorem NAME.ensures_K` to fail elaboration on a regression in the macro's lowering. |

Add new files here when introducing a new tactic or surface form.

## Notes

- Tests use `mktemp -d` for transpiled output, so they never pollute the
  source tree.
- `lake++ ci --safe-profile` is expected to fail on the current example
  tree because intentional `obligation`s and one stdlib `unsafe def`
  push `sorry` and `unsafe` counts above zero. The CI smoke check
  asserts this non-zero exit.
- `LAKE` and `LEANPP` env vars (auto-resolved) override the lake/leanpp
  binaries used by the runners.
