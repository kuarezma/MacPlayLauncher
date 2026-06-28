# TASKS — Görev Panosu

> Tek kaynak. Her araç buradan görev alır. Durum değerleri: `todo` · `doing` · `review` · `done` · `blocked`.
> Protokol: [`../../AGENTS.md`](../../AGENTS.md) Bölüm 3 · Sıra: [`HANDOFF.md`](HANDOFF.md)
> Satır formatı: `[ID] başlık | sahip | durum | bağımlı | verify | branch`
> **Tek komut yeterli:** Kullanıcı "**T-XXX yap**" veya "**sıradaki görevini yap**" derse, ilgili görevin tüm detayı (iş/verify/branch) aşağıdadır — protokolü baştan sona kendin uygula.

## Durum Özeti (her tur sonunda güncellenir)

**Dalga 1: 12/12 ✅ TAMAM** · `▰▰▰▰▰▰▰▰▰▰▰▰` · **Dalga 2: 2/3 ✅** `▰⛔▰` (T-012 ✅, T-013 ⛔ engine-bloklu, T-014 ✅)

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
| T-012 | Siyah ekran & Exit-53 otomasyonu | Sonnet (Claude Code) | 🟠 Yüksek | ✅ done |
| T-013 | Minimap şeffaflık & shader yama | Sonnet (Claude Code) | 🟠 Yüksek | ⬜ todo |
| T-014 | Yanlış pencere & çalışma dizini fix | Sonnet (Claude Code) | 🟡 Orta | ✅ done |

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
- **sahip:** Sonnet (Claude Code) · **zeka:** 🟠 Yüksek · **durum:** done · **bağımlı:** T-011 · **branch:** `fix/blackscreen-exit53`
- **iş:** Oyun klasöründe `steam_settings/offline.txt` **tespiti** + exit-53 yakalanınca aksiyon-önerili UI uyarısı.
- **⚠️ Opus kapsam notu:** **SİLME yok.** Geri-alınabilir şekilde `offline.txt → offline.txt.disabled` yeniden adlandır. Oyun klasörüne erişim **yalnız** `SecurityScopedAccessManager`/bookmark deseniyle (mevcut allowlist mimarisi); erişim yoksa UI rehber-uyarısına düş. `CossacksSetupService` tespit desenini yeniden kullan — yeni `Process()`/mutasyon yolu açma.
- **verify:** ✅ `swift test` yeşil (235 test) · ✅ offline.txt tespiti + rename + exit-53 için 9 yeni test · ✅ swiftlint 0

### T-013 · Atlı Birim (Binici) Render Hatası
- **sahip:** Codex (GPT 5.5) · **zeka:** 🔴 Maksimum · **durum:** ⛔ blocked — WineCX 23.7 engine sınırı (launcher-scope KAPANDI) · **bağımlı:** — · **branch:** —
- **✅ Opus görsel teşhisi (2026-06-25, kullanıcı ekran görüntüsü):** Minimap artık **idare ediyor** (cossacks3.app ile geliyor) → **düşük öncelik**. Asıl hata: **atlı birimin binicisi atın üstünde değil, yanında/yerde duruyor.** Teşhis: binici mesh render ediliyor ama **eyer-kemiği (saddle bone) transform'u uygulanmıyor** → vertex'ler yerel orijinde kalıyor. = **vertex bone-skinning** sorunu (`ShaderPatchService` `unit.sm.b*.vert` bone shader alanı) **VEYA** WineCX GL/D3D bone-matrix çeviri sınırı.
- **⚠️ Fizibilite (dürüst):** Kök neden WineCX-engine ise (önceki not: "daha yeni WineCX gerek"), **launcher'daki `ShaderPatchService` düzeltmesi YETMEZ** → fix `~/Cossacks3_Mac_Port` runtime/WineCX tarafında, bu repo DIŞINDA.
- **✅ Codex verdikti (DEVAM_NOTU.md kanıtı):** Shader-side düzeltmeler **tükenmiş**; dinamik `boneMatrices[index]` Apple/Wine GL'de bozuluyor, if-chain/sabit-indeks/guard denemeleri "en iyi sonuç" verdi ama kalan kusur **WineCX 23.7 engine sınırı**. CrossOver 26 ile düzelebilir (ücretsiz CX26 build yok). `ShaderPatchService` artık vertex üretmiyor; yalnız bilinen-iyi shader geri-yükleme + fragment yama + teşhis yapıyor.
- **KARAR:** Launcher-scope **KAPANDI**. Mükemmel eyer = engine upgrade (yeni WineCX / CrossOver 26) → repo-DIŞI runtime işi. Launcher'ın tek opsiyonel rolü: WineCX sürümünü tespit edip "atlı render yeni engine ister" bilgilendirme notu (düşük öncelik, istenirse alt-görev).
- **Minimap:** idare ediyor → kapalı.
> Referans shader aileleri: `unit.sm.b{1,3,5,16,18,20,22,24,27,42}.id*.vert` + shadow/prefixsiz `b*.vert` + `unit.smx{3,9}.id8.frag`.

