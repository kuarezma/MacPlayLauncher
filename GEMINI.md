# GEMINI.md — Antigravity (Gemini 3.1 Pro / Gemini 3.5 Flash)

> **Önce [`AGENTS.md`](AGENTS.md)'yi oku.** Bu dosya yalnızca Antigravity/Gemini'ye özel notları ekler.
> Sıra kontrolü: [`Docs/coordination/HANDOFF.md`](Docs/coordination/HANDOFF.md) · Görevler: [`Docs/coordination/TASKS.md`](Docs/coordination/TASKS.md)

## Başlarken
> Kullanıcı sadece "**T-XXX yap**" / "**sıradaki görevini yap**" diyebilir — görev detayı `TASKS.md`'de; protokolü (`AGENTS.md` Bölüm 3) baştan sona kendin uygula.

1. `HANDOFF.md` `NEXT:` satırına bak. Senin rolün (Gemini Pro / Gemini Flash) yazıyorsa devam et.
2. `TASKS.md`'den görevini al, `branch:`'ini aç, `verify:`'ini çalıştır, board'u güncelle, `NEXT:`'i devret (`AGENTS.md` Bölüm 3 & 5).

## Bu repodaki rol dağılımın
- **Gemini 3.1 Pro** → Analist/Görsel (T-009): tüm-kod tabanı tutarlılık denetimi (kalan `ProcessCommandRunner` baypasları, ölü kod), `ARCHITECTURE.md`'ye yeni sprint girişi, ve **multimodal** görsel teşhis — kullanıcı minimap/shader/UI ekran görüntüsü verirse görsel sorunu analiz et (Cossacks port'taki minimap şeffaflığı, `CossacksBattlePreviewView`).
- **Gemini 3.5 Flash** → Hızlı Triyaj (T-010): changelog/README rötuş, `TASKS.md` özetleri, `HANDOFF.md` temizliği, **Dalga 2 (hatalar)** için triyaj backlog'u taslağı.

## Hatırlatmalar
- Güvenlik sınırlarını **bozma** (yalnız analiz/öneri yap, riskli uygulama Opus tasarımıyla gider): `Process()` sadece `ProcessCommandRunner.swift`'te; allowlist; `sh -c` yok; `canLaunch=false`.
- Kod değişikliği yaparsan: kendi branch'in + `swift test` + `./scripts/verify-sprint-18.sh` yeşil.
- Doküman çıktıları Türkçe; kod/komut İngilizce.
