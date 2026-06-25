# TASKS — Görev Panosu

> Tek kaynak. Her araç buradan görev alır. Durum değerleri: `todo` · `doing` · `review` · `done` · `blocked`.
> Protokol: [`../../AGENTS.md`](../../AGENTS.md) Bölüm 3 · Sıra: [`HANDOFF.md`](HANDOFF.md)
> Satır formatı: `[ID] başlık | sahip | durum | bağımlı | verify | branch`
> **Tek komut yeterli:** Kullanıcı "**T-XXX yap**" veya "**sıradaki görevini yap**" derse, ilgili görevin tüm detayı (iş/verify/branch) aşağıdadır — protokolü baştan sona kendin uygula.

## Durum Özeti (her tur sonunda güncellenir)

**İlerleme: 7/12 (~%58)** · `▰▰▰▰▰▰▰▱▱▱▱▱`

| # | Görev | Model (araç) | Zeka | Durum |
|---|---|---|---|---|
| T-000 | Koordinasyon sistemi kurulumu | Opus (Claude Code) | 🟠 Yüksek | ✅ done |
| T-001 | Mekanik lint temizliği | Haiku (Claude Code) | 🟢 Düşük | ✅ done |
| T-002 | Servis testleri (otonom TDD) | Codex (GPT 5.5) | 🟡 Orta | ✅ done |
| T-003 | Launch & bookmark testleri | Sonnet (Claude Code) | 🟠 Yüksek | ✅ done |
| T-004 | Refactor tasarımı (spec) | Opus (Claude Code) | 🔴 Maksimum | ✅ done |
| T-005 | Refactor uygulaması | Sonnet (Claude Code) | 🟠 Yüksek | ✅ done |
| T-006 | Kalan küçük yapısal lint | Haiku (Claude Code) | 🟡 Orta | ✅ done |
| T-007 | Sertleştirme tasarımı (spec) | Opus (Claude Code) | 🔴 Maksimum | ⬜ todo |
| T-008 | Sertleştirme uygulaması | Codex (GPT 5.5) | 🟠 Yüksek | ⬜ todo |
| T-009 | Tüm-kod denetimi + doküman + görsel | Gemini 3.1 Pro (Antigravity) | 🟠 Yüksek | ⬜ todo |
| T-010 | Changelog & triyaj | Gemini 3.5 Flash (Antigravity) | 🟢 Düşük | ⬜ todo |
| T-011 | Final review + merge | Opus (Claude Code) | 🔴 Maksimum | ⬜ todo |

> Zeka seviyesi ölçeği + araç ayarları: [`../../AGENTS.md`](../../AGENTS.md) Bölüm 2C. Model başlamadan önce bu seviyeyi kullanıcıya bildirir (protokol Bölüm 3, adım 0).
> Bir görevi tamamlayınca **hem** bu özet satırını **hem** aşağıdaki detay bloğunu güncelle.

## Dalga 1 — Kod Sağlığı

### T-000 · Koordinasyon sistemi kurulumu
- **sahip:** Opus (Claude Code) · **durum:** done · **bağımlı:** — · **branch:** main
- **iş:** `AGENTS.md`, `CLAUDE.md`, `GEMINI.md`, `Docs/coordination/TASKS.md`, `Docs/coordination/HANDOFF.md` oluştur; backlog'u tohumla.
- **verify:** dosyalar mevcut; `HANDOFF.md` `NEXT:` satırı T-001'i gösteriyor.

### T-001 · Mekanik lint temizliği
- **sahip:** Haiku (Claude Code) · **durum:** done · **bağımlı:** T-000 · **branch:** `chore/lint-mechanical`
- **iş:** SwiftLint mekanik uyarıları gider: ~29 sorted-imports, ~25 trailing-newline, ~22 line-length (120+ satırları sar/böl), 1 trailing-whitespace, kısa değişken adları `t`/`v`/`p` (`ProcessCommandRunner.swift`), 1 unneeded-synthesized-init (`FakeCommandRunner`), 1 implicit-optional-init. **Sadece format/isim**, mantık değiştirme.
- **verify:** ✅ `swiftlint lint --quiet` → bu kategorilerde 0 · ✅ `swift test --build-path /tmp/mpl_ci_build` yeşil

