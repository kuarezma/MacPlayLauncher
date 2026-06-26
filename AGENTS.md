# AGENTS.md — Çok-Modelli Ortak Çalışma Sözleşmesi

> Bu dosya **tüm AI araçları** (Codex, Claude Code, Antigravity/Gemini) için **tek kaynaktır**.
> Bir göreve başlamadan önce buradaki **Görev Döngüsü Protokolü**'nü uygula.
> Devir-teslim durumu: [`Docs/coordination/HANDOFF.md`](Docs/coordination/HANDOFF.md) · Görev panosu: [`Docs/coordination/TASKS.md`](Docs/coordination/TASKS.md)

---

## 1. Proje Özeti

**MacPlayLauncher** — Apple Silicon Mac'lerde Cossacks 3'ü Wine/WineCX ile çalıştıran native macOS launcher. Swift 6 + SwiftUI + Observation. Swift Package Manager + XcodeGen. Sprint tabanlı mimari, ADR'ler (`Docs/ADR/`), GitHub Actions CI.

Mimari detay: [`ARCHITECTURE.md`](ARCHITECTURE.md) · Geliştirme: [`DEVELOPMENT.md`](DEVELOPMENT.md)

**Değişmez güvenlik sınırları (asla bozma):**
- `Process()` yalnızca `Core/Services/Commands/ProcessCommandRunner.swift` içinde oluşturulur.
- Komut yürütme **allowlist** ile sınırlıdır; `sh -c` / `bash -c` / `zsh -c` ve `-c` argümanı YASAK.
- Wine keşfi PATH/`which` ile değil, sabit allowlist yollarıyla yapılır.
- `canLaunch` production'da `false` (deneysel launch hariç).
- Steam kimlik bilgisi/otomatik login YOK.

---

## 2. Roller (kim neyi en iyi yapar)

| Model | Araç | Rol | Görev türü |
|---|---|---|---|
| **Opus 4.8** | Claude Code | Mimar / Lead | Mimari karar & ADR, karmaşık refactor **tasarımı**, güvenlik sınırı tasarımı, **merge öncesi son review**, görev kırılımı |
| **Sonnet 4.6** | Claude Code | Senior Dev | İyi tanımlı toplu uygulama, test suite yazımı, orta-karmaşıklık refactor **uygulaması** |
| **Haiku 4.5** | Claude Code | Temizlikçi | Mekanik lint, format, rename, küçük doc/lokalizasyon |
| **GPT 5.5** | Codex | Otonom Uygulayıcı | Test-güdümlü otonom döngü (verify yeşile boyanana kadar) |
| **Gemini 3.1 Pro** | Antigravity | Analist / Görsel | Tüm-kod denetimi, tutarsızlık avı, multimodal görsel teşhis, ARCHITECTURE/README |
| **Gemini 3.5 Flash** | Antigravity | Hızlı Triyaj | Özet, changelog, HANDOFF güncelleme, görev bölme |

**Altın kural:** Riskli/geri-alınması zor işler (mimari değişiklik, çok-dosya refactor, güvenlik sınırı) → **Opus tasarlar → Sonnet/Codex uygular → Opus review eder.** Mekanik/düşük riskli işler doğrudan Haiku/Flash'a gider.

---

## 2A. Kullanıcı ↔ Koordinasyon (insan muhatap = Opus)

Kullanıcının **tek muhatabı Opus 4.8 (Claude Code)**'tur. Orkestra şefi modeli:

- **Yeni iş / öncelik değişikliği / "şunu da ekle" / tıkanma** → kullanıcı **Opus**'a söyler. Opus isteği göreve çevirir, en uygun modele atar, `TASKS.md` + `HANDOFF.md`'yi günceller, `NEXT:`'i ayarlar ve kullanıcıya "şimdi şu modeli aç" der.
- **Rutin ilerleme** → kullanıcı `HANDOFF.md` `NEXT:` satırını takip eder; o aracı açıp "sıradaki görevini al ve tamamla" der. Opus'a gerek yoktur.
- **Diğer modeller** (Sonnet, Haiku, Codex, Gemini Pro/Flash) yalnızca **kendilerine atanmış görevi** yapar; yeni iş/öncelik **belirleyemez**. İş kapsamı dışı bir durum görürlerse `HANDOFF.md`'ye not düşüp `NEXT:`'i **Opus**'a devreder.
- **Opus tüm ilerlemeyi izler** ve kullanıcıya durum raporu verir (kaynak: `HANDOFF.md` + `TASKS.md`).

