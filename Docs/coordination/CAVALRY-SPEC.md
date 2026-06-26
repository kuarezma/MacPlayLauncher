# CAVALRY-SPEC — T-019 Forensik Saldırı (Opus tasarımı)

> **Kapsam:** RUNTIME (`~/Cossacks3_Mac_Port`), Swift repo DEĞİL. Hedef: atlı binicinin "üst gövde eyere oturmaması" bug'ını **enstrümante ederek** çöz ya da gerçek sebebi VERİYLE kanıtla.
> **Kısıt:** KOPYA prefix/shader. Orijinal `wine_cx` + `oyna_ucretsiz.sh` DOKUNULMAZ. Tüm çıktı `~/Cossacks3_Mac_Port/CAVALRY_FORENSIK_NOTU.md`.

## Neden bu çözülebilir (teşhis düzeltmesi)

`DEVAM_NOTU.md` "kök neden = wine-GL dinamik-indeks hatası" diyor. **Bu çürük:** aktif shader (`unit.sm.b42.id22.vert`) zaten 42 `if(index==k)` static-lookup ile **dinamik indekslemeyi tamamen kaldırmış** — rider yine oturmuyor. Sebep dinamik indeksleme olsaydı çözülürdü. → **Gerçek sebep bilinmiyor; kimse vertex-başı veriye bakmadı.** Plan: bak.

**Prime hipotez:** Aktif shader **tek-bone** (`aposn = weight*(bone*gl_Vertex)`, yalnız `gl_MultiTexCoord1.x` + `gl_MultiTexCoord2.x`). Ama bunlar **vec4** — `.y` 2. bone influence'ını taşıyor olabilir. Rider torso'su (eyer bağlantısı) 2-bone blend gerektirir → tek-bone = üst gövde kayık. Hiç denenmedi.

---

## Faz A — Enstrümantasyon (Codex uygular)

