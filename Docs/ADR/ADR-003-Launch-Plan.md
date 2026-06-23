# ADR-003: Launch Plan

## Status

Accepted for Sprint 16 planning. Launch implementation remains deferred to Sprint 17.

## Context

MacPlay Launcher has completed:

- game profile creation with security-scoped bookmarks (Sprint 2)
- read-only diagnostics and run readiness evaluation with `canLaunch: false` (Sprint 4–12)
- a safe diagnostic command boundary via `CommandRunning` / `ProcessCommandRunner` (Sprint 5A)
- allowlisted Homebrew Wine discovery (Sprint 5B, ADR-001)
- per-game prefix directory creation under Application Support (Sprint 14, ADR-002)

Before any experimental game launch, the project needs a single, reviewable plan for:

- how Wine is invoked for a configured profile
- which environment variables are set and in what precedence order
- how security-scoped bookmark access is acquired and released
- what working directory and executable path resolution rules apply
- how process output and failures are handled
- when `canLaunch` may become true in a later sprint

Cossacks 3 remains the first target game. The launcher is personal-use only, sandboxed, and does not automate Steam login, Steam Guard/2FA, purchases, or license bypass. Runtime setup automation is governed by ADR-001.

## Decision

### Launch service boundary

Sprint 17 will introduce a narrow launch boundary, separate from diagnostics:

- `GameLaunchPlanning` or equivalent builds a launch plan value from `GameProfile`, resolved bookmarks, prefix state, and allowlisted Wine discovery.
- `GameLaunchExecuting` or equivalent performs the actual `Process` launch behind the existing command boundary pattern.
- `Process()` for game launch must remain centralized; diagnostics and launch may share `ProcessCommandRunner` only if purpose-specific validation and allowlists are extended deliberately in Sprint 17.

Sprint 16 does not add these types or wire them into the app.

### Wine executable resolution

Launch reuses ADR-001 discovery rules:

- executable: first usable allowlisted `wine` binary
  - `/opt/homebrew/bin/wine`
  - `/usr/local/bin/wine`
- no `PATH` lookup
- no shell invocation
- no user-selected Wine binary outside the allowlist

### Command composition

Planned V1 launch command shape:

```text
{wine} {profile.launchArguments...} {resolvedExecutablePath}
```

Rules:

- `resolvedExecutablePath` comes from the resolved executable bookmark, not the stored string path alone.
- `launchArguments` remain profile-owned and pass through unchanged after validation.
- arguments must not include `-c` or shell metacharacters; reuse `ProcessCommandRunner` rejection rules.
- the game `.exe` is passed as a Wine argument, not as the process `executableURL`.
- Sprint 17 may add a dedicated `CommandPurpose.gameLaunch` with stricter validation and a longer timeout than diagnostics.

### Environment variable mapping

Launch environment is assembled in this precedence order (later wins):

1. minimal process baseline required for Wine launch
2. `GameProfile.environment`
3. launcher-injected required values

Launcher-injected required values:

| Variable | Source |
|---|---|
| `WINEPREFIX` | absolute prefix path from `PrefixManager` / ADR-002 |
| `WINEARCH` | `GameProfile.wineArch` (`win64` / `win32`) |

Rules:

- if `GameProfile.environment` also defines `WINEPREFIX` or `WINEARCH`, launcher values override profile values for safety.
- other profile entries such as `DXVK_STATE_CACHE` pass through unchanged.
- no secrets, tokens, or Steam credentials are injected by the launcher in V1.

Sprint 16 does not set these variables at runtime.

### Working directory

- `cwd` for the Wine process is the resolved working-directory bookmark URL.
- stored `workingDirectory` string paths are informational only; launch must not trust them without bookmark resolution.
- if working-directory access cannot be started, launch aborts before Wine starts.

### Security-scoped bookmark access lifecycle

Sprint 2 creates bookmarks with `.withSecurityScope`. Launch requires an explicit access lifecycle:

