# ADR-002: Prefix Strategy

## Status

Accepted for Sprint 13 planning. Implementation deferred to Sprint 14.

## Context

MacPlay Launcher stores per-game `GameProfile` values in JSON, including a relative `prefixPath` field such as `Prefixes/{profileID}`. Sprint 1–12 intentionally avoid creating Wine prefixes, running Wine setup commands, or writing runtime directories.

Before any prefix creation sprint, the project needs a single, reviewable decision for:

- where prefixes live on disk
- how they map to profiles and `WINEPREFIX`
- whether prefixes are shared or per-game
- how DXVK and MoltenVK paths relate to a prefix in later sprints

Cossacks 3 remains the first target game. The launcher is personal-use only and runs inside the macOS App Sandbox.

## Decision

### Location

Wine prefixes will live under Application Support:

`~/Library/Application Support/MacPlayLauncher/Prefixes/{profileID}/`

`GameProfile.prefixPath` remains a relative path rooted at the MacPlay Launcher app support directory:

- stored value: `Prefixes/{profileID}`
- resolved absolute path: `{appSupport}/Prefixes/{profileID}`

This matches the existing profile creation pattern in `AppState` and the bundled sample profile shape.

### Ownership model

- One Wine prefix per game profile.
- Prefixes are not shared across profiles.
- `profileID` is the stable directory name; display name changes do not rename prefix folders in Sprint 13.

### WINEPREFIX mapping

At launch time in a future sprint, the resolved absolute prefix directory becomes:

`WINEPREFIX={appSupport}/Prefixes/{profileID}`

Sprint 13 does not set `WINEPREFIX` at runtime. The mapping is documented only.

### Creation timing

Prefix directories are not created in Sprint 13.

Sprint 14 will introduce an explicit prefix creation boundary with these rules:

- creation is explicit and user-visible, not automatic on app launch
- creation happens only after prefix strategy ADR acceptance
- no game `.exe` execution during prefix creation
- no DXVK or MoltenVK install during prefix creation unless a later ADR says otherwise

Lazy creation on first launch is rejected for now. A dedicated creation step keeps failures visible and testable.

### DXVK and MoltenVK layout (plan only)

DXVK and MoltenVK remain passive in diagnostics until prefix and runtime strategy sprints land.

Planned layout for later sprints:

- prefix-local Windows state stays inside `Prefixes/{profileID}/`
- DXVK DLLs and MoltenVK ICD/config references are resolved relative to the chosen runtime supply chain, not mixed into game install folders
- real DXVK/MoltenVK diagnostics may later inspect prefix/runtime paths, but only after ADR-001 runtime acquisition and this prefix layout are implemented

Sprint 13 does not add DXVK or MoltenVK detection.

### Security and sandbox

- Prefixes are launcher-managed user data under Application Support.
- Game install folders remain separate from prefix folders.
- Security-scoped bookmark access for game files is a launch-sprint concern and stays out of Sprint 13.
- Prefix creation must not write outside `{appSupport}/Prefixes/`.

### Cossacks 3 reference

The bundled sample profile (`cossacks3`) and newly saved profiles use:

- `prefixPath: "Prefixes/{profileID}"`
- `wineArch: win64`
- `windowsVersion: win10`
- `runtime: wineDXVKMoltenVK`

Sprint 13 does not change these defaults.

## Consequences

- Sprint 13 is documentation-only; no filesystem writes or Wine commands are introduced.
- Sprint 14 can implement `PrefixManaging` or equivalent behind a narrow boundary using the resolved path rules above.
- Runtime acquisition remains governed separately by ADR-001.
- `canLaunch` stays false until a future launch sprint explicitly changes launch policy.
- Diagnostics can continue to treat DXVK and MoltenVK as passive until prefix/runtime implementation exists.

## Out of Scope for Sprint 13

- `wineprefixcreate` or any Wine prefix bootstrap command
- creating `Prefixes/` on disk
- runtime download or install
- game launch
- bookmark resolve/access lifecycle for launch
- changing `canLaunch`
- real DXVK or MoltenVK detection
