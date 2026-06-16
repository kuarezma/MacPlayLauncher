#!/usr/bin/env bash
# Fast Sprint 8 verification — manual real diagnostics check gates.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

FAILURES=0

section() { printf '\n== %s ==\n' "$1"; }
pass()    { printf 'PASS: %s\n' "$1"; }
fail()    { printf 'FAIL: %s\n' "$1"; FAILURES=$((FAILURES + 1)); }

if ./scripts/verify-sprint-6.sh; then
  pass "Sprint 6 base verification"
else
  fail "Sprint 6 base verification"
fi

section "9. Sprint 8 manual real check"
if rg -q 'realCheckButtonTitle|showsManualRealCheckButton' UI/Diagnostics/DiagnosticsViewModel.swift; then
  pass "DiagnosticsViewModel exposes manual real check UI state"
else
  fail "DiagnosticsViewModel missing manual real check UI state"
fi

if rg -q 'runRealSystemCheck|reloadDiagnostics\(mode:' UI/Diagnostics/DiagnosticsView.swift; then
  pass "DiagnosticsView wires manual real check actions"
else
  fail "DiagnosticsView must wire manual real check actions"
fi

if rg -q 'loadSummary\(profiles:.*mode:' Core/Services/Diagnostics/SelectableDependencyDiagnosticService.swift; then
  pass "SelectableDependencyDiagnosticService supports per-request mode"
else
  fail "SelectableDependencyDiagnosticService must support per-request mode"
fi

if rg -q 'loadRuntimeDiagnosticSummary\(mode:' App/AppState.swift; then
  pass "AppState loads diagnostics by requested mode"
else
  fail "AppState must load diagnostics by requested mode"
fi

if rg -q 'reloadDiagnostics\(mode: \.staticOnly\)' UI/Diagnostics/DiagnosticsView.swift; then
  pass "initial diagnostics load stays staticOnly"
else
  fail "DiagnosticsView must load static preparation on appear"
fi

for key in \
  diagnostics.realCheck.button \
  diagnostics.realCheck.loading \
  diagnostics.realCheck.returnToPreparation; do
  if rg -q "\"$key\"" Resources/Localization/Localizable.xcstrings; then
    pass "localization key $key"
  else
    fail "missing localization key $key"
  fi
done

section "Summary"
if [[ "$FAILURES" -eq 0 ]]; then
  printf 'ALL CHECKS PASSED (%s)\n' "fast mode"
  exit 0
else
  printf '%d CHECK(S) FAILED\n' "$FAILURES"
  exit 1
fi