```
KULLANICI ──(yeni istek)──► OPUS ──(görev+atama)──► HANDOFF.md ──► KULLANICI sıradaki aracı açar
                              ▲                                              │
                              └──────────(tıkanma: NEXT → Opus)─────────────┘
```

## 2B. Hangi model hangi dosya ile muhatap

**Ortak çekirdek — HER model okur:** `AGENTS.md` · `Docs/coordination/HANDOFF.md` · `Docs/coordination/TASKS.md`.

| Model (araç) | Ek olarak okur | Yazar / yönetir |
|---|---|---|
| **Opus 4.8** (Claude Code) | `CLAUDE.md` | **Yönetir:** `TASKS.md`, `HANDOFF.md`, `AGENTS.md` · **Yazar:** `REFACTOR-SPEC.md`, `HARDENING-SPEC.md` |
| **Sonnet 4.6** (Claude Code) | `CLAUDE.md`, `REFACTOR-SPEC.md` | Kendi görevi için `TASKS.md`/`HANDOFF.md` günceller |
| **Haiku 4.5** (Claude Code) | `CLAUDE.md` | Kendi görevi için `TASKS.md`/`HANDOFF.md` günceller |
| **GPT 5.5** (Codex) | `AGENTS.md`'yi native okur, `HARDENING-SPEC.md` | Kendi görevi için `TASKS.md`/`HANDOFF.md` günceller |
| **Gemini 3.1 Pro** (Antigravity) | `GEMINI.md` | **Yazar:** `Docs/coordination/AUDIT.md`, `ARCHITECTURE.md` |
| **Gemini 3.5 Flash** (Antigravity) | `GEMINI.md` | **Yazar:** changelog/README · `TASKS.md`/`HANDOFF.md` günceller |

> Not: `REFACTOR-SPEC.md`, `HARDENING-SPEC.md`, `AUDIT.md` ilgili turlarda (T-004, T-007, T-009) `Docs/coordination/` altında oluşturulur.

---

## 2C. Zeka (reasoning) Seviyesi Ölçeği

Her görevin gerektirdiği **zeka seviyesi** [`TASKS.md`](Docs/coordination/TASKS.md) Durum Özeti'ndedir. Model **işe başlamadan önce** bunu kullanıcıya bildirir (Bölüm 3, adım 0) ki kullanıcı doğru reasoning ayarını seçebilsin.

| Seviye | Ne zaman | Claude Code | Codex (GPT 5.5) | Antigravity (Gemini) |
|---|---|---|---|---|
| 🟢 **Düşük** | mekanik/deterministik (lint, format, changelog) | Haiku · normal (gerekirse `/fast`) | reasoning: **low** | Flash |
| 🟡 **Orta** | standart uygulama / test yazımı | Sonnet · normal | reasoning: **medium** | Flash veya Pro |
| 🟠 **Yüksek** | çok-dosya/ince refactor & test, geniş analiz | Opus/Sonnet + "**think hard**" | reasoning: **high** | Pro |
| 🔴 **Maksimum** | mimari tasarım, güvenlik sınırı, kritik review | Opus + "**ultrathink**" | reasoning: **high/xhigh** | Pro + üst düzey thinking |

> Model (Opus/Sonnet/Haiku, Pro/Flash) zaten role göre sabit; bu ölçek o modelin **düşünme/reasoning derinliğini** belirtir. İkisi birlikte "zeka düzeyi"ni verir.
>
> **Codex ailesi içi maliyet kademesi (iş-iş, proje-proje — sabit atama DEĞİL):** Codex'te **GPT 5.5 / GPT 5.4 / GPT 5.4-mini** mevcut. Varsayılan 5.5; ama bir işi **5.4 ya da 5.4-mini de yapabiliyorsa onu seç** → 5.5 limitini koru. Yön: mekanik/scriptsel runtime (log çek, screenshot loop, dosya işi) → **mini** · standart otonom uygulama/test → **5.4** · zor otonom/forensik/sertleştirme/build → **5.5**. Karar göreve göre; gerekmiyorsa ekleme.
>
> **Çok-fazlı görevlerde zeka FAZ-BAZLI olabilir:** model kendi **fazının** seviyesini okur, bütün-task'ı değil. (Örn. T-019: Faz A 🟡 mekanik → GPT 5.4 yeter; ama fix tasarımı 🔴 → Opus.) Görevde faz-bazlı seviye yazılıysa ona uy.

---

## 3. Görev Döngüsü Protokolü (HER araç başlangıçta uygular)