### T-002 · Eksik servis testleri (otonom TDD)
- **sahip:** Codex (GPT 5.5) · **durum:** done · **bağımlı:** T-001 · **branch:** `test/command-services`
- **iş:** `DisplayResolutionService`, `WineSteamService`, `GameProcessMonitor` için birim testleri yaz (`FakeCommandRunner` test double'ı ile; gerçek Process spawn etme). Dosyalar `Core/Services/Commands/` altında.
- **verify:** `swift test --build-path /tmp/mpl_ci_build` yeşil; yeni testler koşuyor

### T-003 · Launch & bookmark testleri
- **sahip:** Sonnet (Claude Code) · **durum:** done · **bağımlı:** T-001 · **branch:** `test/launch-bookmark`
- **iş:** `ProcessGameLaunchExecutor` (gerçek launch yolu) ve security-scoped bookmark yaşam döngüsü (`SecurityScopedAccessManager` start/stop) için entegrasyon testleri. `paralel: evet` (T-002 ile farklı dosyalar).
- **verify:** ✅ `swift test --build-path /tmp/mpl_ci_build` yeşil (226 test)

### T-004 · Refactor tasarımı (spec)
- **sahip:** Opus (Claude Code) · **durum:** done · **bağımlı:** T-002, T-003 · **branch:** main
- **iş:** Spec yazıldı → [`REFACTOR-SPEC.md`](REFACTOR-SPEC.md). 4 hedef + extension bölme planı + fonksiyon parçalama; orphan uyarılar T-006/T-008'e devredildi.
- **verify:** ✅ `REFACTOR-SPEC.md` mevcut; T-005 alt-hedefleri aşağıda

### T-005 · Refactor uygulaması
- **sahip:** Sonnet (Claude Code) · **durum:** todo · **bağımlı:** T-004 · **branch:** `refactor/appstate-diagnostics`
- **iş:** [`REFACTOR-SPEC.md`](REFACTOR-SPEC.md)'i uygula — 4 hedef: ① `AppState` → `+AddGame/+Diagnostics/+Launch` extension'ları + `makeAddGameProfile` böl; ② `DiagnosticsViewModel` → `+NextStep/+Experimental/+Prefix/+Source/+Badges` extension'ları; ③ `SetupOrchestrator.runOrchestration` → `process`/`runAutomation` böl; ④ `ExperimentalRunReadinessEvaluator.evaluate` → yardımcılara böl. **Davranış/public API/string'ler birebir aynı.**
- **verify:** `swift test --build-path /tmp/mpl_ci_build` yeşil · `swiftlint lint --quiet` → bu 4 dosyada type_body_length / file_length / function_body_length / cyclomatic_complexity 0

### T-006 · Kalan küçük yapısal lint
- **sahip:** Haiku (Claude Code) · **durum:** done · **bağımlı:** T-005 · **branch:** `chore/lint-structural`
- **iş:** `WineDiagnosticProvider` 6 param → parametre struct'ına sar (≤5); `SetupOrchestratorTests` large-tuple → adlandırılmış tip; `SelectableDependencyDiagnosticServiceTests` tip adını (>40 karakter) kısalt.
- **verify:** ✅ `swiftlint lint --quiet` → function_parameter_count / large_tuple / type_name 0 · ✅ `swift test` yeşil (226 test)

### T-007 · Sertleştirme tasarımı (spec)
- **sahip:** Opus (Claude Code) · **durum:** todo · **bağımlı:** T-006 · **branch:** `docs/hardening-spec`
- **NOT (T-002 devri):** `DisplayResolutionService` + `GameProcessMonitor` allowlist yönlendirmesi T-002'de Codex tarafından **erken yapıldı**; geçici olarak `BlockingCommandRunner` (semaphore köprüsü, `Task.detached`) ile çalışıyor. Asıl tasarım işi artık: **async-güvenli sınırı tasarla → `BlockingCommandRunner` semaphore köprüsünü tamamen kaldır** (launch akışını async yap, çağıranları `await`'e geçir).
- **iş:** Yukarıdaki async-güvenli boundary tasarımı + `WineSteamService` çift-yol (nil → bare `Process()`) tutarsızlığını gider + sabit CrossOver yolunu resolver'a taşı. Güvenlik gerekçesi + allowlist yolları.
- **verify:** spec dosyası (`Docs/coordination/HARDENING-SPEC.md`) mevcut

