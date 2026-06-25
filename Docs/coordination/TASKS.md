# TASKS — Görev Panosu

> Tek kaynak. Her araç buradan görev alır. Durum değerleri: `todo` · `doing` · `review` · `done` · `blocked`.
> Protokol: [`../../AGENTS.md`](../../AGENTS.md) Bölüm 3 · Sıra: [`HANDOFF.md`](HANDOFF.md)
> Satır formatı: `[ID] başlık | sahip | durum | bağımlı | verify | branch`
> **Tek komut yeterli:** Kullanıcı "**T-XXX yap**" veya "**sıradaki görevini yap**" derse, ilgili görevin tüm detayı (iş/verify/branch) aşağıdadır — protokolü baştan sona kendin uygula.

## Durum Özeti (her tur sonunda güncellenir)

**Dalga 1: 12/12 ✅ TAMAM** · `▰▰▰▰▰▰▰▰▰▰▰▰` · (Dalga 2: 0/3 — T-012…T-014 backlog hazır)

| # | Görev | Model (araç) | Zeka | Durum |
|---|---|---|---|---|
| T-000 | Koordinasyon sistemi kurulumu | Opus (Claude Code) | 🟠 Yüksek | ✅ done |
| T-001 | Mekanik lint temizliği | Haiku (Claude Code) | 🟢 Düşük | ✅ done |
| T-002 | Servis testleri (otonom TDD) | Codex (GPT 5.5) | 🟡 Orta | ✅ done |
| T-003 | Launch & bookmark testleri | Sonnet (Claude Code) | 🟠 Yüksek | ✅ done |
| T-004 | Refactor tasarımı (spec) | Opus (Claude Code) | 🔴 Maksimum | ✅ done |
| T-005 | Refactor uygulaması | Sonnet (Claude Code) | 🟠 Yüksek | ✅ done |
| T-006 | Kalan küçük yapısal lint | Haiku (Claude Code) | 🟡 Orta | ✅ done |
| T-007 | Sertleştirme tasarımı (spec) | Opus (Claude Code) | 🔴 Maksimum | ✅ done |
| T-008 | Sertleştirme uygulaması | Codex (GPT 5.5) | 🟠 Yüksek | ✅ done |
| T-009 | Tüm-kod denetimi + doküman + görsel | Gemini 3.1 Pro (Antigravity) | 🟠 Yüksek | ✅ done |
| T-010 | Changelog & triyaj | Gemini 3.5 Flash (Antigravity) | 🟢 Düşük | ✅ done |
| T-011 | Final review + merge | Opus (Claude Code) | 🔴 Maksimum | ✅ done |
| T-012 | Siyah ekran & Exit-53 otomasyonu | Sonnet (Claude Code) | 🟠 Yüksek | ⬜ todo |
| T-013 | Minimap şeffaflık & shader yama | Sonnet (Claude Code) | 🟠 Yüksek | ⬜ todo |
| T-014 | Yanlış pencere & çalışma dizini fix | Sonnet (Claude Code) | 🟠 Yüksek | ⬜ todo |

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
- **sahip:** Opus (Claude Code) · **durum:** done · **bağımlı:** T-006 · **branch:** main
- **NOT (T-002 devri):** `DisplayResolutionService` + `GameProcessMonitor` allowlist yönlendirmesi T-002'de Codex tarafından **erken yapıldı**; geçici olarak `BlockingCommandRunner` (semaphore köprüsü, `Task.detached`) ile çalışıyor. Asıl tasarım işi artık: **async-güvenli sınırı tasarla → `BlockingCommandRunner` semaphore köprüsünü tamamen kaldır** (launch akışını async yap, çağıranları `await`'e geçir).
- **iş:** Yukarıdaki async-güvenli boundary tasarımı + `WineSteamService` çift-yol (nil → bare `Process()`) tutarsızlığını gider + sabit CrossOver yolunu resolver'a taşı. Güvenlik gerekçesi + allowlist yolları.
- **verify:** ✅ [`HARDENING-SPEC.md`](HARDENING-SPEC.md) mevcut (A: async sınır + `BlockingCommandRunner` kaldır, B: çağıran sadeleştir, C: resolver, D: son lint → 0)

