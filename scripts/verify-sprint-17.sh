#!/usr/bin/env bash
# Fast Sprint 17 verification — minimal launch prototype gates.
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

section "15. Sprint 14 prefix creation boundary"
if rg -q 'protocol PrefixManaging' Core/Services/PrefixManager.swift; then
  pass "PrefixManaging boundary exists"
else
  fail "PrefixManaging must exist"
fi

section "16. Sprint 15 runtime strategy planning"
if [[ -f Docs/ADR/ADR-001-Runtime-Acquisition.md ]]; then
  pass "ADR-001 runtime acquisition document exists"
else
  fail "Docs/ADR/ADR-001-Runtime-Acquisition.md must exist"
fi

section "17. Sprint 16 launch plan planning (docs)"
if [[ -f Docs/ADR/ADR-003-Launch-Plan.md ]]; then
  pass "ADR-003 launch plan document exists"
else
  fail "Docs/ADR/ADR-003-Launch-Plan.md must exist"
fi

if rg -q 'Sprint 16' ARCHITECTURE.md README.md; then
  pass "Sprint 16 documented in ARCHITECTURE and README"
else
  fail "Sprint 16 must be documented in ARCHITECTURE and README"
fi

section "18. Sprint 17 minimal launch prototype"
if rg -q 'protocol GameLaunching' Core/Services/GameLauncher.swift; then
  pass "GameLaunching boundary exists"
else
  fail "GameLaunching must exist"
fi

if rg -q 'SecurityScopedAccessManaging' Core/Services/SecurityScopedAccessManager.swift; then
  pass "security-scoped access manager exists"
else
  fail "SecurityScopedAccessManager must exist"
fi

if rg -q 'ExperimentalRunReadinessEvaluator' Core/Services/ExperimentalRunReadinessEvaluator.swift; then
  pass "experimental readiness evaluator exists"
else
  fail "ExperimentalRunReadinessEvaluator must exist"
fi

if rg -q 'experimentalLaunchSection|launchExperimentalGame|evaluateExperimentalRunReadiness' UI/Diagnostics/DiagnosticsView.swift App/AppState.swift; then
  pass "experimental launch UI and app state wiring exist"
else
  fail "Diagnostics must expose experimental launch flow"
fi

if rg -q 'WINEPREFIX' Core/Services/GameLaunchPlanner.swift; then
  pass "launch planner sets WINEPREFIX"
else
  fail "GameLaunchPlanner must set WINEPREFIX for launch"
fi

if rg --glob '*.swift' --glob '!Tests/**' -q 'wineprefixcreate' Core App UI 2>/dev/null; then
  fail "wineprefixcreate must not be introduced in Sprint 17"
else
  pass "no wineprefixcreate in production code"
fi

if rg -q 'canLaunch:[[:space:]]*false' Core/Services/DefaultRunReadinessEvaluator.swift; then
  pass "default readiness evaluator keeps canLaunch false"
else
  fail "DefaultRunReadinessEvaluator must keep canLaunch false"
fi

if rg -q 'canLaunch:[[:space:]]*true' Core/Services/ExperimentalRunReadinessEvaluator.swift; then
  pass "experimental readiness evaluator can enable canLaunch"
else
  fail "ExperimentalRunReadinessEvaluator must support experimental canLaunch true"
fi

PROCESS_HITS="$(rg -l 'Process\(\)' Core App UI --glob '*.swift' --glob '!Tests/**' 2>/dev/null || true)"
if [[ "$(printf '%s\n' "$PROCESS_HITS" | sed '/^$/d' | wc -l | tr -d ' ')" -eq 1 ]] && [[ "$PROCESS_HITS" == *ProcessCommandRunner.swift* ]]; then
  pass "Process() remains centralized in ProcessCommandRunner.swift"
else
  fail "Process() must remain only in ProcessCommandRunner.swift"
  printf 'Found in: %s\n' "$PROCESS_HITS"
fi

if rg -q 'Sprint 17' ARCHITECTURE.md README.md; then
  pass "Sprint 17 documented in ARCHITECTURE and README"
else
  fail "Sprint 17 must be documented in ARCHITECTURE and README"
fi

section "Summary"
if [[ "$FAILURES" -eq 0 ]]; then
  printf 'ALL CHECKS PASSED (%s)\n' "fast mode"
  exit 0
else
  printf '%d CHECK(S) FAILED\n' "$FAILURES"
  exit 1
fi