1. resolve executable and working-directory bookmarks
2. reject stale bookmarks with `MacPlayError.bookmarkStale`
3. call `startAccessingSecurityScopedResource()` on both URLs
4. build and execute the launch plan
5. on completion or failure, call `stopAccessingSecurityScopedResource()` on both URLs in a `defer` path

Rules:

- access is scoped to the launch operation, not app lifetime
- access must not be started during diagnostics, prefix creation, or profile load
- a dedicated `SecurityScopedAccessManaging` helper is preferred over scattering access calls in UI code
- if access fails to start, launch aborts with a Turkish user-facing error

Sprint 16 documents this lifecycle only; `startAccessingSecurityScopedResource` is not called yet.

### Prefix prerequisites

For Sprint 17 experimental launch:

- prefix directory must already exist (`PrefixDirectoryState.availability == .exists`)
- Wine prefix bootstrap (`wineprefixcreate` or equivalent) is **not** part of Sprint 17 unless a separate amendment says otherwise
- an empty prefix directory alone is insufficient for a successful game start; the first controlled launch is expected to fail gracefully and produce readable logs

This keeps Sprint 17 focused on launch wiring, not full Wine setup automation.

### Process lifecycle

Planned V1 experimental behavior:

- one launch attempt per explicit user action
- no automatic relaunch or watchdog restart
- no concurrent launches for the same profile in V1
- Wine process may outlive the launcher UI; Sprint 17 does not require waiting for game exit before returning control to the UI
- terminate-on-app-quit is out of scope for the first prototype unless explicitly added in Sprint 17

### Logging and failure handling

- stdout and stderr are captured with the same bounded buffer approach as diagnostics (`ProcessCommandRunner` output limit pattern).
- launch failures map to `MacPlayError` or a dedicated launch error type with Turkish `LocalizedError` messages via `ErrorPresenter`.
- successful process start with non-zero early exit is reported as a launch failure with captured stderr excerpt when available.
- no log file persistence in V1 unless Sprint 17 explicitly adds an in-memory session log first.

### Readiness and `canLaunch`

`DefaultRunReadinessEvaluator` stays at `canLaunch: false` through Sprint 16.

Sprint 17 may introduce an experimental launch gate with stricter rules than diagnostics `ready`:

- configured profile with executable and working-directory bookmarks
- prefix directory exists
- allowlisted Wine discovered as ready by real diagnostics or a launch-time re-check
- Rosetta ready on Apple Silicon when required
- explicit user action from a clearly labeled experimental control

Even in Sprint 17, `canLaunch: true` is allowed only behind an experimental policy flag; production default remains blocked until a later stabilization sprint.

### UI policy

Sprint 17 experimental launch UI must:

- use explicit Turkish copy that launch is experimental
- not reuse the diagnostics real-check button
- not auto-launch on app open or profile save
- remain absent from Sprint 16 entirely

Sprint 16 adds no launch button or affordance.

### Cossacks 3 reference

The bundled sample profile remains the template:

- `launchArguments: []`
- `wineArch: win64`
- `environment` includes `WINEARCH` and `DXVK_STATE_CACHE`
- executable and working-directory bookmarks are still required for a user-saved profile before launch

## Consequences

- Sprint 16 is documentation-only; no launch code, bookmark access, or `canLaunch` changes are introduced.
- Sprint 17 can implement launch behind `GameLaunchPlanning` / `GameLaunchExecuting` without reopening command, prefix, or runtime decisions.
- Bookmark access lifecycle becomes a required part of launch implementation; it must not be skipped for path-string convenience.
- Empty-prefix experimental launch is acceptable as a wiring test; full game success is not a Sprint 17 gate.
- Steam automation, runtime install, and `wineprefixcreate` remain separate future work.

## Out of Scope for Sprint 16

- game launch implementation
- launch button or experimental launch UI
- `startAccessingSecurityScopedResource` / `stopAccessingSecurityScopedResource`
- `WINEPREFIX` runtime wiring
- `wineprefixcreate` or Wine prefix bootstrap
- changing `canLaunch`
- runtime download or install
- Steam login automation
- shell execution or `PATH`-based Wine discovery
