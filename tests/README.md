# Lean++ MVP test suite

Two complementary suites that together cover the MVP surface end-to-end.

## Suites

| Script | What it covers |
|--------|----------------|
| `run_all.sh` | Builds the LeanPP stdlib via `lake build`, transpiles every `.leanpp` example, elaborates each generated `.lean` against the stdlib, and elaborates hand-written `*.expected.lean` reference files. Asserts zero `error:` lines. |
| `smoke_cli.sh` | Exercises the user-facing CLI: `leanpp --version`, `--help`, `transpile`, `obligations`, `trust`, `new`; and `lake++` (no-arg usage, `ci --safe-profile`, stubs). |

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

## Notes

- Tests use `mktemp -d` for transpiled output, so they never pollute the
  source tree.
- `lake++ ci --safe-profile` is expected to fail on the current example
  tree because intentional `obligation`s and one stdlib `unsafe def`
  push `sorry` and `unsafe` counts above zero. The CI smoke check
  asserts this non-zero exit.
- `LAKE` and `LEANPP` env vars (auto-resolved) override the lake/leanpp
  binaries used by the runners.
