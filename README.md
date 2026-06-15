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

- Sprint 2: Added localized Add Game profile creation flow with folder/executable selection, bookmarks, Cossacks 3 detection, containment validation, and focused tests.
- Sprint 1: Initial XcodeGen project skeleton, models, persistence, localized SwiftUI shell, tests, and documentation.
