#!/usr/bin/env bash
# Fast Sprint 5B verification — static checks only, completes in seconds.
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

section "1. Provider implementation"
for file in \
  Core/Services/Diagnostics/RosettaDiagnosticProvider.swift \
  Core/Services/Diagnostics/WineDiagnosticProvider.swift \
  Core/Services/Diagnostics/PassiveRuntimeDiagnosticProvider.swift \
  Core/Services/Diagnostics/RealDependencyDiagnosticService.swift \
  Core/Services/Diagnostics/RuntimeDiagnosticProviding.swift \
  Core/Services/Diagnostics/FileChecking.swift; do
  if [[ -f "$file" ]]; then pass "$file exists"; else fail "missing $file"; fi
done

section "2. Test coverage"
for file in \
  Tests/MacPlayLauncherTests/RosettaDiagnosticProviderTests.swift \
  Tests/MacPlayLauncherTests/WineDiagnosticProviderTests.swift \
  Tests/MacPlayLauncherTests/RealDependencyDiagnosticServiceTests.swift; do
  if [[ -f "$file" ]]; then pass "$file exists"; else fail "missing $file"; fi
done

section "3. Service wiring"
if rg --glob '*.swift' -q 'RealDependencyDiagnosticService' App/ 2>/dev/null; then
  fail "RealDependencyDiagnosticService referenced in App/ (production wiring)"
else
  pass "RealDependencyDiagnosticService not wired in App/"
fi

if rg_swift -q 'StaticDependencyDiagnosticService\(\)' App/AppEnvironment.swift; then
  pass "AppEnvironment.live uses StaticDependencyDiagnosticService"
elif rg --glob 'AppEnvironment.swift' -q 'SelectableDependencyDiagnosticService' App/ 2>/dev/null; then
  pass "AppEnvironment.live uses activation gate (SelectableDependencyDiagnosticService)"
else
  fail "AppEnvironment.live must use static diagnostics wiring"
fi

section "4. Scope boundary"
AUTHORIZED_SETUP_COMMAND_FILES='^(Core/Services/SetupInstallerService\.swift|Core/Services/CossacksSetupService\.swift|Core/Services/Commands/ProcessCommandRunner\.swift):'
FORBIDDEN=(
  'softwareupdate'
  'which wine'
  'which[[:space:]]'
  'sh -c'
  'install-rosetta'
)
for pattern in "${FORBIDDEN[@]}"; do
  hits="$(rg_swift -n "$pattern" | rg -v "$AUTHORIZED_SETUP_COMMAND_FILES" || true)"
  if [[ -n "$hits" ]]; then
    fail "unauthorized pattern '$pattern' in production Swift:"
    echo "$hits" | sed 's/^/    /'
  else
    pass "no unauthorized '$pattern' in Core/App/UI Swift"
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

section "6. Production default"
if rg --glob 'AppEnvironment.swift' -q 'mode:[[:space:]]*\.staticOnly' App/ 2>/dev/null; then
  pass "production diagnostics remain static-only via activation gate"
elif rg --glob 'AppEnvironment.swift' -q 'StaticDependencyDiagnosticService\(\)' App/ 2>/dev/null; then
  pass "production diagnostics remain static"
else
  fail "AppEnvironment must keep static diagnostics as production default"
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
    fail "xcodebuild test — run manually: xcodebuild -scheme MacPlayLauncher -destination 'platform=macOS' test"
  fi
else
  section "8. Full build/test"
  pass "skipped (use --full to run xcodebuild test)"
fi

section "Summary"
if [[ "$FAILURES" -eq 0 ]]; then
  printf 'ALL CHECKS PASSED (%s)\n' "fast mode"
  exit 0
else
  printf '%d CHECK(S) FAILED\n' "$FAILURES"
  exit 1
fi