### T-008 · Sertleştirme uygulaması
- **sahip:** Codex (GPT 5.5) · **durum:** done · **bağımlı:** T-007 · **branch:** `refactor/command-boundary`
- **iş:** [`HARDENING-SPEC.md`](HARDENING-SPEC.md)'i uygula: `BlockingCommandRunner`+çağırandaki `Task.detached` köprülerini kaldır (servis metotları `async`, `DisplayResolutionService`→`actor`), `AppState+Steam.swift`'i `await`'e geçir, `WineSteamService` çift-yol + sabit CrossOver yolunu kaldır (resolver), `runProcess`'i böl (son lint → 0). **Davranış korunur**, `CommandServiceTests` `await`'e uyarlanır.
- **verify:** `swift test` yeşil · `./scripts/verify-sprint-18.sh` yeşil (`Process()` yalnız `ProcessCommandRunner.swift` kriteri) · `BlockingCommandRunner` kaldırıldı

### T-009 · Tüm-kod denetimi + doküman + görsel teşhis
- **sahip:** Gemini 3.1 Pro (Antigravity) · **durum:** done · **bağımlı:** T-008 · **branch:** `docs/audit-architecture`
- **iş:** Geniş-bağlam tutarlılık denetimi (kalan baypaslar, ölü kod, çapraz tutarsızlık) → rapor (`Docs/coordination/AUDIT.md`). `ARCHITECTURE.md`'ye yeni sprint girişi. Kullanıcı ekran görüntüsü verirse minimap/shader **görsel** teşhis.
- **verify:** `AUDIT.md` mevcut; `ARCHITECTURE.md` güncel

### T-010 · Changelog & triyaj
- **sahip:** Gemini 3.5 Flash (Antigravity) · **durum:** done · **bağımlı:** T-009 · **branch:** `docs/changelog-triage`
- **iş:** README/changelog rötuş, `TASKS.md` özet, `HANDOFF.md` temizlik, **Dalga 2 (hatalar)** triyaj backlog'u taslağı (bu panoya `## Dalga 2` bölümü).
- **verify:** dokümanlar güncel; Dalga 2 bölümü taslak hâlinde

### T-011 · Final review + merge
- **sahip:** Opus (Claude Code) · **durum:** done · **bağımlı:** T-010 · **branch:** main
- **iş:** Tüm Dalga 1 incelendi (her tur zaten gate'lenip main'e alındı). Final doğrulama main'de koşuldu.
- **verify:** ✅ `swiftlint lint --quiet` **0 uyarı** · ✅ `swift test` **226 yeşil** (1 skip) · ✅ `verify-sprint-18` 17/17 · ✅ `Process()` yalnız `ProcessCommandRunner`

---

## Dalga 2 — Hatalar (T-010 taslak + Opus rafine)

> **Opus notu (Dalga 1 dersi):** Bunlar **gerçek oyun-runtime hataları** — Dalga 1'in test-kanıtlanabilir işlerinden farklı; nihai doğrulama gerçek oyunla/ekran görüntüsüyle olur. Akış: **görsel/runtime olanlarda önce teşhis (Gemini Pro / Opus)** → Sonnet uygula → Opus review. Dosya mutasyonları **geri-alınabilir** + `SecurityScopedAccessManager` erişimiyle yapılır; erişim yoksa UI rehberliğine düşülür.

### T-012 · Siyah Ekran & Exit-53 Otomasyonu
- **sahip:** Sonnet (Claude Code) · **zeka:** 🟠 Yüksek · **durum:** todo · **bağımlı:** T-011 · **branch:** `fix/blackscreen-exit53`
- **iş:** Oyun klasöründe `steam_settings/offline.txt` **tespiti** + exit-53 yakalanınca aksiyon-önerili UI uyarısı.
- **⚠️ Opus kapsam notu:** **SİLME yok.** Geri-alınabilir şekilde `offline.txt → offline.txt.disabled` yeniden adlandır. Oyun klasörüne erişim **yalnız** `SecurityScopedAccessManager`/bookmark deseniyle (mevcut allowlist mimarisi); erişim yoksa UI rehber-uyarısına düş. `CossacksSetupService` tespit desenini yeniden kullan — yeni `Process()`/mutasyon yolu açma.
- **verify:** `swift test` yeşil · offline.txt tespiti + rename + exit-53 için fake/mock testleri.

