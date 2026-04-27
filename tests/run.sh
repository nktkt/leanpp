#!/usr/bin/env bash
# tests/run.sh — top-level test runner. Invokes both suites.
set -u

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

fails=0
"$REPO_ROOT/tests/run_all.sh" || fails=$((fails + 1))
echo
"$REPO_ROOT/tests/smoke_cli.sh" || fails=$((fails + 1))

echo
if [ "$fails" = "0" ]; then
  echo "ALL SUITES PASSED."
  exit 0
fi
echo "$fails suite(s) failed."
exit 1
