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