### T-013 · Atlı Birim (Binici) Render Hatası
- **sahip:** Codex (GPT 5.5) · **zeka:** 🔴 Maksimum · **durum:** ⛔ blocked — WineCX 23.7 engine sınırı (launcher-scope KAPANDI) · **bağımlı:** — · **branch:** —
- **✅ Opus görsel teşhisi (2026-06-25, kullanıcı ekran görüntüsü):** Minimap artık **idare ediyor** (cossacks3.app ile geliyor) → **düşük öncelik**. Asıl hata: **atlı birimin binicisi atın üstünde değil, yanında/yerde duruyor.** Teşhis: binici mesh render ediliyor ama **eyer-kemiği (saddle bone) transform'u uygulanmıyor** → vertex'ler yerel orijinde kalıyor. = **vertex bone-skinning** sorunu (`ShaderPatchService` `unit.sm.b*.vert` bone shader alanı) **VEYA** WineCX GL/D3D bone-matrix çeviri sınırı.
- **⚠️ Fizibilite (dürüst):** Kök neden WineCX-engine ise (önceki not: "daha yeni WineCX gerek"), **launcher'daki `ShaderPatchService` düzeltmesi YETMEZ** → fix `~/Cossacks3_Mac_Port` runtime/WineCX tarafında, bu repo DIŞINDA.
- **✅ Codex verdikti (DEVAM_NOTU.md kanıtı):** Shader-side düzeltmeler **tükenmiş**; dinamik `boneMatrices[index]` Apple/Wine GL'de bozuluyor, if-chain/sabit-indeks/guard denemeleri "en iyi sonuç" verdi ama kalan kusur **WineCX 23.7 engine sınırı**. CrossOver 26 ile düzelebilir (ücretsiz CX26 build yok). `ShaderPatchService` artık vertex üretmiyor; yalnız bilinen-iyi shader geri-yükleme + fragment yama + teşhis yapıyor.
- **KARAR:** Launcher-scope **KAPANDI**. Mükemmel eyer = engine upgrade (yeni WineCX / CrossOver 26) → repo-DIŞI runtime işi. Launcher'ın tek opsiyonel rolü: WineCX sürümünü tespit edip "atlı render yeni engine ister" bilgilendirme notu (düşük öncelik, istenirse alt-görev).
- **Minimap:** idare ediyor → kapalı.
> Referans shader aileleri: `unit.sm.b{1,3,5,16,18,20,22,24,27,42}.id*.vert` + shadow/prefixsiz `b*.vert` + `unit.smx{3,9}.id8.frag`.

### T-014 · Yanlış Pencere & Çalışma Dizini Fix
- **sahip:** Sonnet (Claude Code) · **zeka:** 🟡 Orta · **durum:** todo · **bağımlı:** T-013 · **branch:** `fix/workdir-window`
- **iş:** `GameLaunchPlanner` working directory çözümlemesi + pencere argümanlarını normalize et (oyun doğru dizinde/pencere modunda açılsın).
- **verify:** `GameLaunchPlannerTests` yeşil.

### T-015 · Performans — kalabalıkta FPS 0-10 (DXVK/MoltenVK render yolu)
- **sahip:** Codex (GPT 5.5 — runtime bağlamı) · **zeka:** 🔴 Maksimum · **durum:** todo · **bağımlı:** — · **branch:** (büyük ihtimalle runtime/repo-dışı)
- **✅ Opus teşhisi (kullanıcı: kalabalıkta 0-10 FPS, idle ~17):** Muhtemel kök neden: (a) **render yolu** — oyun WineD3D→OpenGL'de koşuyor olabilir (`WINEDLLOVERRIDES=…=b` builtin/software D3D); hızlı yol **DXVK→MoltenVK** (D3D→Vulkan→Metal), ~2-5× kazanç; (b) **CPU** — Wine+Rosetta+binlerce birim, daha az düzeltilebilir.
- **⚠️ Scope:** FPS launcher Swift kodunda **doğrudan çözülmez** — render yolu WineCX/prefix config'inde. Launcher rolü: **DXVK/MoltenVK tespit + etkinleştirme rehberliği** (mevcut passive diagnostics → aksiyon-önerili). Asıl fix runtime tarafında (Dalga 3 "DXVK/MoltenVK" ile örtüşür).
- **iş — Codex'e danış:** Cossacks3 prefix'inde DXVK+MoltenVK kurulu/aktif mi? Değilse etkinleştirme adımları → FPS kazancı; launcher diagnostics'ini buna göre aksiyon-önerili yap.
- **verify:** gerçek oyunda kalabalık-sahne FPS ölçümü iyileşti.

## Dalga 3 — Yeni yetenek (taslak)
- `canLaunch` kapısını aç, Wine prefix bootstrap, DXVK/MoltenVK gerçek tespiti, log kalıcılığı.
- Akış: Opus tasarım → Codex/Sonnet uygula → Opus review.

