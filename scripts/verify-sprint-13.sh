#!/usr/bin/env bash
# Fast Sprint 13 verification — prefix strategy planning gates.
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

section "14. Sprint 13 prefix strategy planning"
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

if rg --glob '*.swift' --glob '!Tests/**' -q 'wineprefixcreate|WINEPREFIX' Core App UI 2>/dev/null; then
  fail "prefix runtime wiring must not be introduced in Sprint 13"
else
  pass "no wineprefixcreate or WINEPREFIX runtime wiring in production code"
fi

if rg --glob '*.swift' --glob '!Tests/**' -q 'createPrefix|PrefixCreation|PrefixManaging' Core App UI 2>/dev/null; then
  fail "prefix creation services must not be introduced in Sprint 13"
else
  pass "no prefix creation service in production code"
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