### T-008 · Sertleştirme uygulaması
- **sahip:** Codex (GPT 5.5) · **durum:** todo · **bağımlı:** T-007 · **branch:** `refactor/command-boundary`
- **iş:** T-007 spec'ini uygula: `BlockingCommandRunner` köprüsünü kaldır, çağrı yerlerini async-güvenli yap, `WineSteamService` çift-yolunu tek yola indir, tüm `Process()` çağrılarının `ProcessCommandRunner` üzerinden gittiğini garanti et.
- **verify:** `swift test` yeşil · `./scripts/verify-sprint-18.sh` yeşil (`Process()` yalnız `ProcessCommandRunner.swift` kriteri) · `BlockingCommandRunner` kaldırıldı

### T-009 · Tüm-kod denetimi + doküman + görsel teşhis
- **sahip:** Gemini 3.1 Pro (Antigravity) · **durum:** todo · **bağımlı:** T-008 · **branch:** `docs/audit-architecture`
- **iş:** Geniş-bağlam tutarlılık denetimi (kalan baypaslar, ölü kod, çapraz tutarsızlık) → rapor (`Docs/coordination/AUDIT.md`). `ARCHITECTURE.md`'ye yeni sprint girişi. Kullanıcı ekran görüntüsü verirse minimap/shader **görsel** teşhis.
- **verify:** `AUDIT.md` mevcut; `ARCHITECTURE.md` güncel

### T-010 · Changelog & triyaj
- **sahip:** Gemini 3.5 Flash (Antigravity) · **durum:** todo · **bağımlı:** T-009 · **branch:** `docs/changelog-triage`
- **iş:** README/changelog rötuş, `TASKS.md` özet, `HANDOFF.md` temizlik, **Dalga 2 (hatalar)** triyaj backlog'u taslağı (bu panoya `## Dalga 2` bölümü).
- **verify:** dokümanlar güncel; Dalga 2 bölümü taslak hâlinde

### T-011 · Final review + merge
- **sahip:** Opus (Claude Code) · **durum:** todo · **bağımlı:** T-010 · **branch:** `main` (review/merge)
- **iş:** Tüm Dalga 1 diff'ini incele (correctness, readability, architecture, security, performance). CI yeşil mi, `swiftlint` 0 uyarı mı doğrula → branch'leri main'e merge et.
- **verify:** `swiftlint lint --quiet` 0 uyarı · `swift test` yeşil · CI yeşil

---

## Dalga 2 — Hatalar (taslak, T-010'da detaylandırılır)
- exit-code 53 / `offline.txt`, siyah ekran, minimap şeffaflığı, yanlış pencere durumu için launcher-tarafı otomasyon.
- Akış: Gemini Pro teşhis → Sonnet uygula → Opus review.

## Dalga 3 — Yeni yetenek (taslak)
- `canLaunch` kapısını aç, Wine prefix bootstrap, DXVK/MoltenVK gerçek tespiti, log kalıcılığı.
- Akış: Opus tasarım → Codex/Sonnet uygula → Opus review.
