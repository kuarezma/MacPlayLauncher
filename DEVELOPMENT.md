# Development

## Tooling

- Xcode 26.5 or compatible.
- XcodeGen 2.45+.
- SwiftLint is optional locally for Sprint 1. If available, run `swiftlint`.

## Commands

Generate the project:

```sh
xcodegen generate
```

Build the app:

```sh
xcodebuild -scheme MacPlayLauncher -destination 'platform=macOS' build
```

Run tests:

```sh
xcodebuild -scheme MacPlayLauncher -destination 'platform=macOS' test
```

## Conventions

- Commit `project.yml`, not the generated `.xcodeproj`.
- Use SwiftUI and Observation.
- Use `@Observable`, not `ObservableObject`.
- Keep visible UI strings behind `String(localized:)`.
- Keep runtime, process execution, shell scripts, and game launching out of Sprint 1.

## Localization

English is the base language. Turkish placeholder localization lives in `Resources/Localization/Localizable.xcstrings`.

