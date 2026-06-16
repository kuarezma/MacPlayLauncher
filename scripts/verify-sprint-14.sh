#!/usr/bin/env bash
# Fast Sprint 14 verification — prefix creation boundary gates.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

FAILURES=0

section() { printf '\n== %s ==\n' "$1"; }
pass()    { printf 'PASS: %s\n' "$1"; }
fail()    { printf 'FAIL: %s\n' "$1"; FAILURES=$((FAILURES + 1)); }

if ./scripts/verify-sprint-12.sh; then
  pass "Sprint 12 base verification"
else
  fail "Sprint 12 base verification"
fi

section "14. Sprint 13 prefix strategy planning (docs)"
if [[ -f Docs/ADR/ADR-002-Prefix-Strategy.md ]]; then
  pass "ADR-002 prefix strategy document exists"
else
  fail "Docs/ADR/ADR-002-Prefix-Strategy.md must exist"
fi

if rg -q 'Sprint 13' ARCHITECTURE.md README.md; then
  pass "Sprint 13 documented in ARCHITECTURE and README"
else
  fail "Sprint 13 must be documented in ARCHITECTURE and README"
fi

section "15. Sprint 14 prefix creation boundary"
if rg -q 'protocol PrefixManaging' Core/Services/PrefixManager.swift; then
  pass "PrefixManaging boundary exists"
else
  fail "PrefixManaging must exist in Core/Services/PrefixManager.swift"
fi

if rg -q 'prefixManager' App/AppEnvironment.swift App/AppState.swift; then
  pass "prefix manager wired in app environment"
else
  fail "AppEnvironment and AppState must wire prefix manager"
fi

if rg -q 'diagnostics.prefix.createButton|createPrefixDirectory' UI/Diagnostics/DiagnosticsView.swift App/AppState.swift; then
  pass "explicit prefix creation UI and action exist"
else
  fail "Diagnostics must expose explicit prefix creation"
fi

if rg 'func loadInitialProfiles' -A 25 App/AppState.swift | rg -q 'createPrefixDirectory'; then
  fail "prefix creation must not run during initial profile load"
else
  pass "no automatic prefix creation on initial profile load"
fi

if rg -q 'canLaunch:[[:space:]]*false' Core/Services/DefaultRunReadinessEvaluator.swift; then
  pass "canLaunch remains false"
else
  fail "DefaultRunReadinessEvaluator must keep canLaunch false"
fi

if rg -q 'Sprint 14' ARCHITECTURE.md README.md; then
  pass "Sprint 14 documented in ARCHITECTURE and README"
else
  fail "Sprint 14 must be documented in ARCHITECTURE and README"
fi

section "Summary"
if [[ "$FAILURES" -eq 0 ]]; then
  printf 'ALL CHECKS PASSED (%s)\n' "fast mode"
  exit 0
else
  printf '%d CHECK(S) FAILED\n' "$FAILURES"
  exit 1
fi
