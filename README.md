# MacPlay Launcher

A free, open-source macOS launcher for running **Cossacks 3** on Apple Silicon Macs using a local WineCX/Wine runtime, without needing CrossOver or a Windows license. Supports the tested local Cossacks 3 port path.

> Built for M-series Macs. Current Cossacks 3 flow targets the local `~/Cossacks3_Mac_Port` WineCX port.

---

## Kullanıcı Kurulumu (Normal Kullanıcı)

1. [GitHub Releases](../../releases) sayfasından `MacPlayLauncher.dmg` veya `MacPlayLauncher.zip` dosyasını indir
2. DMG'yi aç veya ZIP'i çıkar → `MacPlayLauncher.app` simgesini `Applications` klasörüne sürükle
3. Uygulamayı aç — uygulama uygun kurulum adımlarını arka planda kendisi başlatır
4. **Kurulum Rehberi** ekranından ilerlemeyi izle; gerekirse yalnızca duraklat/devam ettir
5. Yerel `~/Cossacks3_Mac_Port` klasörünü hazır tut; CrossOver trial/lisans adımı gerekmez

### Gereksinimler

| Gereksinim | Detay |
|---|---|
| macOS | 14.0 (Sonoma) veya üzeri |
| Mac | Apple Silicon (M1/M2/M3/M4) |
| Yerel port | `~/Cossacks3_Mac_Port` içinde `winecx_engine` ve `oyun_dosyalari` |
| Oyun dosyası | `oyun_dosyalari/steamclient_loader_x86.exe` ve `cossacks.exe` |

---

## Features

- One-click launch: starts Wine Steam, waits for readiness, then launches the game
- Real Steam multiplayer (friends list, matchmaking, achievements)
- Automatic display resolution switching (1280×800 for game, restored on exit)
- Local Cossacks 3 WineCX port integration without CrossOver trial/runtime dependency
- Background setup checks for Rosetta, the local Cossacks 3 port, shader repair, minimap data, and displayplacer
- Local WineCX runtime is preferred before Homebrew Wine
- WineD3D launch override for the Cossacks 3 macOS shader/minimap fixes
- Free local port shader repair that restores visible unit bone shaders before applying safe fragment/fx fixes
- Cossacks-style launcher preview with resource bar, minimap, buildings, troop formations, and mine-state visual cues
- In-launcher optimization checklist for minimap, local Wine runtime, and game resolution readiness
- SwiftUI native app, macOS 14+

---

## Requirements

| Requirement | Details |
|---|---|
| macOS | 14.0 (Sonoma) or newer |
| Mac | Apple Silicon (M1/M2/M3/M4) |
| Local Cossacks 3 port | `~/Cossacks3_Mac_Port` with the bundled WineCX engine and game files |
| displayplacer | Installed by the in-app setup guide when Homebrew is available |

---

## Setup Guide

### 1. Run the in-app Setup Guide

Open MacPlay Launcher. The app detects missing setup steps and starts eligible automation in the background. Open **Kurulum Rehberi** to follow progress, pause, or resume.

The app can automate:

- Rosetta installation via Apple's `softwareupdate`
- opening the official Homebrew installer in Terminal when Homebrew is missing
- installing `displayplacer` through Homebrew
- detecting the local Cossacks 3 port and applying safe shader/minimap checks

The app does not store game-service credentials and does not bypass license checks. The current Cossacks 3 flow does not require CrossOver trial/license approval.

### 2. Prepare the local Cossacks 3 port

The tested path is:

```bash
~/Cossacks3_Mac_Port/oyun_dosyalari
```

It should contain:

```bash
cossacks.exe
steamclient_loader_x86.exe
data/shaders/obj
```

### 3. Configure ColdClientLoader if your port files require it

In `~/Cossacks3_Mac_Port/oyun_dosyalari`, keep `ColdClientLoader.ini` pointed at the local game executable:

```ini
[SteamClient]
Exe=cossacks.exe
AppId=333420
```

### 4. Apply the current macOS port files

The working Cossacks 3 port expects the patched shader set in the game folder. If you keep the separate `~/Cossacks3_Mac_Port` helper repo, run its minimap fix script after updating game files:

```bash
~/Cossacks3_Mac_Port/apply_minimap_fix.sh
```