### A1. GLSL derleme logu
`oyna_ucretsiz.sh` KOPYASINDA `WINEDEBUG=-all` → `WINEDEBUG=+wgl` (gerekirse `+glsl`), stderr'i `~/Cossacks3_Mac_Port/CAVALRY_FORENSIK_NOTU_glsl.log`'a yönlendir. Sorular: shader sessizce compile-fail mi ediyor? Hangi vertex attribute kanalları bağlanıyor (MultiTexCoord1/2'nin kaç bileşeni)?

### A2. TEK kareyle 3 soruyu yanıtlayan debug-shader (kritik enstrüman)

Aktif `unit.sm.b42.id22.vert`'in KOPYASINI şu debug sürümüyle değiştir (sadece çıktı satırı + guard-flag eklendi; iskeleton/if-chain aynı):

```glsl
#define NBONES 42
uniform mat4 boneMatrices[NBONES];
void main(){
   float weight=gl_MultiTexCoord1.x;
   int index=int(gl_MultiTexCoord2.x+0.5);
   mat4 bone=boneMatrices[0];
   if(index==1)bone=boneMatrices[1];
   /* ... 41'e kadar mevcut if-chain aynen ... */
   if(index==41)bone=boneMatrices[41];
   float guardFired = (bone[3][3]<0.5) ? 1.0 : 0.0;   // guard'tan ÖNCE ölç
   if(bone[3][3]<0.5)bone=mat4(1.0);
   vec4 aposn=weight*(bone*gl_Vertex);
   // DEBUG: R=index/41 (hangi bone) · G=MultiTexCoord1.y (2. weight var mı) · B=guard fire
   gl_FrontColor = vec4( float(index)/41.0, gl_MultiTexCoord1.y, guardFired, 1.0 );
   gl_Position = gl_ModelViewProjectionMatrix*aposn;
}
```

Eşleşen debug fragment (`unit.smx3.id8.frag` + `unit.smx9.id8.frag` kopyası):
```glsl
void main(){ gl_FragColor = gl_Color; }
```

**Bu tek debug, RGB ile 3 hipotezi aynı anda test eder** (Gemini Pro rider'a bakıp okur):
- **Torso YEŞİL** (`MultiTexCoord1.y>0`) → **2. bone influence VAR ama yok sayılıyor → multi-bone hipotezi DOĞRU** → Faz C fix-1.
- **Torso MAVİ** (guard fire) → guard, torso bone'unu identity'ye çeviriyor → Faz C fix-2 (guard kaldır/gevşet).
- **Torso KIRMIZI tonu tuhaf/sabit** → index okuma/attribute eşleme sorunu → Faz C fix-3.
- Aynısını ana cavalry varyantları için yap: `b16` (Sipahi), `b20` (Spakh), `b42` (Tatar).

---

## Faz B — Hızlı görsel harness (Codex uygular)

Amaç: 15-20s manuel döngüyü **tek komuta** indir. Script `~/Cossacks3_Mac_Port/cavalry_lab/` içinde (kopya alan):

1. **Cavalry sahnesi (bir kez):** Tek cavalry birim merkezde olan bir skirmish save'i oluştur (`cavalry_test`) — Codex Cossacks'ın cmdline save-load / mission dosyası mekaniğini araştırır; mümkün değilse "save'i elle yükle, sonra batch dönsün" yarı-otomatik kabul.
2. **`render_variant.sh <shader_dir>`:** shader setini KOPYA prefix oyun klasörüne uygula → `oyna_ucretsiz.sh` KOPYASIYLA başlat → N sn bekle → `screencapture -o -l<windowID> out/<ad>.png` → süreci kapat.
3. **`batch.sh`:** debug + fix varyantları üzerinde döngü; her birini `out/`'a PNG yazar. Bu PNG'ler Gemini Pro'ya gider.

---

## Faz C — Veriye dayalı fix (Opus tasarlar, Faz A sonucuna göre)

**Fix-1 (multi-bone, prime):** if-chain'i 2-bone blend'e genişlet — iki influence'ı topla:
```glsl
float w0=gl_MultiTexCoord1.x, w1=gl_MultiTexCoord1.y;
int i0=int(gl_MultiTexCoord2.x+0.5), i1=int(gl_MultiTexCoord2.y+0.5);
mat4 b0=boneMatrices[0]; if(i0==1)b0=boneMatrices[1]; /* ...41... */
mat4 b1=boneMatrices[0]; if(i1==1)b1=boneMatrices[1]; /* ...41... */
vec4 aposn = w0*(b0*gl_Vertex) + w1*(b1*gl_Vertex);
vec4 anorm = w0*(b0*vec4(gl_Normal.xyz,0.0)) + w1*(b1*vec4(gl_Normal.xyz,0.0));
```
(2×42 if-chain = ~84 satır; GLSL 1.20 + `MAX_VERTEX_UNIFORM=4096` rahat kaldırır. `w1==0` ise eski davranışa eşdeğer → güvenli.)

**Fix-2 (guard):** guard torso'da fire ediyorsa → kaldır veya eşiği gevşet (`<-0.1`), VEYA geçersiz bone'u identity yerine **bone 0**'a düşür.

**Fix-3 (index/attribute):** debug index tuhafsa → `int(x+0.5)` vs `int(x)` vs `floor`, veya doğru MultiTexCoord kanalı.

Her fix Faz B harness'ıyla render edilir, Gemini Pro "oturdu mu" der, döngü.

---

## Çok-modelli döngü (T-019)
`Opus tasarla → Codex render/harness → Gemini Pro GÖZLE (screenshot) → Opus yorumla+fix → Codex uygula → Gemini doğrula.` Tükenene veya oturana kadar; her tur HANDOFF'ta.

## Başarı / bitiş
- **Başarı:** harness PNG'sinde rider eyerde; debug'da torso ne yeşil(çözüldü) ne mavi(guard) kalır.
- **Kanıtlı limit:** debug, sebebin shader-dışı (Wine-GL attribute aktarımı) olduğunu gösterirse → bone-texture interposer ileri seçenek, yoksa VERİYLE kapat.

---

## Faz A SONUCU (2026-06-26) + Faz A.2 tasarımı

**Faz A bulgusu (Opus, PNG'leri doğrudan okudu):** Debug-renk sahnesinde **hiç YEŞİL yok** (`MultiTexCoord1.y=0` → 2. bone influence YOK → **multi-bone hipotezi ÇÜRÜK**), **hiç MAVİ yok** (guard fire etmiyor → **guard hipotezi ÇÜRÜK**), biniciler **düz kırmızı** (tek, yüksek bone index), atlar **düz siyah** (index 0). → **Tek-bone rigid skinning + doğru index + sağlam matris (guard tetiklenmedi).** İki üst hipotez veriyle elendi (kör fix önlendi).

**Kalan şüpheli:** `boneMatrices[riderIndex]` İÇERİĞİ — doğru eyer transform'u mu, yoksa bind-pose/Wine-GL yüksek-index matris-yükleme sorunu mu?

### Faz A.2 — "bone vs no-bone" (en keskin ayraç; Codex harness ile, 🟡/🟠)
Rider bone shader'larının (`b16/b20/b42`) KOPYA debug'unda **iki varyant** render et + screenshot:
- **V1 (no-bone):** `gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;` — bone'u tamamen yok say, rider'ın HAM model vertex'i nereye düşüyor?
- **V2 (bone, mevcut):** `gl_Position = MVP * (bone*gl_Vertex);`

**Yorum:**
- no-bone rider'ı **doğru oturtuyorsa** → bone matrisi onu yanlış taşıyor = **matris/bind sorunu** (muhtemelen Wine-GL yüksek-index uniform matris yüklemesi). Workaround yolları: rider bone'unu **düşük index'e remap**, matris bileşenini düzelt, ya da bone-texture.
- no-bone **da yanlışsa** → sorun mesh/model yerleşiminde, bone değil.

### Faz A.2 yan test — matris içeriği
Rider bone'unun translation'ını renge bas: `gl_FrontColor=vec4(fract(abs(bone[3].xyz)*0.01),1.0);` → rider vs horse bone translation tutarlı mı, sıfır/çöp mü.

Çıktı: V1/V2 + matris PNG'leri → Opus/Gemini karşılaştırır → **matris mi, mesh mi** netleşir, Faz C fix ona göre.

---

## Faz A.2 SONUÇ (Gemini Pro, 2026-06-26) + Faz C tasarımı (Opus)

**KESİN BULGU:** no-bone (V1) ile bone (V2) çıktıları **BİREBİR AYNI** → `bone*vertex == vertex` → rider'ın `boneMatrices[yüksek_index]`'i **IDENTITY** geliyor. Index doğru (kırmızı), ama **Wine-GL yüksek-index uniform-matris verisini identity/boş aktarıyor** → KANITLI kök neden (guard fire etmemesiyle de tutarlı: identity'nin [3][3]=1 ≥ 0.5). Olmayan veriyi shader yaratamaz → düz shader fix yok.

**AMA bulgu bir WORKAROUND açıyor (Opus):** `boneMatrices[0]` (horse root) DOĞRU geliyor. Rider'ı, kırık yüksek-index bone yerine **çalışan horse bone[0] + sabit eyer-offset** ile yeniden konumla → rider eyere oturur (asıl görünür bug), tam binme-animasyonu olmasa da.

### Faz C — adımlar (runtime: Gemini, ya da Codex reset sonrası)
1. **Hızlı doğrula (düşük-index çalışıyor mu):** rider shader'ında `index`'i zorla `0` yap → rider non-identity matris alıp HAREKET ediyor mu? Hangi index'ten sonra identity başladığını bul (b16'nın max'ı 15 → b16 süvarileri çalışıyor olabilir; b42 patlıyor).
2. **Reconstruction:** rider'ı `aposn = boneMatrices[0] * SADDLE_OFFSET * gl_Vertex` ile çiz (kırık bone baypas). `SADDLE_OFFSET` (yukarı+geri translation) harness ile **empirik** ayarla (saniyede bir dene).
3. Görsel (Gemini/Opus): rider eyerde mi?
- **Oturuyorsa → T-019 İLK GERÇEK FIX 🎯.** Oturmuyorsa → kesin kanıtla kapat (Wine-GL yüksek-index uniform bug; workaround yetersiz).

**Dürüst odds ~%30:** hack/yaklaşık (sabit offset, animasyon yok), ama **denenmemiş + bulguya dayalı**. Kapatma da kazanç: kök neden artık KANITLI.
