#!/usr/bin/env bash
# Fast Sprint 16 verification — launch plan planning gates.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

FAILURES=0

section() { printf '\n== %s ==\n' "$1"; }
pass()    { printf 'PASS: %s\n' "$1"; }
fail()    { printf 'FAIL: %s\n' "$1"; FAILURES=$((FAILURES + 1)); }

if ./scripts/verify-sprint-15.sh; then
  pass "Sprint 15 base verification"
else
  fail "Sprint 15 base verification"
fi

section "17. Sprint 16 launch plan planning"
if [[ -f Docs/ADR/ADR-003-Launch-Plan.md ]]; then
  pass "ADR-003 launch plan document exists"
else
  fail "Docs/ADR/ADR-003-Launch-Plan.md must exist"
fi

if rg -q 'Accepted for Sprint 16' Docs/ADR/ADR-003-Launch-Plan.md; then
  pass "ADR-003 marked accepted for Sprint 16"
else
  fail "ADR-003 must be accepted for Sprint 16 planning"
fi

if rg -q 'Sprint 16' ARCHITECTURE.md README.md; then
  pass "Sprint 16 documented in ARCHITECTURE and README"
else
  fail "Sprint 16 must be documented in ARCHITECTURE and README"
fi

if rg --glob '*.swift' --glob '!Tests/**' -q 'GameLaunch|LaunchService|launchGame|startAccessingSecurityScopedResource' Core App UI 2>/dev/null; then
  fail "launch services or bookmark access must not be introduced in Sprint 16"
else
  pass "no launch services or bookmark access runtime in production code"
fi

if rg --glob '*.swift' --glob '!Tests/**' -q 'wineprefixcreate|WINEPREFIX' Core App UI 2>/dev/null; then
  fail "Wine prefix bootstrap runtime wiring must not be introduced in Sprint 16"
else
  pass "no wineprefixcreate or WINEPREFIX runtime wiring in production code"
fi

if rg -q 'launchGame|Launch Game|Oyunu başlat|Oyunu Baslat' UI App 2>/dev/null; then
  fail "launch affordance must not be introduced in Sprint 16"
else
  pass "no launch affordance in UI"
fi

if rg -q 'canLaunch:[[:space:]]*false' Core/Services/DefaultRunReadinessEvaluator.swift; then
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
