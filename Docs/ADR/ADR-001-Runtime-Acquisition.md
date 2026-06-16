# ADR-001: Runtime Acquisition

## Status

Accepted for Sprint 15 planning. Runtime download, install, and launch wiring remain deferred to later sprints.

## Context

MacPlay Launcher is a personal-use macOS launcher for Cossacks 3 on Apple Silicon. Sprint 1–14 intentionally avoid choosing or implementing a Wine runtime supply chain, runtime download flows, or DXVK/MoltenVK installation.

The project already has:

- read-only Wine discovery in `WineDiagnosticProvider` against a fixed Homebrew allowlist
- passive DXVK and MoltenVK diagnostics via `PassiveRuntimeDiagnosticProvider`
- per-game prefix directories under Application Support (ADR-002, Sprint 14)
- `GameProfile.runtime` values such as `wineDXVKMoltenVK` that describe intent, not installed files

Before launch planning, the project needs a single, reviewable decision for:

- how Wine is supplied in V1
- whether the launcher may ever download or install runtimes
- how DXVK and MoltenVK relate to Wine and prefixes in later work
- how future launch resolves Wine without trusting `PATH`

Cossacks 3 remains the first target game. The app runs inside the macOS App Sandbox and does not automate Homebrew or Steam installs.

## Decision

### V1 Wine supply model

V1 uses **user-managed system Wine**, not launcher-managed acquisition.

- The user installs Wine outside the launcher, typically via Homebrew on Apple Silicon.
- The launcher discovers Wine only through the existing read-only allowlist used by `WineDiagnosticProvider`:
  - `/opt/homebrew/bin/wine`
  - `/usr/local/bin/wine`
- `PATH`, `which wine`, shell wrappers, and user-selected Wine binaries are rejected.
- The launcher does not download, extract, install, update, or bundle Wine in V1.

This aligns with Sprint 5B diagnostics and keeps runtime responsibility visible to the user.

### Rejected for V1

- Bundled Wine runtime inside the app package
- Launcher-driven runtime download or install
- Self-built and self-hosted Wine distribution from the launcher
- Automatic Homebrew invocation (`brew install wine`)
- Trusting `PATH` or arbitrary filesystem locations for launch

These remain future options only if a separate sprint amends this ADR.

### Future bundled runtime option (plan only)

If a bundled runtime is added later, it must:

- live under launcher-managed Application Support, separate from game installs and prefixes
- require explicit user action before download or install
- verify checksums before extraction or use
- remain behind a narrow service boundary with tests and verification gates

Sprint 15 does not implement this path.

### Launch-time Wine resolution (documented only)

A future launch sprint will reuse the same allowlisted Wine discovery rules as diagnostics. Planned mapping:

- Wine executable: first usable allowlisted `wine` binary
- `WINEPREFIX`: resolved absolute prefix path from `PrefixManager` / ADR-002
- `WINEARCH`: from `GameProfile.wineArch` / `GameProfile.environment`
- working directory and executable: from resolved security-scoped bookmarks in a later bookmark-access sprint

Sprint 15 does not set these environment variables at runtime.

### DXVK strategy (plan only)

DXVK remains passive in diagnostics until prefix bootstrap and launch planning land.

Planned V1 assumptions:

- DXVK is user-managed alongside the chosen Homebrew Wine install
- Windows DLL state and DXVK overrides stay inside the per-game prefix from ADR-002
- DXVK files are not copied into game install folders by the launcher
- real DXVK detection may later inspect prefix-local or Wine-adjacent paths, but only after this ADR and the launch plan ADR are implemented

Sprint 15 does not add real DXVK detection or installation.

### MoltenVK strategy (plan only)

MoltenVK follows the same boundary as DXVK:

- user-managed install outside the launcher
- passive diagnostics remain the default until launch prerequisites exist
- ICD and layer configuration are resolved relative to the chosen graphics stack, not mixed into game folders
- no launcher download or install in Sprint 15

### `GameProfile.runtime` meaning

`RuntimeKind` continues to describe launch intent for Cossacks 3 (`wineDXVKMoltenVK` for the sample profile). It does not imply that DXVK or MoltenVK are installed, detected, or managed by the launcher in Sprint 15.

### Security and sandbox

- Runtime discovery stays read-only and allowlist-based.
- Any future runtime write operation must stay under Application Support and pass checksum validation first.
- The launcher must not execute game `.exe` files during runtime planning or acquisition work.
- Shell execution, `softwareupdate`, and package-manager automation remain out of scope.

### Cossacks 3 reference

The bundled sample profile keeps:

- `runtime: wineDXVKMoltenVK`
- `wineArch: win64`
- `environment` entries such as `WINEARCH` and `DXVK_STATE_CACHE`

Sprint 15 does not change profile defaults or diagnostics behavior.

## Consequences

- Sprint 15 is documentation-only for runtime acquisition; no runtime directories, downloads, or install flows are introduced.
- `WineDiagnosticProvider` remains the authoritative V1 discovery rule set; launch work must not widen discovery silently.
- DXVK and MoltenVK stay passive in diagnostics until a later implementation sprint.
- Prefix bootstrap (`wineprefixcreate` or equivalent) remains a separate sprint after launch planning.
- `canLaunch` stays false until a future launch sprint explicitly changes launch policy.
- A future bundled-runtime sprint requires a new ADR amendment or ADR addendum with checksum and storage rules.

## Out of Scope for Sprint 15

- runtime download, install, or update UI
- bundled Wine binaries in the app
- real DXVK or MoltenVK detection
- `wineprefixcreate` or Wine prefix bootstrap commands
- `WINEPREFIX` / launch env wiring
- game launch
- changing `canLaunch`
- Homebrew automation or install prompts
