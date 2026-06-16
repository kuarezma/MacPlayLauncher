#!/usr/bin/env bash
# Fast Sprint 15 verification — runtime strategy planning gates.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

FAILURES=0

section() { printf '\n== %s ==\n' "$1"; }
pass()    { printf 'PASS: %s\n' "$1"; }
fail()    { printf 'FAIL: %s\n' "$1"; FAILURES=$((FAILURES + 1)); }

if ./scripts/verify-sprint-14.sh; then
  pass "Sprint 14 base verification"
else
  fail "Sprint 14 base verification"
fi

section "16. Sprint 15 runtime strategy planning"
if [[ -f Docs/ADR/ADR-001-Runtime-Acquisition.md ]]; then
  pass "ADR-001 runtime acquisition document exists"
else
  fail "Docs/ADR/ADR-001-Runtime-Acquisition.md must exist"
fi

if rg -q 'Accepted for Sprint 15' Docs/ADR/ADR-001-Runtime-Acquisition.md; then
  pass "ADR-001 marked accepted for Sprint 15"
else
  fail "ADR-001 must be accepted for Sprint 15 planning"
fi

if rg -q 'Sprint 15' ARCHITECTURE.md README.md; then
  pass "Sprint 15 documented in ARCHITECTURE and README"
else
  fail "Sprint 15 must be documented in ARCHITECTURE and README"
fi

if rg --glob '*.swift' --glob '!Tests/**' -q 'RuntimeDownloading|RuntimeInstaller|downloadRuntime|installRuntime|brew install' Core App UI 2>/dev/null; then
  fail "runtime download or install must not be introduced in Sprint 15"
else
  pass "no runtime download or install services in production code"
fi

if rg -q 'PassiveRuntimeDiagnosticProvider' Core/Services/Diagnostics/RealDependencyDiagnosticService.swift; then
  pass "DXVK and MoltenVK remain passive in real diagnostics"
else
  fail "Real diagnostics must keep DXVK/MoltenVK passive"
fi

if rg --glob '*.swift' --glob '!Tests/**' -q 'wineprefixcreate|WINEPREFIX' Core App UI 2>/dev/null; then
  fail "Wine prefix bootstrap runtime wiring must not be introduced in Sprint 15"
else
  pass "no wineprefixcreate or WINEPREFIX runtime wiring in production code"
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
