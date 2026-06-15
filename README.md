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

## Development

Generate the Xcode project:

```sh
xcodegen generate
```

Build:

```sh
xcodebuild -scheme MacPlayLauncher -destination 'platform=macOS' build
```

Test:

```sh
xcodebuild -scheme MacPlayLauncher -destination 'platform=macOS' test
```

Run SwiftLint if installed:

```sh
swiftlint
```

## Changelog

- Sprint 4: Added passive Run Readiness Gate with blocker explanations and Turkish diagnostics UI, without launch/runtime execution.
- Sprint 3: Added passive runtime diagnostics preparation with Turkish readiness UI, static dependency status service, setup guidance, and tests.
- Sprint 2: Added localized Add Game profile creation flow with folder/executable selection, bookmarks, Cossacks 3 detection, containment validation, and focused tests.
- Sprint 1: Initial XcodeGen project skeleton, models, persistence, localized SwiftUI shell, tests, and documentation.
