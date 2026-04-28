#!/usr/bin/env bash
# tests/smoke_cli.sh — exercise the Lean++ CLI surface.
#
# Verifies that the user-facing commands run without crashing and produce
# sensible output. Complements `tests/run_all.sh` (which exercises the
# Lean macro/elaboration path).

set -u

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

LEANPP="$REPO_ROOT/bin/leanpp"
LAKEPP="$REPO_ROOT/bin/lake++"

pass=0
fail=0
fails=()

check() {
  local label="$1"; shift
  local expect_pat="$1"; shift
  local out
  out="$("$@" 2>&1)"
  if printf '%s\n' "$out" | grep -q "$expect_pat"; then
    pass=$((pass + 1))
    printf '  PASS  %s\n' "$label"
  else
    fail=$((fail + 1))
    fails+=("$label")
    printf '  FAIL  %s\n' "$label"
    printf '        expected pattern: %s\n' "$expect_pat"
    printf '%s\n' "$out" | head -3 | sed 's/^/        out: /'
  fi
}

check_exit_nonzero() {
  local label="$1"; shift
  if "$@" > /dev/null 2>&1; then
    fail=$((fail + 1))
    fails+=("$label")
    printf '  FAIL  %s (expected non-zero exit)\n' "$label"
  else
    pass=$((pass + 1))
    printf '  PASS  %s\n' "$label"
  fi
}

echo "=== Lean++ CLI smoke tests ==="

echo "leanpp ..."
check "leanpp --version"       "leanpp"           "$LEANPP" --version
check "leanpp --help"           "transpile"        "$LEANPP" --help
check "leanpp transpile (.leanpp -> .lean)"  " -> " \
  "$LEANPP" transpile examples/abs.leanpp -o /tmp/_smoke_abs.lean

# Linter smoke: a deliberately-malformed file emits diagnostics with
# editor-friendly file:line:col: messages. We piggyback on a heredoc
# tempfile rather than committing a `bad.leanpp` to the repo.
LINT_TMP="$(mktemp).leanpp"
cat > "$LINT_TMP" <<'EOF'
spec def x (n : Nat) : Nat
  ensure n >= 0
by
  proof
    auto

specdef y : Nat := 0
EOF
check "leanpp-transpile lint catches `ensure` typo" \
  "did you mean .ensures." \
  "$REPO_ROOT/bin/leanpp-transpile" "$LINT_TMP"
check "leanpp-transpile lint catches `specdef` typo" \
  "did you mean .spec def." \
  "$REPO_ROOT/bin/leanpp-transpile" "$LINT_TMP"
check_exit_nonzero "leanpp-transpile --strict refuses to write on warnings" \
  "$REPO_ROOT/bin/leanpp-transpile" --strict "$LINT_TMP" -o /tmp/_strict_out.lean
rm -f "$LINT_TMP"
check "leanpp obligations (no crash, grep fallback)" "" "$LEANPP" obligations
check "leanpp trust (kernel: Lean 4 line, grep fallback)" "kernel:" "$LEANPP" trust
check "leanpp obligations FILE.leanpp (env walk)" "Obligations:" \
  "$LEANPP" obligations examples/trust.leanpp
check "leanpp trust FILE.leanpp --ident IDENT (env walk, focused)" \
  "Trust Ledger: TwoListQ.empty" \
  "$LEANPP" trust examples/Queue.leanpp --ident TwoListQ.empty

echo
echo "leanpp new ..."
TMPNEW="$(mktemp -d)"
( cd "$TMPNEW" && "$LEANPP" new smoke_proj > /dev/null 2>&1 )
[ -f "$TMPNEW/smoke_proj/Main.leanpp" ] && \
  { pass=$((pass + 1)); echo "  PASS  leanpp new scaffolds Main.leanpp"; } || \
  { fail=$((fail + 1)); fails+=("leanpp new"); echo "  FAIL  leanpp new"; }
[ -f "$TMPNEW/smoke_proj/lakefile.lean" ] && \
  { pass=$((pass + 1)); echo "  PASS  leanpp new scaffolds lakefile.lean"; } || \
  { fail=$((fail + 1)); fails+=("leanpp new (lakefile)"); echo "  FAIL  leanpp new (lakefile)"; }
rm -rf "$TMPNEW"

echo
echo "leanpp run ..."
check "leanpp run examples/abs.leanpp (transpile + elaborate)" \
  "LeanPP profile set" \
  "$LEANPP" run examples/abs.leanpp
check_exit_nonzero "leanpp run on missing file exits non-zero" \
  "$LEANPP" run /tmp/_nonexistent_smoke_file.leanpp

echo
echo "leanpp clean / doctor ..."
# Generate one artifact so `clean` has something to remove.
"$LEANPP" transpile examples/abs.leanpp > /dev/null 2>&1
check "leanpp clean removes transpiled artifacts" "abs.transpiled.lean" \
  "$LEANPP" clean
check "leanpp doctor reports a healthy environment" "No issues detected" \
  "$LEANPP" doctor

echo
echo "lake++ ..."
check "lake++ --help / no-arg usage" "wrapper around lake" "$LAKEPP"
check_exit_nonzero "lake++ ci --safe-profile fails on current tree (sorry > 0)" \
  "$LAKEPP" ci --safe-profile

# stub commands should print and exit 0.
check "lake++ proof-cache stub" "Phase 2"  "$LAKEPP" proof-cache get
check "lake++ minimize-imports stub" "Phase\\|stub\\|not implemented" "$LAKEPP" minimize-imports

echo
echo "=== Summary ==="
echo "  passed: $pass"
echo "  failed: $fail"
if [ "$fail" != "0" ]; then
  echo "  failures:"
  for x in "${fails[@]}"; do echo "    - $x"; done
  exit 1
fi
echo "All CLI smoke tests passed."
