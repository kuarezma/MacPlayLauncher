# REFACTOR-SPEC — T-004 (Opus tasarımı)

> **Amaç:** SwiftLint yapısal uyarılarını gidermek **davranışı değiştirmeden**. Public API, isimler, çıktı stringleri **aynı kalır**; testler yeşil kalır.
> **Uygulayan:** T-005 (Sonnet, 🟠 Yüksek) — ana refactor · T-008 (Codex) — yalnız `ProcessCommandRunner.run()` · T-006 (Haiku) — test isim/tuple.
> **Genel yöntem:** Üyeleri `extension`'lara taşı (SwiftLint `type_body_length` ve `file_length` extension gövdelerini saymaz) → ana tip küçülür. Uzun fonksiyonları küçük `private` yardımcılara böl.

---

## Hedef 1 — `App/AppState.swift` (type_body 356→<300; `makeAddGameProfile` 60→<50)

**Ana dosyada KALIR:** `import`'lar, nested `AddGameFormState` + `NavigationItem`, tüm stored property'ler, `init`, `loadInitialProfiles`, `loadBundledCossacks3Profile`, `prefixTargetProfile`, navigation (`showAddGame/showDiagnostics/showSettings`), `appDataFolderPath`.

**Yeni extension dosyaları** (her biri `extension AppState { … }`, `@MainActor` miras alınır):

| Yeni dosya | Taşınan üyeler |
|---|---|
| `App/AppState+AddGame.swift` | `canSaveAddGameProfile`, `selectGameFolderForAddGame`, `selectExecutableForAddGame`, `saveAddGameProfile`, `cancelAddGame`, `makeAddGameProfile`, `makeProfileID` |
| `App/AppState+Diagnostics.swift` | `canRunManualRealDiagnosticCheck`, `loadRuntimeDiagnosticSummary`, `evaluateRunReadiness`, `evaluateExperimentalRunReadiness`, `restoreCachedDiagnosticsIfAvailable`, `storeDiagnosticsSession`, `resetDiagnosticsSessionToStaticPreparation`, `libraryReadinessResult`, `diagnosticsSessionSourceLabel` |
| `App/AppState+Launch.swift` | `isExperimentalLaunchEnabled`, `experimentalLaunchStatusLabel`, `launchExperimentalGame`, `launchGame`, `loadPrefixDirectoryState`, `createPrefixDirectory` |

> Not: `AppState+Setup.swift` ve `AppState+Steam.swift` zaten var — aynı deseni izle.

**`makeAddGameProfile` bölünmesi** (function_body düzeltmesi) — `AppState+AddGame.swift` içinde iki `private` yardımcı çıkar; ikisi de tek tek <50 satır, gövdeler birebir mevcut `GameProfile(...)` literalleri:
- `private func makeCrossOverProfile(profileID:displayName:folderURL:template:) throws -> GameProfile`
- `private func makeStandardProfile(profileID:displayName:folderURL:executableURL:template:) throws -> GameProfile`
- `makeAddGameProfile()` → kısa dağıtıcı: guard'lar → id+template hesapla → `crossOver` ise `makeCrossOverProfile`, değilse executable guard + `validateExecutable` + `makeStandardProfile`.

⚠️ `private` üyeler taşındıkları extension dosyasında çağrılıyorsa sorun yok; `makeProfileID` ve iki `make…Profile` hep `AppState+AddGame.swift`'te birlikte dursun.

---

## Hedef 2 — `UI/Diagnostics/DiagnosticsViewModel.swift` (file 509→<500; type_body 415→<300)

Bu tip neredeyse tamamen **sunum (localized string / renk) computed property'leri**. State + mutasyon ana dosyada kalır; saf sunum grupları extension'lara taşınır.

**Ana dosyada KALIR:** `import`'lar, `DiagnosticsNextAction` enum, tüm stored property'ler (14-24), `update(...)` aşırı yüklemeleri, tüm setter'lar (`setAllowsManualRealCheck`, `setRunningRealCheck`, `setExperimentalLaunchEnabled`, `setLaunchingExperimental`, `setExperimentalLaunchFeedbackMessage`, `updatePrefixState`, `setCreatingPrefix`, `setPrefixFeedbackMessage`).

**Yeni extension dosyaları** (`extension DiagnosticsViewModel { … }`):

