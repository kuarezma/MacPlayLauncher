#!/usr/bin/env bash
# Fast Sprint 6 verification — static checks only, completes in seconds.
# Use --full to also run xcodebuild test (slow; not for agent loops).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

FAILURES=0
RUN_FULL=false

for arg in "$@"; do
  case "$arg" in
    --full) RUN_FULL=true ;;
    -h|--help)
      echo "Usage: $0 [--full]"
      echo "  Default: fast static checks (~5s)"
      echo "  --full:  also run xcodebuild test (minutes)"
      exit 0
      ;;
    *) echo "Unknown option: $arg" >&2; exit 2 ;;
  esac
done

section() { printf '\n== %s ==\n' "$1"; }
pass()    { printf 'PASS: %s\n' "$1"; }
fail()    { printf 'FAIL: %s\n' "$1"; FAILURES=$((FAILURES + 1)); }

rg_swift() {
  rg --glob '*.swift' --glob '!Tests/**' "$@" Core App UI 2>/dev/null || true
}

section "1. Sprint 6 models and services"
for file in \
  Core/Models/DiagnosticMode.swift \
  Core/Services/Diagnostics/SelectableDependencyDiagnosticService.swift \
  Core/Services/Diagnostics/RosettaDiagnosticProvider.swift \
  Core/Services/Diagnostics/WineDiagnosticProvider.swift \
  Core/Services/Diagnostics/RealDependencyDiagnosticService.swift; do
  if [[ -f "$file" ]]; then pass "$file exists"; else fail "missing $file"; fi
done

section "2. Sprint 6 test coverage"
for file in \
  Tests/MacPlayLauncherTests/DiagnosticModeTests.swift \
  Tests/MacPlayLauncherTests/SelectableDependencyDiagnosticServiceTests.swift \
  Tests/MacPlayLauncherTests/RealDependencyDiagnosticServiceTests.swift; do
  if [[ -f "$file" ]]; then pass "$file exists"; else fail "missing $file"; fi
done

section "3. Activation gate wiring"
if rg --glob 'AppEnvironment.swift' -q 'SelectableDependencyDiagnosticService' App/ 2>/dev/null; then
  pass "AppEnvironment uses SelectableDependencyDiagnosticService"
else
  fail "AppEnvironment must use SelectableDependencyDiagnosticService"
fi

if rg --glob 'AppEnvironment.swift' -q 'mode:[[:space:]]*\.staticOnly' App/ 2>/dev/null; then
  pass "AppEnvironment.live defaults to staticOnly mode"
else
  fail "AppEnvironment.live must default to staticOnly mode"
fi

if rg --glob 'AppEnvironment.swift' -q 'policy:[[:space:]]*\.production' App/ 2>/dev/null; then
  pass "AppEnvironment.live uses production activation policy"
else
  fail "AppEnvironment.live must use production activation policy"
fi

if rg --glob 'AppEnvironment.swift' -q 'dependencyDiagnosticService:[[:space:]]*RealDependencyDiagnosticService' App/ 2>/dev/null; then
  fail "RealDependencyDiagnosticService must not be production default in AppEnvironment.live"
else
  pass "RealDependencyDiagnosticService is not direct production default"
fi

section "4. Scope boundary"
FORBIDDEN=(
  'softwareupdate'
  'which wine'
  'which[[:space:]]'
  'sh -c'
  'install-rosetta'
)
for pattern in "${FORBIDDEN[@]}"; do
  hits="$(rg_swift -n "$pattern" || true)"
  if [[ -n "$hits" ]]; then
    fail "forbidden pattern '$pattern' in production Swift:"
    echo "$hits" | sed 's/^/    /'
  else
    pass "no '$pattern' in Core/App/UI Swift"
  fi
done

section "5. Process boundary"
process_files="$(rg --glob '*.swift' --glob '!Tests/**' -l 'Process\(\)' Core App UI 2>/dev/null || true)"
if [[ "$process_files" == "Core/Services/Commands/ProcessCommandRunner.swift" ]]; then
  pass "Process() only in ProcessCommandRunner.swift"
elif [[ -z "$process_files" ]]; then
  fail "Process() not found in ProcessCommandRunner.swift"
else
  fail "Process() found outside ProcessCommandRunner.swift:"
  echo "$process_files" | sed 's/^/    /'
fi

if rg --glob '*.swift' -l 'NSTask' . 2>/dev/null | grep -q .; then
  fail "NSTask found in codebase"
else
  pass "no NSTask usage"
fi

section "6. Production default and canLaunch policy"
if rg_swift -q 'canLaunch:[[:space:]]*false' Core/Services/DefaultRunReadinessEvaluator.swift; then
  pass "canLaunch remains false in DefaultRunReadinessEvaluator"
else
  fail "DefaultRunReadinessEvaluator must keep canLaunch false"
fi

if rg_swift -q 'allowsRealDiagnostics:[[:space:]]*false' Core/Models/DiagnosticMode.swift; then
  pass "production policy blocks real diagnostics by default"
else
  fail "DiagnosticActivationPolicy.production must set allowsRealDiagnostics false"
fi

section "7. Build hygiene (fast)"
tracked_before="$(git status --porcelain --untracked-files=no)"
if command -v xcodegen >/dev/null 2>&1; then
  xcodegen generate >/dev/null
  pass "xcodegen generate"
else
  fail "xcodegen not installed"
fi

tracked_after="$(git status --porcelain --untracked-files=no)"
if [[ "$tracked_before" == "$tracked_after" ]]; then
  pass "xcodegen did not modify tracked files"
else
  fail "xcodegen changed tracked files (compare git status before/after)"
  comm -13 <(printf '%s\n' "$tracked_before" | sort) <(printf '%s\n' "$tracked_after" | sort) | sed 's/^/    /'
fi

if [[ "$RUN_FULL" == true ]]; then
  section "8. Full build/test (optional)"
  if xcodebuild -scheme MacPlayLauncher -destination 'platform=macOS' test 2>&1 | tail -5 | grep -q 'TEST SUCCEEDED'; then
    pass "xcodebuild test"
  else
    fail "xcodebuild test — run manually in Xcode GUI: Product > Test"
  fi
else
  section "8. Full build/test"
  pass "skipped (use --full to run xcodebuild test; GUI test is preferred)"
fi

section "Summary"
if [[ "$FAILURES" -eq 0 ]]; then
  printf 'ALL CHECKS PASSED (%s)\n' "fast mode"
  exit 0
else
  printf '%d CHECK(S) FAILED\n' "$FAILURES"
  exit 1
fi