### 5. Build and run MacPlayLauncher

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
  → Local WineCX engine is selected from ~/Cossacks3_Mac_Port/winecx_engine/wswine.bundle/bin/wine64
  → DisplayResolutionService sets display to 1280×800
  → GameLaunchPlanner starts steamclient_loader_x86.exe from ~/Cossacks3_Mac_Port/oyun_dosyalari
  → ColdClientLoader launches cossacks.exe through the local Wine prefix
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
| "Uygulama açılamadı" / Gatekeeper uyarısı | System Settings → Privacy & Security → "Yine de Aç" |
| Homebrew Terminal komutu çalışmıyor | Terminal'de `xcode-select --install` çalıştır, sonra tekrar dene |
| Yerel WineCX bulunamadı | `~/Cossacks3_Mac_Port/winecx_engine/wswine.bundle/bin/wine64` yolunu kontrol et |
| Game exits with code 53 | `steam_settings/offline.txt` must be renamed to `.disabled` |
| "Couldn't find SteamClient64Dll" | Yerel port için `ColdClientLoader.ini` yollarını kontrol et |
| Game opens in the wrong window/workdir state | The Cossacks profile should use `~/Cossacks3_Mac_Port/oyun_dosyalari` as its working directory |
| Build hangs for hours | Delete `build_output/` from project folder, run `swift build --build-path /tmp/mpl_build` |
| Black screen / crash | Make sure `steam_settings/` folder has no `offline.txt` |
| Minimap is transparent | Re-run `~/Cossacks3_Mac_Port/apply_minimap_fix.sh` and confirm the bundled profile uses `d3d9,d3d11,dxgi=b` |

### Notarization kurulumu (geliştirici — bir kez yapılır)

Developer ID sertifikası edindikten sonra notary kimlik bilgilerini Keychain'e kaydet:

```bash
xcrun notarytool store-credentials "MacPlayNotary" \
    --apple-id "APPLE_ID_EMAILINIZ" \
    --team-id "TEAM_ID" \
    --password "@keychain:APP_SPECIFIC_PASSWORD"
```

App-specific password için: [appleid.apple.com](https://appleid.apple.com) → Sign-In and Security → App-Specific Passwords.

Kaydedildikten sonra `./scripts/create-release.sh v0.24.0` otomatik olarak notarize eder ve staple uygular.

---

## Changelog

- 2026-06-25: Refactored core services to be fully async/await native, eliminating the legacy `BlockingCommandRunner` bridge and removing all blocking semaphore patterns.
- 2026-06-25: Enforced strict command execution boundaries by routing `DisplayResolutionService`, `GameProcessMonitor`, and `WineSteamService` directly through `CommandRunning`.
- 2026-06-25: Resolved CrossOver executable paths through `AppEnvironment` wiring instead of hardcoded strings in services.
- 2026-06-25: Achieved zero SwiftLint warnings across the codebase to ensure strict adherence to style guidelines.
- 2026-06-24: Removed the default Cossacks 3 CrossOver dependency by switching setup, profile, Wine resolution, and local `oyna.sh` launch flow to the local WineCX port.
- 2026-06-24: Restored Cossacks visible unit vertex shaders from local backups and kept the launcher shader patch limited to safe fragment/fx fixes.
- 2026-06-23: Updated CI to run the current sprint verification, use stable SwiftPM tests, and allow only controlled setup installer command usage.
- 2026-06-23: Updated install notes to cover both DMG and ZIP release artifacts.
- 2026-06-23: Fixed release checksum generation so SHA256SUMS keeps the hash and artifact path.
- 2026-06-23: Prepared v0.24.0 release notes for background setup automation and CrossOver-managed runtime readiness.
- 2026-06-23: Started eligible setup automation in the background and stopped showing separate Wine/DXVK/MoltenVK blockers for CrossOver profiles.
- 2026-06-23: Added guided setup automation for Rosetta, CrossOver trial, `Cossacks3` bottle creation, Wine Steam preparation, and displayplacer.
- 2026-06-23: Made `scripts/build.sh` finish successfully in non-interactive runs after creating `/tmp/MacPlayLauncher.app`.
- 2026-06-23: Limited the Cossacks shader patcher to safe fragment/fx fixes and stopped rewriting unit bone vertex shaders so cavalry rendering keeps the working path.
- 2026-06-22: Preserved lighting, fog, and texture outputs in the Cossacks bone shader patch so cavalry meshes avoid dynamic bone indexing without losing render data.
- 2026-06-22: CrossOver launch plans now fall back to the profile working directory path, matching the tested Cossacks port launch folder.
- 2026-06-22: Reworked `scripts/build.sh` to avoid the hanging Xcode build path and create `/tmp/MacPlayLauncher.app` through SwiftPM.
- 2026-06-22: Added the Cossacks-style launcher preview, minimap/resource UI, optimization readiness checklist, and SwiftPM test target.
- 2026-06-21: Aligned the CrossOver launch profile with the OpenGL proxy override and documented the minimap bootstrap fix.

---

## License

MIT
