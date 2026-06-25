# CLAUDE.md — Claude Code (Opus 4.8 / Sonnet 4.6 / Haiku 4.5)

> **Önce [`AGENTS.md`](AGENTS.md)'yi oku.** Bu dosya yalnızca Claude Code'a özel notları ekler.
> Sıra kontrolü: [`Docs/coordination/HANDOFF.md`](Docs/coordination/HANDOFF.md) · Görevler: [`Docs/coordination/TASKS.md`](Docs/coordination/TASKS.md)

## Başlarken
> Kullanıcı sadece "**T-XXX yap**" / "**sıradaki görevini yap**" diyebilir — görev detayı `TASKS.md`'de; protokolü (`AGENTS.md` Bölüm 3) baştan sona kendin uygula.

1. `HANDOFF.md` `NEXT:` satırına bak. Senin rolün (Opus / Sonnet / Haiku) yazıyorsa devam et.
2. `TASKS.md`'den sana atanmış `todo` görevi al, `branch:`'ini aç, `verify:`'ini yeşile boya, board'u güncelle, `NEXT:`'i devret (`AGENTS.md` Bölüm 3 & 5).

## Bu repodaki rol dağılımın
- **Opus 4.8** → tasarım/spec (T-004, T-007), final review + merge (T-011). Kod yazmadan önce `ARCHITECTURE.md` + ilgili ADR'yi oku.
- **Sonnet 4.6** → uygulama & test (T-003, T-005). Davranışı değiştirme; testleri yeşil tut.
- **Haiku 4.5** → mekanik lint & küçük yapısal düzeltme (T-001, T-006). Yalnız ilgili lint kategorilerine dokun, mantık değiştirme.

## Hatırlatmalar
- `Process()` sadece `ProcessCommandRunner.swift` içinde. Allowlist/güvenlik sınırını bozma.
- `@Observable` deseni; UI string'leri `String(localized:)`.
- Doğrulama: `swiftlint lint --quiet` + `swift test --build-path /tmp/mpl_ci_build` + `./scripts/verify-sprint-18.sh`. `xcodebuild test` çalıştırma.
- Commit sonu: `Co-Authored-By: Claude <model> <noreply@anthropic.com>`.
