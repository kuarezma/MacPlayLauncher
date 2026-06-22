# MacPlay Launcher

A free, open-source macOS launcher for running **Cossacks 3** on Apple Silicon Macs using CrossOver + Wine, without needing a Windows license. Supports **real Steam multiplayer** via an embedded Wine Steam session.

> Built for M-series Macs. Tested on M3 MacBook with CrossOver 26.

---

## Features

- One-click launch: starts Wine Steam, waits for readiness, then launches the game
- Real Steam multiplayer (friends list, matchmaking, achievements)
- Automatic display resolution switching (1280×800 for game, restored on exit)
- CrossOver bottle integration (no manual Wine configuration)
- OpenGL proxy launch override for the Cossacks 3 macOS shader/minimap fixes
- Cossacks-style launcher preview with resource bar, minimap, buildings, troop formations, and mine-state visual cues
- In-launcher optimization checklist for minimap, Wine Steam, CrossOver bottle, and game resolution readiness
- SwiftUI native app, macOS 14+

---

## Requirements

| Requirement | Details |
|---|---|
| macOS | 14.0 (Sonoma) or newer |
| Mac | Apple Silicon (M1/M2/M3/M4) |
| CrossOver | [CrossOver 26+](https://www.codeweavers.com/crossover) — paid app |
| Cossacks 3 | Must own on Steam |
| displayplacer | `brew install displayplacer` |

---

## Setup Guide

### 1. Install CrossOver and create a bottle

1. Install [CrossOver](https://www.codeweavers.com/crossover)
2. Create a new bottle named exactly **`Cossacks3`** (Win10, 64-bit)

### 2. Install Wine Steam inside the bottle

1. In CrossOver, install **Steam** inside the `Cossacks3` bottle
2. Launch Steam from CrossOver, log into your Steam account
3. In Wine Steam → Library, install **Cossacks 3** (let it download completely)

### 3. Configure ColdClientLoader

In the Cossacks 3 game folder inside the bottle:
```
~/Library/Application Support/CrossOver/Bottles/Cossacks3/drive_c/Program Files (x86)/Steam/steamapps/common/Cossacks 3/
```

Edit `ColdClientLoader.ini` — set the `SteamClient` paths to the real Steam DLLs:
```ini
[SteamClient]
Exe=cossacks.exe
AppId=333420
SteamClientDll=C:\Program Files (x86)\Steam\steamclient.dll
SteamClient64Dll=C:\Program Files (x86)\Steam\steamclient64.dll
```

Make sure `steam_settings/offline.txt` does **not** exist (rename it to `offline.txt.disabled` if present).

### 4. Create the C:\Cossacks3 symlink inside the bottle

```bash
BOTTLE="$HOME/Library/Application Support/CrossOver/Bottles/Cossacks3/drive_c"
GAMEDIR="$BOTTLE/Program Files (x86)/Steam/steamapps/common/Cossacks 3"
ln -s "$GAMEDIR" "$BOTTLE/Cossacks3"
```

### 5. Install displayplacer

```bash
brew install displayplacer
```

### 6. Apply the current macOS port files

The working Cossacks 3 port expects the patched shader set and `opengl32.dll` proxy in the game folder. If you keep the separate `~/Cossacks3_Mac_Port` helper repo, run its minimap fix script after updating game files:

```bash
~/Cossacks3_Mac_Port/apply_minimap_fix.sh
```

### 7. Build and run MacPlayLauncher

```bash
git clone https://github.com/kuarezma/MacPlayLauncher.git
cd MacPlayLauncher
swift build --build-path /tmp/mpl_build -c debug
```

Then create the app bundle and open it (see `scripts/build.sh`):
```bash
./scripts/build.sh
```

The script creates `/tmp/MacPlayLauncher.app` and asks whether to open it.

---

## How It Works

```
OYNA button pressed
  → WineSteamService launches steam.exe inside Cossacks3 bottle
  → Waits for steamwebhelper.exe to appear (Steam is ready)
  → DisplayResolutionService sets display to 1280×800
  → GameLaunchPlanner builds: cxstart --bottle Cossacks3 --env WINEDLLOVERRIDES=opengl32=n,b;d3d9,d3d11,dxgi=b C:\Cossacks3\steamclient_loader_x86.exe
  → ColdClientLoader connects to running Wine Steam → launches cossacks.exe
  → When cossacks.exe exits → DisplayResolutionService restores original resolution
```

The library card also mirrors the expected in-game layout: resources are shown as a top bar, the minimap sits in the bottom-right, buildings use dense city blocks, troops appear in readable formations, and mines are represented as either active mine entrances or depleted dark pits. These are original SwiftUI visuals inspired by Cossacks-style RTS composition; the app does not bundle copyrighted gameplay screenshots or game assets.

---

## Build System Notes

**Use `swift build` — NOT `swift build` from inside Xcode's run button:**

```bash
cd MacPlayLauncher
swift build --build-path /tmp/mpl_build -c debug
```

> The project's `build_output/` folder (used by the release script) must never be inside the project directory during a build. `Package.swift` excludes it, but if it appears, move it out first.

**Do NOT use `xcodebuild` directly** — it hangs on Xcode 26 due to device discovery initialization. Use `scripts/build.sh` which handles all of this automatically.

---

## Project Structure

```
MacPlayLauncher/
├── App/               SwiftUI app entry, AppState, AppEnvironment
├── Core/
│   ├── Models/        GameProfile, GameLaunchPlan, etc.
│   ├── Services/      WineSteamService, DisplayResolutionService, GameLauncher...
│   └── Utilities/     GameProfileDisplayFormatter, PathContainmentValidator...
├── UI/
│   └── GameLibrary/   GameCardView, LibraryView...
├── Resources/
│   ├── Profiles/      cossacks3.profile.json (bundled template)
│   └── Localization/  Localizable.xcstrings (TR + EN)
└── scripts/
    └── build.sh       Watchdog-protected build script
```

---

## Troubleshooting

| Problem | Fix |
|---|---|
| Game exits with code 53 | `steam_settings/offline.txt` must be renamed to `.disabled` |
| "Couldn't find SteamClient64Dll" | Check `ColdClientLoader.ini` paths |
| Wine Steam doesn't open | Check CrossOver bottle name is exactly `Cossacks3` |
| Game opens but no multiplayer | Steam must be running before ColdClientLoader starts |
| Game opens in the wrong window/workdir state | The Cossacks profile should use `~/Cossacks3_Mac_Port/oyun_dosyalari` as its CrossOver working directory |
| Build hangs for hours | Delete `build_output/` from project folder, run `swift build --build-path /tmp/mpl_build` |
| Black screen / crash | Make sure `steam_settings/` folder has no `offline.txt` |
| Minimap is transparent | Re-run `~/Cossacks3_Mac_Port/apply_minimap_fix.sh` and confirm the bundled profile uses `opengl32=n,b;d3d9,d3d11,dxgi=b` |

---

## Changelog

- 2026-06-23: Limited the Cossacks shader patcher to safe fragment/fx fixes and stopped rewriting unit bone vertex shaders so cavalry rendering keeps the working path.
- 2026-06-22: Preserved lighting, fog, and texture outputs in the Cossacks bone shader patch so cavalry meshes avoid dynamic bone indexing without losing render data.
- 2026-06-22: CrossOver launch plans now fall back to the profile working directory path, matching the tested Cossacks port launch folder.
- 2026-06-22: Reworked `scripts/build.sh` to avoid the hanging Xcode build path and create `/tmp/MacPlayLauncher.app` through SwiftPM.
- 2026-06-22: Added the Cossacks-style launcher preview, minimap/resource UI, optimization readiness checklist, and SwiftPM test target.
- 2026-06-21: Aligned the CrossOver launch profile with the OpenGL proxy override and documented the minimap bootstrap fix.

---

## License

MIT