### T-014 · Yanlış Pencere & Çalışma Dizini Fix
- **sahip:** Sonnet (Claude Code) · **zeka:** 🟡 Orta · **durum:** done · **bağımlı:** T-012 (T-013 engine-bloklu, atlandı) · **branch:** `fix/workdir-window`
- **iş:** `GameLaunchPlanner` working directory çözümlemesi + pencere argümanlarını normalize et (oyun doğru dizinde/pencere modunda açılsın).
- **verify:** ✅ `GameLaunchPlannerTests` yeşil (9 test, 3 yeni) · ✅ 238 test toplam · ✅ swiftlint 0

### T-015 · Performans — kalabalıkta FPS 0-10
- **sahip:** — · **zeka:** 🔴 · **durum:** ⛔ blocked — engine/OpenGL sınırı (FPS fix repo-DIŞI) · **bağımlı:** —
- **✅ Codex runtime teşhisi (kanıtlı):** Opus'un DXVK hipotezi **YANLIŞ çıktı.** Cossacks 3 ana 3D'yi **D3D9'dan değil, doğrudan OpenGL+GLSL** ile çiziyor (`DEVAM_NOTU.md:72`). Aktif yol: WineCX 23.7 + builtin WineD3D (`d3d9.dll` ~200KB builtin) + oyunun kendi GLSL'i. MoltenVK **var ama render yolunda değil**; DXVK **yanlış katman** (D3D→Vulkan), aktif edilse bile bu oyunda fayda düşük ihtimal.
- **Gerçek darboğaz:** OpenGL/GLSL + WineCX 23.7 + Apple GL→Metal çeviri + CPU birim/animasyon yükü. Free engine alternatifleri çalışmıyor (WineHQ 11 SEH fırtınası, CX24 "Need OpenGL 1.1"); stabil tek motor WineCX 23.7. İyileşme = yeni engine (CX26, paralı) → repo-DIŞI.
- **KARAR:** FPS *fix* launcher-scope DIŞI (engine sınırı, cavalry ile aynı kök). Tek in-scope iş → **T-016** (render-yolu teşhisi).

