#!/usr/bin/env bash
# tests/run_all.sh — Lean++ MVP smoke test.
#
# Runs every `.leanpp` example through the transpiler, then elaborates
# the result against the LeanPP stdlib via `lake env lean`. Asserts that
# every elaboration is error-free. Also elaborates hand-written
# `*.expected.lean` reference files. Exits non-zero on any failure.
#
# Usage: from the repo root, `bash tests/run_all.sh` (or invoke directly
# after `chmod +x`).

set -u

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

LAKE="${LAKE:-$(command -v lake || echo /Users/naoki/.elan/bin/lake)}"
LEANPP="$REPO_ROOT/bin/leanpp"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

pass=0
fail=0
fails=()

run_one() {
  local label="$1"
  local lean_file="$2"
  local out
  out="$("$LAKE" env lean "$lean_file" 2>&1)"
  local errs
  errs="$(printf '%s\n' "$out" | grep -c '^[^:]*:[0-9]*:[0-9]*: error:' || true)"
  if [ "$errs" = "0" ]; then
    pass=$((pass + 1))
    printf '  PASS  %s\n' "$label"
  else
    fail=$((fail + 1))
    fails+=("$label")
    printf '  FAIL  %s (%s errors)\n' "$label" "$errs"
    printf '%s\n' "$out" | grep '^[^:]*:[0-9]*:[0-9]*: error:' | head -3 | sed 's/^/        /'
  fi
}

echo "=== Lean++ MVP test suite ==="
echo "repo: $REPO_ROOT"
echo "lake: $LAKE"
echo

echo "Building stdlib..."
if ! "$LAKE" build > /dev/null 2>&1; then
  echo "  FAIL  lake build"
  exit 1
fi
echo "  PASS  lake build"
echo

echo "Transpiling and elaborating .leanpp examples..."
for f in examples/*.leanpp; do
  out="$TMPDIR/$(basename "$f" .leanpp).lean"
  if ! "$LEANPP" transpile "$f" -o "$out" > /dev/null 2>&1; then
    fail=$((fail + 1))
    fails+=("$(basename "$f") (transpile)")
    printf '  FAIL  %s (transpile)\n' "$(basename "$f")"
    continue
  fi
  run_one "$(basename "$f")" "$out"
done

echo
echo "Elaborating hand-written *.expected.lean reference files..."
for f in examples/*.expected.lean; do
  [ -e "$f" ] || continue
  run_one "$(basename "$f")" "$f"
done

echo
echo "=== Summary ==="
echo "  passed: $pass"
echo "  failed: $fail"
if [ "$fail" != "0" ]; then
  echo "  failures:"
  for x in "${fails[@]}"; do echo "    - $x"; done
  exit 1
fi
echo "All tests passed."
