# MacPlay Launcher

MacPlay Launcher is a macOS launcher project for running selected Windows games on Apple Silicon Macs in future runtime phases. The first target game is Cossacks 3.

## What It Is Not

- It is not a Windows VM.
- It is not Parallels Desktop.
- It does not install or automate the Steam client/login flow in V1.
- It is not planned for Mac App Store distribution.
- It does not claim universal Windows game compatibility.

## Requirements

- macOS 14.0 or newer.
- Apple Silicon Mac.
- Rosetta 2 will be required in future runtime phases, but Sprint 1 does not implement Rosetta checks.

## Sprint 1 Features

- XcodeGen macOS SwiftUI project skeleton.
- SwiftUI `NavigationSplitView` shell.
- Observation framework with `@Observable`.
- JSON profile persistence.
- Sample Cossacks 3 profile.
- English base localization with Turkish placeholder localization.
- Keyboard shortcuts for Add Game, Settings, and Diagnostics.
- XCTest unit tests for models and persistence.

## Sprint 2 Features

- Turkish Add Game form for selecting a local game folder and `.exe` file.
- `NSOpenPanel` based folder and executable selection behind a testable file selection service.
- Security-scoped bookmark creation and stale bookmark resolution handling.
- Cossacks 3 executable detection inside the selected game folder.
- Manual profile creation using existing profile persistence.
- Safe path containment validation so executables outside the selected folder are rejected.

## Sprint 3 Features

- Turkish runtime readiness diagnostics screen.
- Passive dependency models for Rosetta, Wine, DXVK, MoltenVK, and game profile readiness.
- Static diagnostic service that does not run system commands or inspect real runtime installs.
- Game profile readiness based on minimum user-configured profile data, without file access or launch checks.
- Manual setup guide text explaining that installation and launch are handled in later sprints.
- Unit tests for diagnostic aggregation, static diagnostic output, and view model mapping.

## Sprint 4 Features

- Run Readiness Gate domain model for explaining whether a future launch would be allowed.
- Pure readiness evaluator based only on `GameProfile` and `RuntimeDiagnosticSummary`.
- Turkish Diagnostics UI section that lists readiness blockers and passive suggested actions.
- No launch button, launch affordance, process execution, shell script, runtime download/install, prefix creation, or real file/bookmark access.
- `ready` status is only a domain result for future launch gating; the app still does not run games and `canLaunch` remains false in Sprint 4.
- Unit tests for readiness status priority, blocker order, configured profile requirements, and UI mapping.

## Sprint 5A Features

- Diagnostic command boundary for future real runtime checks.
- `CommandRunning` abstraction with request/result/error models.
- `ProcessCommandRunner` keeps process execution behind a whitelist, timeout, and output limit.
- Shell execution, `sh -c`, game launch, runtime install/download, and prefix creation remain out of scope.
- `FakeCommandRunner` supports deterministic command tests without depending on the local system.
- Production diagnostics remain static/passive; real Rosetta and Wine detection are deferred to a later sprint.

## Sprint 5B Features

- Read-only Rosetta and Wine diagnostic providers for future production diagnostics.
- Rosetta detection uses the existing command boundary and does not install Rosetta or request admin privileges.
- Wine detection checks only explicit allowed paths and runs only `wine --version`; it does not use `PATH` lookup or `which wine`.
- DXVK and MoltenVK remain passive because prefix/runtime strategy is not implemented yet.
- `RealDependencyDiagnosticService` is implemented for tests and future wiring, but production still uses static diagnostics through the activation gate.
- UI, game launch, prefix creation, runtime download/install, shell execution, and user `.exe` execution remain out of scope.

## Sprint 6 Features

- Real diagnostics activation gate with `DiagnosticMode`, `DiagnosticActivationPolicy`, and `DiagnosticsSource`.
- `SelectableDependencyDiagnosticService` routes between static preparation and read-only real diagnostics.
- Production default remains `staticOnly` with `DiagnosticActivationPolicy.production`; real diagnostics require explicit internal activation.
- Diagnostics UI shows a passive source label (`Hazırlık rehberi` / `Gerçek sistem kontrolü`) without a manual real-check button.
- `canLaunch` remains false for all readiness results.
- Fast agent verification via `./scripts/verify-sprint-6.sh`; GUI build/test remains the primary human verification channel.

## Sprint 7 Features

- Diagnostics source info card with title, badge, subtitle, policy notes, and shared footnotes.
- Clear Turkish messaging that the screen shows passive preparation guidance, not automatic real system checks.
- Real source mapping remains testable for future use; production still uses `staticOnly`.
- No manual real-check button, no real diagnostics execution, and no production policy change.

## Sprint 8 Features

- Manual `Gerçek sistemi kontrol et` button on the Diagnostics screen for read-only Rosetta/Wine checks.
- Loading state and `Hazırlık rehberine dön` action after a real result.
- Per-request diagnostic mode routing through `SelectableDependencyDiagnosticService`; initial load remains static preparation.
- Production policy allows real diagnostics only with explicit user action; `canLaunch` remains false.

## Sprint 9 Features

- Real-check result details on the Diagnostics screen: last check timestamp plus dependency version and install path when available.
- Detail lines appear only after a manual real check; static preparation UI stays unchanged.
- No persistence, policy change, or launch affordance.

## Sprint 10 Features

- In-memory diagnostics session state preserves manual real-check results while navigating within the app.
- Returning to Diagnostics restores the cached real-check summary until the user resets to preparation or saves a new profile.
- No disk persistence, automatic real-check, or launch affordance.

