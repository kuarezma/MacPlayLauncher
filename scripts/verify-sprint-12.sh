#!/usr/bin/env bash
# Fast Sprint 12 verification — settings diagnostics overview.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

FAILURES=0

section() { printf '\n== %s ==\n' "$1"; }
pass()    { printf 'PASS: %s\n' "$1"; }
fail()    { printf 'FAIL: %s\n' "$1"; FAILURES=$((FAILURES + 1)); }

if ./scripts/verify-sprint-11.sh; then
  pass "Sprint 11 base verification"
else
  fail "Sprint 11 base verification"
fi

section "13. Sprint 12 settings diagnostics overview"
if rg -q 'diagnosticsSessionSourceLabel' App/AppState.swift; then
  pass "AppState exposes diagnostics session source label"
else
  fail "AppState must expose diagnostics session source label"
fi

if rg -q 'settings.diagnostics.title|diagnosticsSessionSourceLabel' UI/Settings/SettingsView.swift; then
  pass "SettingsView shows diagnostics overview"
else
  fail "SettingsView must show diagnostics overview"
fi

if rg -q 'SettingsView\(appState:' App/MacPlayApp.swift UI/GameLibrary/GameLibraryView.swift; then
  pass "SettingsView receives AppState"
else
  fail "SettingsView must receive AppState"
fi

if rg -q 'showDiagnostics' UI/Settings/SettingsView.swift; then
  pass "settings navigates to diagnostics only"
else
  fail "settings must navigate to diagnostics only"
fi

for key in \
  settings.diagnostics.title \
  settings.diagnostics.staticDefault \
  settings.diagnostics.manualRealCheck \
  settings.diagnostics.currentSource; do
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
