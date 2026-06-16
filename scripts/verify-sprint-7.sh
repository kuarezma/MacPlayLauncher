#!/usr/bin/env bash
# Fast Sprint 7 verification — includes Sprint 6 checks plus source UI polish gates.
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

section "9. Sprint 7 source info card"
if rg -q 'sourceInfoCard' UI/Diagnostics/DiagnosticsView.swift; then
  pass "DiagnosticsView defines sourceInfoCard"
else
  fail "DiagnosticsView must define sourceInfoCard"
fi

if rg -q 'sourceTitle|sourceBadgeText|sourceSubtitle' UI/Diagnostics/DiagnosticsViewModel.swift; then
  pass "DiagnosticsViewModel exposes source info card properties"
else
  fail "DiagnosticsViewModel missing source info card properties"
fi

if rg -q 'Button' UI/Diagnostics/DiagnosticsView.swift; then
  fail "DiagnosticsView must not add buttons in Sprint 7"
else
  pass "no Button in DiagnosticsView"
fi

for key in \
  diagnostics.source.static.title \
  diagnostics.source.static.subtitle \
  diagnostics.source.static.note \
  diagnostics.source.real.title \
  diagnostics.source.noInstall \
  diagnostics.source.dxvkMoltenVKLater; do
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