## Sprint 11 Features

- Passive readiness strip on the Game Library screen with status badge and short explanation.
- Uses cached real-check readiness when available; otherwise falls back to static preparation evaluation.
- `Tanılamayı aç` navigates to Diagnostics only; no launch affordance.

## Sprint 12 Features

- Settings screen diagnostics section with policy notes and current in-memory session source label.
- Reuses existing navigation to Diagnostics; no policy toggles or automatic real checks.

## Sprint 13 Features

- ADR-002 documents the Wine prefix strategy: per-game prefixes under Application Support, `WINEPREFIX` mapping, and deferred creation in Sprint 14.
- No prefix directories are created and no Wine prefix bootstrap commands run in Sprint 13.

## Sprint 14 Features

- `PrefixManager` creates per-game prefix directories under Application Support on explicit user action from Diagnostics.
- Path validation keeps writes inside `Prefixes/`; no Wine bootstrap, `WINEPREFIX`, or launch behavior is added.

## Sprint 15 Features

- ADR-001 finalizes V1 runtime strategy: user-managed Homebrew Wine via allowlist discovery; no launcher runtime download or install.
- DXVK and MoltenVK remain passive; supply-chain notes are documented for later launch work.

## Sprint 16 Features

- ADR-003 documents the launch plan: Wine command shape, env mapping, bookmark access lifecycle, and experimental gating for Sprint 17.
- No launch button, launch services, or bookmark access runtime calls are added in Sprint 16.

## Sprint 17 Features

- Experimental launch flow wires ADR-003: Wine command start, `WINEPREFIX`/`WINEARCH`, bookmark access lifecycle, and bounded failure messaging.
- Production readiness still reports `canLaunch: false`; experimental launch requires real diagnostics, prefix folder, and explicit user action.

## Sprint 18 Features

- Game Library now shows an actionable `Eksikleri gider` panel with ordered setup steps for game folder, real system check, Wine, prefix, and experimental launch readiness.
- Game cards use Turkish user-facing runtime, performance, Windows version, and profile type labels instead of raw enum values.
- Diagnostics starts with a `Sıradaki adım` card that routes real check, prefix creation, and experimental launch actions from one place.
- Settings shows diagnostics source, experimental launch status, and the application data folder.
- Production launch remains disabled; only the controlled experimental flow can become available after real diagnostics, Wine, and prefix requirements pass.

## Development

Generate the Xcode project:

```sh
xcodegen generate
```

Build:

```sh
xcodebuild -scheme MacPlayLauncher -destination 'platform=macOS' build
```

Build, test, and launch:

```sh
./script/build_and_run.sh
```

Test:

```sh
xcodebuild -scheme MacPlayLauncher -destination 'platform=macOS' test
```

Run SwiftLint if installed:

```sh
swiftlint lint
```

Continuous integration runs XcodeGen, SwiftLint, sprint verification, and XCTest on every push and pull request to `main`.

Regenerate app icons:

```sh
./scripts/generate-app-icons.py
```

## Changelog

- Sprint 18: Added actionable readiness guidance across Library, Diagnostics, and Settings while keeping production launch disabled; stabilized Xcode 26 local build/test settings.
- Chore: Added generated MacPlay Launcher app icons and reusable launcher symbol assets.
- Chore: Added a project-local build/run script and Codex Run action.
- Chore: Added GitHub Actions CI for XcodeGen, SwiftLint, sprint verification, and XCTest.
- Fix: Restored Swift 6/Xcode test compatibility for environment wiring and launch planner tests.
- Sprint 17: Added experimental minimal launch prototype with bookmark access and experimental readiness gating.
- Sprint 16: Added ADR-003 launch plan; no launch implementation or bookmark access runtime.
- Sprint 15: Finalized ADR-001 runtime acquisition strategy; no runtime download, install, or launch behavior.
- Sprint 14: Added explicit prefix directory creation boundary with Diagnostics UI; no Wine bootstrap or launch.
- Sprint 13: Added ADR-002 prefix strategy planning; no prefix creation or launch behavior.
- Sprint 12: Added Settings diagnostics overview with policy notes and current session source label.
- Sprint 11: Added passive readiness strip to the Game Library with navigation to Diagnostics.
- Sprint 10: Added in-memory diagnostics session state so manual real-check results survive navigation within the app session.
- Sprint 9: Added real-check result details for timestamp, version, and install path on the Diagnostics screen.
- Sprint 8: Added manual real diagnostics check button with per-request mode routing; static preparation remains the default load.
- Sprint 7: Added diagnostics source info card and clearer passive preparation messaging; no real-check button.
- Sprint 6: Added real diagnostics activation gate, selectable diagnostic service, and passive source labeling; production remains static-only.
- Sprint 5B: Added read-only Rosetta/Wine diagnostic providers and a non-default real diagnostics service; production diagnostics remain static.
- Sprint 5A: Added a safe diagnostic command boundary with fake runner tests; production diagnostics remain static.
- Sprint 4: Added passive Run Readiness Gate with blocker explanations and Turkish diagnostics UI, without launch/runtime execution.
- Sprint 3: Added passive runtime diagnostics preparation with Turkish readiness UI, static dependency status service, setup guidance, and tests.
- Sprint 2: Added localized Add Game profile creation flow with folder/executable selection, bookmarks, Cossacks 3 detection, containment validation, and focused tests.
- Sprint 1: Initial XcodeGen project skeleton, models, persistence, localized SwiftUI shell, tests, and documentation.
