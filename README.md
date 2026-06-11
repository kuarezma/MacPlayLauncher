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

- Sprint 1: Initial XcodeGen project skeleton, models, persistence, localized SwiftUI shell, tests, and documentation.

