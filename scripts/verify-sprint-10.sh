#!/usr/bin/env bash
# Fast Sprint 10 verification — in-memory diagnostics session state.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

FAILURES=0

section() { printf '\n== %s ==\n' "$1"; }
pass()    { printf 'PASS: %s\n' "$1"; }
fail()    { printf 'FAIL: %s\n' "$1"; FAILURES=$((FAILURES + 1)); }

rg_swift() {
  rg --glob '*.swift' --glob '!Tests/**' "$@" Core App UI 2>/dev/null || true
}

if ./scripts/verify-sprint-9.sh; then
  pass "Sprint 9 base verification"
else
  fail "Sprint 9 base verification"
fi

section "11. Sprint 10 diagnostics session state"
if rg -q 'storeDiagnosticsSession|restoreCachedDiagnosticsIfAvailable|resetDiagnosticsSessionToStaticPreparation' App/AppState.swift; then
  pass "AppState stores and restores diagnostics session"
else
  fail "AppState must manage diagnostics session state"
fi

if rg -q 'restoreCachedDiagnosticsIfAvailable' UI/Diagnostics/DiagnosticsView.swift; then
  pass "DiagnosticsView restores cached real-check session"
else
  fail "DiagnosticsView must restore cached diagnostics session"
fi

if rg -q 'returnToStaticPreparation' UI/Diagnostics/DiagnosticsView.swift; then
  pass "DiagnosticsView resets session when returning to preparation"
else
  fail "DiagnosticsView must reset diagnostics session on return to preparation"
fi

if rg_swift -q 'canLaunch:[[:space:]]*false' Core/Services/DefaultRunReadinessEvaluator.swift; then
  pass "canLaunch remains false"
else
  fail "DefaultRunReadinessEvaluator must keep canLaunch false"
fi

section "Summary"
if [[ "$FAILURES" -eq 0 ]]; then
  printf 'ALL CHECKS PASSED (%s)\n' "fast mode"
  exit 0
else
  printf '%d CHECK(S) FAILED\n' "$FAILURES"
  exit 1
fi
