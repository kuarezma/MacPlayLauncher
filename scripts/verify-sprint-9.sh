#!/usr/bin/env bash
# Fast Sprint 9 verification — real diagnostics result detail UI.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

FAILURES=0

section() { printf '\n== %s ==\n' "$1"; }
pass()    { printf 'PASS: %s\n' "$1"; }
fail()    { printf 'FAIL: %s\n' "$1"; FAILURES=$((FAILURES + 1)); }

if ./scripts/verify-sprint-8.sh; then
  pass "Sprint 8 base verification"
else
  fail "Sprint 8 base verification"
fi

section "10. Sprint 9 real check result details"
if rg -q 'lastRealCheckText|dependencyVersionText|dependencyInstallPathText' UI/Diagnostics/DiagnosticsViewModel.swift; then
  pass "DiagnosticsViewModel exposes real check result detail text"
else
  fail "DiagnosticsViewModel missing real check result detail text"
fi

if rg -q 'lastRealCheckText|dependencyVersionText|dependencyInstallPathText' UI/Diagnostics/DiagnosticsView.swift; then
  pass "DiagnosticsView renders real check result details"
else
  fail "DiagnosticsView must render real check result details"
fi

for key in \
  diagnostics.realCheck.lastChecked \
  diagnostics.dependency.version \
  diagnostics.dependency.installPath; do
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