### T-016 · Render-yolu teşhisi (launcher, opsiyonel/düşük öncelik)
- **sahip:** Sonnet (Codex runtime spec'iyle) · **zeka:** 🟠 Yüksek · **durum:** todo (opsiyonel) · **bağımlı:** —
- **iş:** Launcher diagnostics'e "aktif render yolu" tespiti ekle: builtin WineD3D mi / DXVK DLL mi (dosya boyutu/strings ile ayırt et), MoltenVK sadece mevcut mu yoksa aktif mi, oyun OpenGL log özeti. **FPS'i ARTIRMAZ** — yalnız şeffaf teşhis/bilgilendirme (launcher'ın mevcut diagnostics rolüne uyar).
- **verify:** diagnostics aktif render yolunu doğru raporluyor (mevcut durum = builtin WineD3D + OpenGL).

## Runtime Deneyleri (repo-DIŞI: `~/Cossacks3_Mac_Port`)

### T-017 · [RUNTIME] Zink GL→Vulkan→MoltenVK deneyi
- **sahip:** Codex (GPT 5.5, runtime bağlamı) · **zeka:** 🔴 Maksimum · **durum:** ⛔ PARK — KosmicKrisp de `nullDescriptor` sağlamıyor (MoltenVK gibi) + XQuartz(x86_64)/Mesa(arm64) mimari uyumsuzluğu. patch'li Mesa yolu DERİN/düşük-odds → önce **T-018 (CX26 diff)**. · **kapsam:** `~/Cossacks3_Mac_Port` (bu repo DIŞI)
- **iş:** [`ZINK-EXPERIMENT.md`](ZINK-EXPERIMENT.md)'i uygula — **Faz 0 fizikbilite** (winex11.drv + Mesa Zink + MoltenVK + oyunu çalıştıran x11-capable Wine var mı?) → **karar kapısı** → Faz 1 (izole Zink probu) → Faz 2 (Cossacks Zink üzerinde). **Orijinal prefix/script'e dokunma** (kopya üzerinde). Her faz sonunda rapor + Opus'a devret.
- **⚠️ Can alıcı kapı:** WineCX 23.7 mac-driver-only olabilir → oyunu çalıştıran x11'li Wine bulmak/üretmek deneyin make-or-break'i.
- **verify:** Faz 0 raporu (`~/Cossacks3_Mac_Port/ZINK_DENEME_NOTU.md`); kapı geçilirse Faz 1/2 gözlemleri (cavalry eyerde mi, kalabalık FPS).

### T-018 · [RUNTIME] CX26 ↔ WineCX 23.7 fark analizi (Codex planı + Opus onayı)
- **sahip:** **Gemini 3.1 Pro (Antigravity)** — analiz işi, kullanıcının Gemini bütçesi fazla · **zeka:** 🔴 Maksimum (üst düzey thinking) · **durum:** ⛔ iptal (CX26 hatayı çözmüyor) · **bağımlı:** — · **kapsam:** `~/Cossacks3_Mac_Port` (bu repo DIŞI)
- **📚 Bağlam (BAŞLAMADAN OKU — Codex'in runtime geçmişi burada):** `~/Cossacks3_Mac_Port/DEVAM_NOTU.md` (tüm geçmiş denemeler, shader/engine), `~/Cossacks3_Mac_Port/ZINK_DENEME_NOTU.md` (Zink/KosmicKrisp sonuçları), `Docs/coordination/ZINK-EXPERIMENT.md`. Aktif ücretsiz hat: WineCX 23.7 + builtin WineD3D/OpenGL + Goldberg (`oyna_ucretsiz.sh`).
- **Neden (Opus onayı):** Zink/patch'li-Mesa derinleşti (nullDescriptor×2 + arch mismatch) → brute-force yerine **bilgi-önce**. CX26 cavalry'yi düzeltiyorsa NEDEN, ve o fark ÜCRETSİZ tarafa taşınabilir mi? En iyi senaryo: fark sadece ayar/registry/DLL/env → **build YOK, ücretsiz win.**
- **🚨 2026-06-26 GÜNCELLEMESİ (İPTAL NEDENİ):** Kullanıcı CX26 trial kurdu ve görsel kanıt sundu: **Süvari (cavalry) binici hatası CrossOver 26'da DEVAM EDİYOR!** Binici eyerde değil, atın yanında/yerde duruyor. Bu durum, hatanın CX26 ile düzeleceği varsayımını çökertti. Hata, Apple GL veya Wine'ın GL çeviri katmanında derin bir sorun (dinamik bone matrix uniform dizileri) ve en yeni CX motorunda bile mevcut.
- **çıktı/karar:** "Farkı ücretsiz motora taşıma" planı düştü çünkü ortada taşınacak bir çözüm (fix) yok. Süvari hatası şu an macOS üzerinde (Apple GL hattında) çözülemez durumda. T-018 iptal edildi. `Docs/coordination/CX26-DIFF.md` dosyası oluşturulmayacak.
- **verify:** CX26'nın sorunu çözmediği görsel olarak doğrulandı. Görev kapatıldı.

### T-019 · [RUNTIME] Cavalry forensik saldırı (enstrümante — multi-model döngü)
- **sahip (döngü):** Opus tasarım → Codex uygula/render → **Gemini 3.1 Pro görsel yargı** → Opus fix · **zeka: FAZ-BAZLI** (Faz A 🟡 · Faz B 🟠 · görsel yargı 🟠 · fix tasarımı 🔴) — bütün-task değil, fazına bak · **durum:** Faz C ❌ → Faz C.2 (geniş tahmini threshold) ❌ (rider yok + paylaşılan-shader yan hasarı) → **Faz C.3 exact-index dar fix (Codex GPT-5.4) bekliyor — kullanıcı SON-tur onayı** · **kapsam:** `~/Cossacks3_Mac_Port` (repo DIŞI)
- **Tasarım:** ✅ [`CAVALRY-SPEC.md`](CAVALRY-SPEC.md) — **teşhis düzeltmesi:** if-chain dinamik indekslemeyi zaten kaldırmış ama rider hâlâ oturmuyor → eski "dinamik-indeks" teşhisi YANLIŞ, gerçek sebep bilinmiyor. Prime hipotez: **eksik multi-bone blending** (shader yalnız `.x` okuyor). 3-soruyu-tek-karede çözen debug-renk shader: **R=index · G=2.weight · B=guard** → torso yeşilse multi-bone, maviyse guard.
- **Faz A (Codex):** ✅ GLSL log (`+wgl`) + debug-renk shader'ları (KOPYA) uygula+render → PNG seti üretildi.
- **Faz B (Codex):** otomatik screenshot harness (15-20s manuel döngü → tek komut).
- **Faz A.2 / Görsel yargı (Gemini 3.1 Pro, multimodal):** ✅ PNG'lere bakıldı. No-bone (`gl_Position = MVP * gl_Vertex`) testi biniciyi yerde gösterdi. Kemikli (buggy) hali de tam olarak AYNI YERDE (yerde). Sonuç: Matris shader'a "Identity Matrix" (Birim Matris) olarak aktarılıyor. Bu shader içi bir hata (mesh sorunu) değil; Wine-GL uniform aktarım sorunudur. Shader ile düzeltilemez!
- **Faz C (Codex uygula / Opus görsel yargı):** ❌ Exact + `0.001` toleranslı identity-remap uygulandı; doku/horse düzeldi ama **rider oturmadı.** Opus PNG yargısı: doku ✅, horse ✅, rider ❌. Teşhis KESİN: rider yüksek-index bone'u temiz identity gelmiyor → içerik-kontrolü güvenilmez (Faz A: horse=index0, rider=tek yüksek index). (Not: tam `obj_yedek` frag Wine-GL lighting bug'ı → siyah; minimal doku+custColor frag kullanıldı.)
- **Faz C.2 (Codex GPT-5.4 / Opus görsel yargı):** ❌ geniş tahmini threshold (`b16>=8`,`b20>=10`,`b42>=30`, 3 shader'a birden). Geçerli set `20260628_213925`. Opus yargısı: doku ✅, atlar ✅, **rider temiz oturmuyor (sırtta blob) + paylaşılan-shader yan hasarı (totem deformasyonu).** Teşhis: **paylaşılan-shader duvarı** — geniş kural kırık cavalry bone'unu diğer birimlerden ayıramıyor; N'ler ölçülmedi/tahmin.
- **Faz C.3 (Codex GPT-5.4, NEXT — kullanıcı SON-tur onayı):** exact-index dar fix. İzole cavalry → her shader ayrı tint'li index-color ile **gerçek shader+index ölç** → YALNIZ o shader'da `if(index==RIDER_IDX) bone=boneMatrices[0]`, diğer 2 shader `obj_yedek`'e döndür → karışık sahne render. Yapısal yan-hasarsız + tanısal (C.0-C.2 tutarsızlığını çözer). Odds ~%45. Olmazsa → Opus kapatır (forensik yol kanıtla tükendi).
- **çıktı:** `~/Cossacks3_Mac_Port/CAVALRY_FORENSIK_NOTU.md` güncellendi.
- **verify:** Faz C setleri: `cavalry_lab/out/20260628_195726`, `20260628_200709`, `20260628_201332`. Faz C.2 setleri: `20260628_213436` (geçersiz masaüstü capture), `20260628_213925` (geçerli oyun içi capture). `oyna_ucretsiz.sh` SHA1 hâlâ `b18c446b17446a26ef9ca3a561eec34b6bb99624`; orijinal `wine_cx` dizinine dokunulmadı. NEXT: Opus görsel gate + fallback/kapatma kararı.

## Dalga 3 — Yeni yetenek (taslak)
- `canLaunch` kapısını aç, Wine prefix bootstrap, DXVK/MoltenVK gerçek tespiti, log kalıcılığı.
- Akış: Opus tasarım → Codex/Sonnet uygula → Opus review.