| Yeni dosya | Taşınan üyeler |
|---|---|
| `…/DiagnosticsViewModel+NextStep.swift` | `nextStepTitle`, `nextStepMessage`, `nextAction`, `nextStepButtonTitle`, `showsNextStepButton`, `private firstExperimentalBlockerMessage`, `private needsWinePreparation` |
| `…/DiagnosticsViewModel+Experimental.swift` | `experimentalLaunchTitle/Subtitle/ButtonTitle/LoadingTitle/DisabledNote`, `showsExperimentalLaunchButton`, `experimentalReadinessTitle/Message/Blockers` |
| `…/DiagnosticsViewModel+Prefix.swift` | `prefixTitle/Subtitle/WineBootstrapNote/CreateButtonTitle/CreatingTitle/NoProfileText`, `profileLabel`, `relativePathLabel`, `absolutePathLabel`, `prefixStatusText`, `showsPrefixCreateButton` |
| `…/DiagnosticsViewModel+Source.swift` | `dependencies`, `readinessTitle/Message/Blockers`, `launchNotImplementedText`, `noLaunchThisSprintText`, `overallTitle/Description`, `sourceTitle/Subtitle/Note/BadgeText/NoInstallNote/DxvkMoltenVKLaterNote`, `realCheckButtonTitle/LoadingTitle/returnToPreparationButtonTitle`, `showsManualRealCheckButton`, `showsReturnToPreparationButton`, `lastRealCheckText`, `dependencyVersionText`, `dependencyInstallPathText`, `formattedLastRealCheckText`, `private showsRealCheckDependencyDetails` |
| `…/DiagnosticsViewModel+Badges.swift` | `badgeText`, `badgeColor`, `readinessBadgeText`, `readinessBadgeColor`, `severityText`, `severityColor` |

⚠️ `+Source.swift` ve `+Badges.swift` `SwiftUI` (Color) import'u gerektirir; `+NextStep` vb. yalnız `Foundation`. Her dosyaya gereken import'u ekle. `private` yardımcıları çağrıldıkları extension dosyasında tut.

---

## Hedef 3 — `Core/Services/SetupOrchestrator.swift` (`runOrchestration` cyclomatic 13→<10, body 55→<50)

`runOrchestration` içindeki `while` + büyük `switch target.status` karmaşıklığı parçalanır. Davranış birebir korunur (aynı loglar, aynı sıra).

Bir `private enum OrchestrationControl { case keepGoing, stop }` ekle, şu üç parçaya böl:
- `runOrchestration` → sadece döngü iskeleti: `while !Task.isCancelled { detect → onStepUpdate → steps=fresh → guard target → control = await process(target,onStepUpdate); if case .stop = control { isRunning=false; return } }`. (target yoksa "tümü tamamlandı" logu + return — mevcut davranış.)
- `private func process(target:onStepUpdate:) async -> OrchestrationControl` → mevcut `switch target.status`; `.ok`→keepGoing, `.blocked/.failed`→log+stop, `.waitingForUser`→log+poll+keepGoing, `.needsAction/.checking/.installing`→`await runAutomation(...)`.
- `private func runAutomation(target:onStepUpdate:) async -> OrchestrationControl` → `canAutoFix`/`automationTarget` guard + `installerService.install` + iç `switch result` (completed/waitingForUser) + catch. Mevcut log mesajları aynen.

Her üç metot da tek tek cyclomatic <10 ve body <50 olur.

---

## Hedef 4 — `Core/Services/ExperimentalRunReadinessEvaluator.swift` (`evaluate` 79→<50)

79 satırlık `evaluate` fonksiyonundan, blocker üreten mantığı `private` yardımcılara çıkar (örn. her bağımlılık/kontrol için `appendXBlocker(...)` veya bir `collectBlockers(profiles:summary:) -> [RunReadinessBlocker]` derleyici). `evaluate` kısa kalır: blocker'ları topla → `RunReadinessResult` kur. **Çıktı (blocker sırası/mesajları/canLaunch) birebir korunmalı** — mevcut testler bunu doğrular.

---

## Kapsam DIŞI (başka turlara devredildi — T-011'in "0 uyarı"ı için takip)
- `Core/Services/Commands/ProcessCommandRunner.swift` `run()` (body 63) → **T-008** (güvenlik dosyası; sertleştirmeyle birlikte tek elden; `run()`'dan bir `private` yardımcı çıkar).
- `Tests/…/SelectableDependencyDiagnosticServiceTests.swift` tip adı >40 karakter + `Tests/…/SetupOrchestratorTests.swift` large_tuple → **T-006** (mekanik).

---

## Doğrulama (T-005 sonunda)
```sh
swiftlint lint --quiet            # AppState/DiagnosticsViewModel/SetupOrchestrator/ExperimentalRunReadinessEvaluator → 0
swift test --build-path /tmp/mpl_ci_build   # tüm testler yeşil (davranış değişmedi)
./scripts/verify-sprint-18.sh
```
**Kabul:** type_body_length / file_length / function_body_length / cyclomatic_complexity uyarıları bu dört dosyada 0; test sayısı/sonucu değişmez; hiçbir görünür string/Public API değişmez.
