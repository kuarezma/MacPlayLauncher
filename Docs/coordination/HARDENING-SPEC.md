# HARDENING-SPEC — T-007 (Opus tasarımı)

> **Amaç:** Komut sınırını **async-güvenli** hale getirip `BlockingCommandRunner` semaphore köprüsünü tamamen kaldırmak; `WineSteamService` çift-yolunu tekleştirmek; sabit CrossOver yolunu resolver'a taşımak; son SwiftLint uyarısını (0 hedefi) gidermek.
> **Uygulayan:** T-008 (Codex, 🟠 Yüksek). **Kapsam:** yalnız `ProcessCommandRunner.swift` + `App/AppState+Steam.swift` + `App/AppEnvironment.swift` + `Tests/…/CommandServiceTests.swift`. Davranış (loglar, sıra, timeout'lar, çıktı) korunur.

---

## Teşhis (neden bu tasarım)

`DisplayResolutionService`/`GameProcessMonitor`/`WineSteamService` komutları `CommandRunning.run` (async) üzerinden gidiyor; ama servis metotları **senkron** olduğu için T-002'de async→sync köprüsü (`BlockingCommandRunner`, `DispatchSemaphore.wait()`) eklendi. **Tek çağıran `AppState+Steam.swift` zaten `async`** (satır 40 `await`); üstelik senkron çağrıları `Task.detached { … }` ile thread'den kaçırıyor (satır 42, 84-86). Yani köprüye **hiç gerek yok** — metotları `async` yapınca çağıran doğrudan `await` eder.

`ProcessCommandRunner.run` zaten asıl Process işini `Task.detached(priority: .utility)` içinde koşturuyor → async metotlar **askıya alır, thread bloklamaz**. (İçteki `completion.wait` = sürecin bitişini bekleyen, timeout'lu, utility-thread'deki meşru bekleme; **kapsam dışı**.)

---

## A. `BlockingCommandRunner`'ı kaldır → servisleri `async` yap

**A1. `DisplayResolutionServicing` → async; `DisplayResolutionService` `class @unchecked Sendable` → `actor`**
- Protokol: `func setGameResolution() async` · `func restoreResolution() async`.
- `final class … @unchecked Sendable` yerine **`actor DisplayResolutionService`** — `savedConfig` actor-izole olur, `@unchecked` kalkar (Swift 6 temiz). İç yardımcılar (`mainDisplayConfig`, `runAndCapture`, `runDisplayplacer`) `async` olur.
- `BlockingCommandRunner.run(commandRunner, request:)` → `try? await commandRunner.run(request)`. `commandRunner` zaten non-optional; aynı kalır (default `ProcessCommandRunner(allowedExecutableURLs: [displayplacerURL])`).

**A2. `GameProcessMonitor` → static async**
- `static func isProcessRunning(name:commandRunner:) async -> Bool` · `static func killWineProcesses(commandRunner:) async`.
- Gövdede `BlockingCommandRunner.run(...)` → `await commandRunner.run(request)` (aynı `try?`/sonuç semantiği: `isProcessRunning` başarı= exit0 ⇒ `(try? await …) != nil`).

**A3. `WineSteamServicing.launch` → async; çift-yolu kaldır**
- Protokol: `func launch(bottleName:) async throws`.
- `commandRunner` **non-optional** yap (default `ProcessCommandRunner(allowedExecutableURLs: [wineURL])`). `init`'teki opsiyoneli ve **bare `Process()` dalını (satır 380-386) tamamen sil**. Tek yol: `try await commandRunner.run(request)`.
- `isSteamProcessRunning()` → `await GameProcessMonitor.isProcessRunning(name: "steam.exe", commandRunner: commandRunner)` (artık async).

**A4. `BlockingCommandRunner` + `BlockingCommandResultBox` private tiplerini tamamen kaldır.**

---

## B. Çağıranı sadeleştir — `App/AppState+Steam.swift`

`launchGameWithWineSteam(profileID:)` içinde:
- `try environment.wineSteamService.launch(bottleName:)` → `try await environment.wineSteamService.launch(bottleName:)`
- `await Task.detached { displayService.setGameResolution() }.value` → `await displayService.setGameResolution()`  *(Task.detached sarmalı kalkar)*

`monitorGameExitAndRestoreDisplay(service:)` içinde:
- `let isRunning = await Task.detached { GameProcessMonitor.isProcessRunning(name: "cossacks.exe") }.value` → `let isRunning = await GameProcessMonitor.isProcessRunning(name: "cossacks.exe")`
- `service.restoreResolution()` → `await service.restoreResolution()`
- `GameProcessMonitor.killWineProcesses()` → `await GameProcessMonitor.killWineProcesses()`

> Dıştaki `Task.detached { await AppState.monitorGameExitAndRestoreDisplay(...) }` (satır 44-46) **kalır** — bu meşru fire-and-forget arka plan izleyici, bloklama köprüsü değil.

---

## C. Sabit CrossOver yolu → resolver

`WineSteamService` `static let winePath = "/Applications/CrossOver.app/…/bin/wine"` literalini **kaldır**. `wineURL` default'u `CrossOverExecutableResolver` üzerinden gelsin:
- `App/AppEnvironment.swift`'te `WineSteamService()` wiring'i, resolver'dan çözülmüş URL'i geçsin: `WineSteamService(wineURL: CrossOverExecutableResolver().resolve() ?? CrossOverExecutableResolver.defaultAllowedURLs[0])`.
- `wineURL` `ProcessCommandRunner`'ın default CrossOver allowlist'inde zaten var (`defaultAllowedCrossOverURLs ← CrossOverExecutableResolver.defaultAllowedURLs`) → allowlist sorunu yok.

---

## D. Son lint uyarısı — `runProcess` (63 satır → <50)

`ProcessCommandRunner.runProcess` (satır 39) içinden saf yardımcılar çıkar (davranış birebir): örn. `private static func makeProcess(_ request:) -> (Process, Pipe, Pipe)`, `attachReaders(stdout:stderr:buffer:onOverflow:)`, `awaitExit(_ process:completion:timeout:) throws`. `runProcess` kısa orkestratör kalır. **Bu, SwiftLint'teki tek kalan uyarıyı kapatır → 0.**

---

## Doğrulama (T-008 sonunda)
```sh
swiftlint lint --quiet            # 0 uyarı (D maddesi son uyarıyı kapatır)
swift test --build-path /tmp/mpl_ci_build   # tüm testler yeşil (CommandServiceTests çağrıları `await`'e güncellenir)
./scripts/verify-sprint-18.sh     # Process() yalnız ProcessCommandRunner.swift; boundary korundu
grep -rn "BlockingCommandRunner\|DispatchSemaphore" Core/Services/Commands/ProcessCommandRunner.swift   # köprü: 0; (runProcess içi completion hariç)
```
**Kabul:** `BlockingCommandRunner`/`BlockingCommandResultBox` yok · `WineSteamService`'te bare `Process()` yok · sabit `winePath` literali yok · servis metotları `async` · çağıran `Task.detached` sarmalları kalktı · **swiftlint 0** · testler yeşil · davranış/loglar/timeout'lar değişmedi.

> Not (T-008 test güncellemesi): `CommandServiceTests` artık `async` metotları `await` ile çağırır; `FakeCommandRunner` zaten async `CommandRunning`. Yeni test gerekmez, mevcutlar `await`'e uyarlanır.
