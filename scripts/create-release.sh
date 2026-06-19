#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:-}"
if [ -z "$VERSION" ]; then
    echo "Usage: $0 <version> (e.g., v0.19.0)" >&2
    exit 1
fi
[[ ! "$VERSION" =~ ^v ]] && VERSION="v$VERSION"

APP_NAME="MacPlayLauncher"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_PATH="/tmp/mpl_release_build"
APP_BUNDLE="/tmp/$APP_NAME.app"
DMG_OUT="$ROOT_DIR/build_output/$APP_NAME.dmg"

cd "$ROOT_DIR"

# build_output içindeyse SPM'i mahveder, dışarı taşı
if [ -d "$ROOT_DIR/build_output" ]; then
    echo "== build_output taşınıyor (SPM bunu taramasın) =="
    mv "$ROOT_DIR/build_output" /tmp/mpl_build_output_bak
fi

cleanup() {
    [ -d /tmp/mpl_build_output_bak ] && mv /tmp/mpl_build_output_bak "$ROOT_DIR/build_output" 2>/dev/null || true
}
trap cleanup EXIT

echo "== 1. swift build (release) =="
swift build --build-path "$BUILD_PATH" -c release 2>&1 | tail -3

BINARY="$BUILD_PATH/arm64-apple-macosx/release/$APP_NAME"
[ -f "$BINARY" ] || { echo "Binary bulunamadı: $BINARY"; exit 1; }

echo "== 2. .app bundle oluşturuluyor =="
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources/tr.lproj"
mkdir -p "$APP_BUNDLE/Contents/Resources/en.lproj"

cp "$BINARY" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

# Resources kopyala
cp -r "$ROOT_DIR/Resources/"* "$APP_BUNDLE/Contents/Resources/" 2>/dev/null || true
[ -f "$ROOT_DIR/Resources/AppIcon.icns" ] && cp "$ROOT_DIR/Resources/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/"

# xcstrings → .strings dönüştür
XCSTRINGS="$ROOT_DIR/Resources/Localization/Localizable.xcstrings"
if [ -f "$XCSTRINGS" ]; then
    python3 - << PYEOF
import json
with open("$XCSTRINGS") as f:
    data = json.load(f)
strings = data.get("strings", {})
lines = []
for key, val in strings.items():
    locs = val.get("localizations", {})
    tr = locs.get("tr", {}).get("stringUnit", {}).get("value")
    en = locs.get("en", {}).get("stringUnit", {}).get("value")
    text = tr or en or key
    escaped = text.replace('"', '\\"').replace('\n', '\\n')
    lines.append(f'"{key}" = "{escaped}";')
output = "\n".join(lines)
for lang in ["tr", "en"]:
    with open(f"$APP_BUNDLE/Contents/Resources/{lang}.lproj/Localizable.strings", "w") as f:
        f.write(output)
print(f"Strings: {len(lines)} anahtar")
PYEOF
fi

# Info.plist
python3 - << PYEOF
import plistlib
plist = {
    "CFBundleExecutable": "$APP_NAME",
    "CFBundleIdentifier": "ugur.MacPlayLauncher",
    "CFBundleName": "$APP_NAME",
    "CFBundleDisplayName": "MacPlay Launcher",
    "CFBundleVersion": "${VERSION#v}",
    "CFBundleShortVersionString": "${VERSION#v}",
    "CFBundlePackageType": "APPL",
    "LSMinimumSystemVersion": "14.0",
    "NSPrincipalClass": "NSApplication",
    "NSHighResolutionCapable": True,
    "CFBundleIconFile": "AppIcon",
    "CFBundleIconName": "AppIcon",
}
with open("$APP_BUNDLE/Contents/Info.plist", "wb") as f:
    plistlib.dump(plist, f)
print("Info.plist yazıldı")
PYEOF

echo "== 3. Code signing =="
SIGNING_IDENTITY=$(security find-identity -v -p codesigning 2>/dev/null | grep "Apple Development:" | head -1 | awk -F '"' '{print $2}' || echo "")
[ -z "$SIGNING_IDENTITY" ] && SIGNING_IDENTITY="-"
echo "İmza: ${SIGNING_IDENTITY}"

codesign --force --options runtime \
    --sign "$SIGNING_IDENTITY" \
    --entitlements "$ROOT_DIR/MacPlay.entitlements" \
    "$APP_BUNDLE" 2>&1 || echo "Uyarı: imzalama başarısız, devam ediliyor"

echo "== 4. DMG oluşturuluyor =="
mkdir -p "$(dirname "$DMG_OUT")"
STAGE="/tmp/dmg_stage_$$"
rm -rf "$STAGE"
mkdir -p "$STAGE"
cp -R "$APP_BUNDLE" "$STAGE/"
ln -sf /Applications "$STAGE/Applications"
hdiutil create -volname "$APP_NAME" -srcfolder "$STAGE" -ov -format UDZO "$DMG_OUT" 2>&1 | tail -2
rm -rf "$STAGE"

[ "$SIGNING_IDENTITY" != "-" ] && codesign --force --sign "$SIGNING_IDENTITY" "$DMG_OUT" 2>/dev/null || true

echo "== 5. Git tag: $VERSION =="
git rev-parse "$VERSION" >/dev/null 2>&1 || { git tag -a "$VERSION" -m "Release $VERSION"; git push origin "$VERSION"; }

echo "== 6. GitHub Release =="
NOTES="### Yenilikler v${VERSION#v}

**Wine Steam Multiplayer**
- Gerçek Steam multiplayer desteği: arkadaş listesi, eşleşme, başarımlar
- OYNA butonu Wine Steam'i otomatik başlatır, hazır olunca oyunu açar

**Tam Ekran**
- Oyun başlarken ekran otomatik 1280×800'e geçer
- Oyun kapanınca eski çözünürlük otomatik geri yüklenir
- Herhangi bir Apple Silicon Mac display ile uyumlu (dinamik display ID)

**CrossOver Entegrasyonu**
- workingDirectory zorunluluğu kaldırıldı (CrossOver profiller için)
- Kullanıcı profil kartında uyarı gösterilmez

**Build sistemi**
- \`swift build\` ile 2 saniyede build (xcodebuild yerine)
- build_output SPM'den dışlandı — 15GB+ şişme sorunu çözüldü
- \`scripts/build.sh\` watchdog korumalı build betiği

**Uygulama İkonu**
- Tüm standart boyutlarda .icns dosyası eklendi"

if gh release view "$VERSION" >/dev/null 2>&1; then
    gh release upload "$VERSION" "$DMG_OUT" --clobber
else
    gh release create "$VERSION" "$DMG_OUT" \
        --title "Release $VERSION" \
        --notes "$NOTES"
fi

echo ""
echo "== Release $VERSION başarıyla oluşturuldu! =="
echo "   DMG: $DMG_OUT"
