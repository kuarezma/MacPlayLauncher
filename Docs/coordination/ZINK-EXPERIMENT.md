# ZINK-EXPERIMENT — Yol Z: OpenGL→Vulkan→MoltenVK (Opus tasarımı)

> **Kapsam:** RUNTIME deneyi — `~/Cossacks3_Mac_Port` (bu Swift repo DEĞİL). **Uygulayan:** Codex (GPT 5.5, runtime bağlamı). **Tasarlayan/yorumlayan:** Opus.
> **Hedef:** Oyunun OpenGL'ini Apple'ın donmuş GL→Metal'i yerine **Mesa Zink (GL→Vulkan) → winevulkan/MoltenVK → Metal**'e yönlendir. Beklenen kazanç: (a) FPS (modern Vulkan→Metal), (b) cavalry bone-matrix bug (Mesa GLSL→SPIR-V dinamik indekslemeyi doğru derler).
> **Felsefe:** Bu deneysel ve başarısız olabilir. Kör deneme yok — fazlara böl, her fazda **karar kapısı** var. 1-2 başarısız denemede dur, raporla, Opus'a devret.

---

## Render zinciri (hedef)

```
Oyun OpenGL/GLSL → winex11.drv (GLX) → Mesa libGL (ZINK) → Vulkan → MoltenVK → Metal
   ↑ mevcut          ↑ KAPI: WineCX'te yok        ↑ kurulmalı         ↑ prefix'te VAR
```

Şu anki zincir: `Oyun GL → winemac.drv → Apple OpenGL.framework → Metal` (yavaş/buggy).

---

## ⚠️ CAN ALICI KAPI (Faz 0'da netleşmeli)

**WineCX 23.7 muhtemelen yalnız `winemac.drv` içeriyor** (CrossOver x11'i derlemez). Zink yolu `winex11.drv` ister. Yani deneyin başarısı şuna bağlı: **oyunu çalıştıran AMA `winex11.drv`'li bir Wine var mı/üretilebilir mi?**
- Newer Wine (CX24+/WineHQ11) zaten oyunu kırıyor (GL 1.1 / SEH) — onlar x11'li olsa bile işe yaramaz.
- Çalışan taban **wine-8.0.1 (CX23.7)**. Bunun x11'li bir varyantı gerek.

---

## Faz 0 — Fizibilite (ucuz, ÖNCE bunu yap)

Hiçbir şey kurmadan/derlemeden önce şunları tespit et ve raporla:

1. **winex11.drv var mı?** `find ~/Cossacks3_Mac_Port/winecx_engine -name "winex11.drv*"` — WineCX bundle'ında x11 sürücüsü var mı? (Muhtemelen yok.)
2. **MoltenVK ICD çalışıyor mu?** Homebrew `vulkan-tools` + `MoltenVK` kur, `vulkaninfo` MoltenVK GPU'yu listeliyor mu?
3. **Mesa + Zink mevcut mu?** `brew info mesa` — Apple Silicon'da Mesa Zink driver'ı var mı (`MESA_LOADER_DRIVER_OVERRIDE=zink`)?
4. **XQuartz** kurulu/kurulabilir mi (GLX için)?
5. **x11'li çalışan Wine adayı:** Gcenx (winehq-staging macOS, x11'li) build'i VAR mı / oyunu çalıştırabilir mi? VEYA wine-8.0.1'i `--with-x` ile derlemek mümkün mü?

**KARAR KAPISI:** 1+5 olumsuzsa (oyunu çalıştıran x11'li Wine yoksa) → Strategy-1 (XQuartz/Mesa) **bloklu**; Faz 1'e geçme, Opus'a "şu engelle tıkandı + alternatif" diye devret. 5 olumlu/üretilebilirse → Faz 1.

---

## Faz 1 — İzole Zink probu (oyun YOK)

Oyunu denemeden önce zincirin kendisini doğrula:
1. XQuartz + Mesa(Zink) + MoltenVK kur; `MESA_LOADER_DRIVER_OVERRIDE=zink MESA_VK_DEVICE=... glxinfo` → renderer **"zink Vulkan ... (MoltenVK)"** gösteriyor mu?
2. Basit bir GL uygulaması (glxgears veya bir wine'lı küçük GL exe) bu zincirden çiziyor mu?
- **KARAR KAPISI:** glxinfo Zink+MoltenVK göstermiyorsa → zincir kurulamıyor, raporla + dur.

---

## Faz 2 — Cossacks'ı Zink üzerinde çalıştır

Faz 0/1 yeşilse, x11-capable Wine ile (mevcut prefix kopyası üzerinde, orijinali BOZMADAN):
1. `oyna_ucretsiz.sh`'in bir **kopyasını** yap (`oyna_zink_deneme.sh`); winemac yerine winex11 sürücüsü + `MESA_LOADER_DRIVER_OVERRIDE=zink` + MoltenVK ICD env'i.
2. Oyunu aç, gözlemle: **(a)** açılıyor mu, **(b)** cavalry binicisi eyerde mi, **(c)** kalabalıkta FPS ne?
3. WineD3D yine builtin (oyun zaten OpenGL çiziyor; D3D katmanı önemsiz).
- **KARAR KAPISI:** açılmıyorsa/siyah ekransa → log topla, Opus'a getir.

---

## Güvenlik / geri-alınabilirlik (ZORUNLU)
- Orijinal `wine_cx` prefix'ine ve `oyna_ucretsiz.sh`'e **DOKUNMA** — kopya üzerinde çalış.
- Yeni kurulanlar (XQuartz, mesa, vulkan-tools) brew ile, geri alınabilir.
- Her faz sonunda **somut rapor**: ne çalıştı, ne çalışmadı, hangi log, sonraki karar.

## Çıktı
- `~/Cossacks3_Mac_Port/ZINK_DENEME_NOTU.md` (Codex yazar): faz faz sonuç.
- HANDOFF.md'ye özet + `NEXT:` → Opus (yorum/karar).

---

## Opus'un fizibilite değerlendirmesi (dürüst)
- **En olası tıkanma:** Faz 0 madde 5 — oyunu çalıştıran x11'li Wine bulmak. CX23.7 mac-only; Gcenx staging oyunu kırabilir; kaynaktan x11'li wine-8.0.1 derlemek mümkün ama emek ister.
- **Eğer x11+Zink zinciri kurulursa**, cavalry+FPS için gerçek şans var (Mesa derleyici + Vulkan yolu).
- **Başarısızlık senaryosu da değerli:** "x11'li çalışan Wine yok" netleşirse, kalan tek ücretsiz umut tükenmiş olur ve kararı bilinçli veririz (CX26 paralı vs mevcut hâli kabul).