> **Tek komut yeterli:** Kullanıcı sana yalnızca "**T-XXX yap**" veya "**sıradaki görevini yap**" derse, aşağıdaki adımları **baştan sona kendin** uygula — ek talimat/onay bekleme. Görevin tüm detayı (`iş`, `verify`, `branch`, `bağımlı`) [`TASKS.md`](Docs/coordination/TASKS.md)'de; güncel durum tablosu da oradadır.

0. **Zeka seviyesini bildir — işe BAŞLAMADAN.** `TASKS.md` Durum Özeti'nden görevinin `Zeka` seviyesini oku. Kullanıcıya tek satır söyle: *"Bu görev **&lt;seviye&gt;** ister (Bölüm 2C). Reasoning ayarın uygun değilse ayarla; hazırsan 'devam' de."* Kod/dosya değiştirmeden **önce dur ve kullanıcının onayını bekle.** Onay gelince adım 1'e geç.
1. **Sıra sende mi?** [`HANDOFF.md`](Docs/coordination/HANDOFF.md) en üst `NEXT:` satırını oku. Senin model/araç adın yazıyorsa devam et; değilse kullanıcıyı bilgilendir ve dur.
2. **Görevini al.** [`TASKS.md`](Docs/coordination/TASKS.md)'de sana atanmış, `durum: todo`, bağımlılığı (`bağımlı:`) karşılanmış görev(ler)i bul.
3. **Branch aç.** Görevdeki `branch:` adını kullan (`git switch -c <branch>`). `main`'e doğrudan asla yazma.
4. **Yap + doğrula.** Görevdeki `verify:` komutunu çalıştır — **yeşil olmadan** görevi `done` işaretleme.
5. **Board'u güncelle.**
   - `TASKS.md`: görev `durum: done`.
   - `HANDOFF.md`: en üste 1 satır log ekle + `NEXT:`'i DAG'a göre **sıradaki sahibe** ayarla (Bölüm 5'teki tur sırası).
6. **Commit.** `tür(scope): özet` formatı + ilgili modelin `Co-Authored-By` satırı. Mümkünse CI yeşilini bekle.

> **Şerit (lane) disiplini:** Yalnız görevinin kapsamındaki dosya/işe dokun. Güvenlik-sınırı veya üretim-kodu refactor'u görevinde açıkça yoksa **yapma** — gerekiyorsa `HANDOFF.md`'ye not düşüp `NEXT:`'i Opus'a bırak. (Örn. *test yazma* görevinde `ProcessCommandRunner` refactor'u = kapsam aşımı.)
>
> Görev tıkanırsa: 1-2 denemeden sonra dur, `HANDOFF.md`'ye teşhis + en az 2 somut alternatif yaz, `NEXT:`'i **Opus**'a devret.

---

## 4. Komutlar & Doğrulama

```sh
# Lint (dalga sonu hedefi: 0 uyarı)
swiftlint lint --quiet

# Birim testler (tümü yeşil)
swift test --build-path /tmp/mpl_ci_build

# En güncel sprint regresyonu (saniyeler, ajan döngüsü için güvenli)
./scripts/verify-sprint-18.sh

# Uygulamayı derle/çalıştır (manuel duman testi; xcodebuild yerine bunu kullan)
./scripts/build.sh
```

**Yapma:** Varsayılan doğrulama olarak `xcodebuild test` veya tam `git diff` çalıştırma (tıkanır). Bunun yerine `verify-sprint-*.sh` + `swift test`.

**Kurallar özeti:** `project.yml` commit edilir, `.xcodeproj` edilmez · `@Observable` (ObservableObject değil) · görünür UI string'leri `String(localized:)` · her görev kendi branch'inde + CI yeşili.

---

## 5. Tur Sırası (Dalga 1 — Kod Sağlığı)

```
T-000 Opus  →  T-001 Haiku  →  T-002 Codex  →  T-003 Sonnet  →  T-004 Opus
   →  T-005 Sonnet  →  T-006 Haiku  →  T-007 Opus  →  T-008 Codex
   →  T-009 Gemini Pro  →  T-010 Gemini Flash  →  T-011 Opus (final review + merge)
```

Görev detayları, sahipleri ve verify komutları: [`Docs/coordination/TASKS.md`](Docs/coordination/TASKS.md).

---

## 6. Araç-özel notlar

- **Claude Code** ek talimat: [`CLAUDE.md`](CLAUDE.md)
- **Antigravity / Gemini** ek talimat: [`GEMINI.md`](GEMINI.md)
- **Codex** bu `AGENTS.md`'yi native okur; `.codex/environments/environment.toml` "Run" aksiyonu `./script/build_and_run.sh`.
