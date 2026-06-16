#!/usr/bin/env bash
# Fast Sprint 11 verification — library passive readiness strip.
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

if ./scripts/verify-sprint-10.sh; then
  pass "Sprint 10 base verification"
else
  fail "Sprint 10 base verification"
fi

section "12. Sprint 11 library readiness strip"
if rg -q 'libraryReadinessResult' App/AppState.swift; then
  pass "AppState exposes library readiness snapshot"
else
  fail "AppState must expose library readiness snapshot"
fi

if rg -q 'LibraryReadinessStripView|LibraryReadinessChecklistView' UI/GameLibrary/GameLibraryView.swift; then
  pass "GameLibraryView shows readiness guidance"
else
  fail "GameLibraryView must show readiness guidance"
fi

if rg -q 'showDiagnostics' UI/GameLibrary/GameLibraryView.swift; then
  pass "readiness strip navigates to diagnostics"
else
  fail "readiness strip must navigate to diagnostics only"
fi

if rg --glob '*.swift' -q 'canLaunch:[[:space:]]*true' UI/GameLibrary 2>/dev/null; then
  fail "library UI must not expose launch affordance"
else
  pass "no launch affordance in library UI"
fi

for key in library.readiness.title library.readiness.openDiagnostics; do
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
