# Development

## Tooling

- Xcode 26.5 or compatible.
- XcodeGen 2.45+.
- SwiftLint is optional locally but required in CI. If available, run `swiftlint lint`.

## Continuous integration

GitHub Actions runs on every push and pull request to `main`.

CI steps:

```sh
xcodegen generate
swiftlint lint
./scripts/verify-sprint-17.sh
xcodebuild -scheme MacPlayLauncher -destination 'platform=macOS' test
```

## Sprint verification

Fast Sprint 17 checks (seconds, safe for agent loops):

```sh
./scripts/verify-sprint-17.sh
```

Sprint 6 regression checks:

```sh
./scripts/verify-sprint-6.sh
```

Optional full test run (minutes; terminal `xcodebuild` may hang locally):

```sh
./scripts/verify-sprint-6.sh --full
```

Primary human verification: Xcode GUI → Product > Clean Build Folder, Command+B, Command+U.

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

Build, test, and launch from the project-local run entrypoint:

```sh
./script/build_and_run.sh
```

Verify the app starts:

```sh
./script/build_and_run.sh --verify
```

## Conventions

- Commit `project.yml`, not the generated `.xcodeproj`.
- Use SwiftUI and Observation.
- Use `@Observable`, not `ObservableObject`.
- Keep visible UI strings behind `String(localized:)`.
- Keep runtime, process execution, shell scripts, and game launching out of Sprint 1.

## Localization

English is the base language. Turkish placeholder localization lives in `Resources/Localization/Localizable.xcstrings`.
