#!/usr/bin/env bash
# MacPlayLauncher release script
# Kullanim: ./scripts/create-release.sh <versiyon> [--dry-run]
# Ornek:    ./scripts/create-release.sh v0.23.0
#           ./scripts/create-release.sh v0.23.0 --dry-run

set -euo pipefail

VERSION="${1:-}"
if [ -z "$VERSION" ]; then
    echo "Kullanim: $0 <versiyon> [--dry-run]" >&2
    echo "Ornek:    $0 v0.23.0" >&2
    exit 1
fi
[[ ! "$VERSION" =~ ^v ]] && VERSION="v$VERSION"

# --dry-run flag
DRY_RUN=false
for arg in "$@"; do
    [ "$arg" = "--dry-run" ] && DRY_RUN=true
done

run() {
    if [ "$DRY_RUN" = "true" ]; then
        echo "[DRY-RUN] $*"
    else
        "$@"
    fi
}

APP_NAME="MacPlayLauncher"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_PATH="/tmp/mpl_release_build"
APP_BUNDLE="/tmp/$APP_NAME.app"
DMG_OUT="$ROOT_DIR/build_output/$APP_NAME.dmg"
SHA256_OUT="$ROOT_DIR/build_output/SHA256SUMS.txt"

cd "$ROOT_DIR"

# build_output SPM'i mahveder, dışarı taşı
if [ -d "$ROOT_DIR/build_output" ]; then
    echo "== build_output taşınıyor (SPM bunu taramasın) =="
    mv "$ROOT_DIR/build_output" /tmp/mpl_build_output_bak
fi

cleanup() {
    if [ -d /tmp/mpl_build_output_bak ]; then
        # build_output dry-run sırasında mkdir ile yeniden oluşturulmuş olabilir; önce sil
        rm -rf "$ROOT_DIR/build_output" 2>/dev/null || true
        mv /tmp/mpl_build_output_bak "$ROOT_DIR/build_output" 2>/dev/null || true
    fi
}
trap cleanup EXIT

echo "== 1. Swift build (release) =="
if [ "$DRY_RUN" = "true" ]; then
    echo "[DRY-RUN] swift build --build-path $BUILD_PATH -c release"
else
    swift build --build-path "$BUILD_PATH" -c release 2>&1 | tail -3
fi

BINARY="$BUILD_PATH/arm64-apple-macosx/release/$APP_NAME"
if [ "$DRY_RUN" = "false" ] && [ ! -f "$BINARY" ]; then
    echo "Binary bulunamadı: $BINARY" >&2
    exit 1
fi

echo "== 2. .app bundle oluşturuluyor =="
if [ "$DRY_RUN" = "false" ]; then
    rm -rf "$APP_BUNDLE"
    mkdir -p "$APP_BUNDLE/Contents/MacOS"
    mkdir -p "$APP_BUNDLE/Contents/Resources/tr.lproj"
    mkdir -p "$APP_BUNDLE/Contents/Resources/en.lproj"

    cp "$BINARY" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
    cp -r "$ROOT_DIR/Resources/"* "$APP_BUNDLE/Contents/Resources/" 2>/dev/null || true
    [ -f "$ROOT_DIR/Resources/AppIcon.icns" ] && cp "$ROOT_DIR/Resources/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/"

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
fi

echo "== 3. Code signing =="
# Developer ID Application varsa onu kullan; yoksa yerel test seçeneği sun
DEVELOPER_ID=$(security find-identity -v -p codesigning 2>/dev/null \
    | grep "Developer ID Application:" | head -1 | awk -F '"' '{print $2}' || true)
LOCAL_TEST_ONLY=false

if [ -z "$DEVELOPER_ID" ]; then
    echo ""
    echo "UYARI: 'Developer ID Application' sertifikası bulunamadı."
    echo "       Notarized DMG için bu sertifika zorunludur."
    echo "       Apple Geliştirici hesabında 'Certificates, IDs & Profiles' bölümünden edinebilirsiniz."
    echo ""
    if [ "$DRY_RUN" = "true" ]; then
        echo "[DRY-RUN] Developer ID yoksa burada duracak (--dry-run atladı)"
        LOCAL_TEST_ONLY=true
    else
        printf "Yerel test için Apple Development sertifikasıyla devam etmek ister misiniz? (y/N): "
        read -r FALLBACK
        if [[ "$FALLBACK" =~ ^[Yy]$ ]]; then
            DEVELOPER_ID=$(security find-identity -v -p codesigning 2>/dev/null \
                | grep "Apple Development:" | head -1 | awk -F '"' '{print $2}' || true)
            LOCAL_TEST_ONLY=true
            echo "Devam ediliyor: yerel test paketi (notarize edilmeyecek)."
        else
            echo "Release iptal edildi." >&2
            exit 1
        fi
    fi
fi

echo "İmza: ${DEVELOPER_ID:-Ad-hoc}"
run codesign --force --options runtime --deep \
    --sign "${DEVELOPER_ID:--}" \
    --entitlements "$ROOT_DIR/MacPlay.entitlements" \
    "$APP_BUNDLE"

echo "== 4. DMG oluşturuluyor =="
[ "$DRY_RUN" = "false" ] && mkdir -p "$(dirname "$DMG_OUT")"
if [ "$DRY_RUN" = "false" ]; then
    STAGE="/tmp/dmg_stage_$$"
    rm -rf "$STAGE"
    mkdir -p "$STAGE"
    cp -R "$APP_BUNDLE" "$STAGE/"
    ln -sf /Applications "$STAGE/Applications"
    hdiutil create -volname "$APP_NAME" -srcfolder "$STAGE" -ov -format UDZO "$DMG_OUT" 2>&1 | tail -2
    rm -rf "$STAGE"
    [ -n "$DEVELOPER_ID" ] && codesign --force --sign "$DEVELOPER_ID" "$DMG_OUT" 2>/dev/null || true
else
    echo "[DRY-RUN] hdiutil create → $DMG_OUT"
fi

echo "== 5. Notarization =="
if [ "$LOCAL_TEST_ONLY" = "true" ]; then
    echo "Atlıyor: yerel test paketi veya dry-run, notarize edilmeyecek."
elif [ "$DRY_RUN" = "true" ]; then
    echo "[DRY-RUN] xcrun notarytool submit $DMG_OUT --keychain-profile MacPlayNotary --wait"
    echo "[DRY-RUN] xcrun stapler staple $DMG_OUT"
else
    NOTARY_PROFILE="${NOTARY_KEYCHAIN_PROFILE:-MacPlayNotary}"
    echo "Notary profile: $NOTARY_PROFILE"
    echo "Gönderiliyor… (bu birkaç dakika sürebilir)"
    SUBMIT_OUTPUT=$(xcrun notarytool submit "$DMG_OUT" \
        --keychain-profile "$NOTARY_PROFILE" \
        --wait 2>&1)
    echo "$SUBMIT_OUTPUT"
    if echo "$SUBMIT_OUTPUT" | grep -q "status: Accepted"; then
        run xcrun stapler staple "$DMG_OUT"
        echo "Notarization + staple başarılı."
    else
        echo "HATA: Notarization başarısız. Yukarıdaki çıktıya bakın." >&2
        exit 1
    fi
fi

echo "== 6. SHA256 checksum =="
if [ "$DRY_RUN" = "false" ]; then
    shasum -a 256 "$DMG_OUT" | sed "s|.*/||" > "$SHA256_OUT"
    echo "Checksum: $(cat "$SHA256_OUT")"
else
    echo "[DRY-RUN] shasum -a 256 $DMG_OUT → $SHA256_OUT"
fi

echo "== 7. Git tag: $VERSION =="
run git -C "$ROOT_DIR" rev-parse "$VERSION" >/dev/null 2>&1 \
    || run git -C "$ROOT_DIR" tag -a "$VERSION" -m "Release $VERSION"
run git -C "$ROOT_DIR" push origin "$VERSION"

echo "== 8. Dinamik release notları =="
LAST_TAG=$(git -C "$ROOT_DIR" describe --tags --abbrev=0 HEAD^ 2>/dev/null || echo "")
if [ -n "$LAST_TAG" ]; then
    COMMIT_LOG=$(git -C "$ROOT_DIR" log "$LAST_TAG..HEAD" \
        --pretty=format:"- %s" 2>/dev/null \
        | grep -E "^- (feat|fix|perf|refactor)(\(.+\))?:" || true)
    [ -z "$COMMIT_LOG" ] && COMMIT_LOG=$(git -C "$ROOT_DIR" log "$LAST_TAG..HEAD" --pretty=format:"- %s" | head -10 || true)
else
    COMMIT_LOG="- İlk release"
fi

SHA_LINE=""
[ -f "$SHA256_OUT" ] && SHA_LINE="$(cat "$SHA256_OUT")"
[ "$LOCAL_TEST_ONLY" = "true" ] && SHA_LINE="(notarize edilmemiş yerel test paketi)"

NOTES="## ${VERSION} — Kolay Kurulum ve Notarized DMG

### Değişiklikler
${COMMIT_LOG:-— değişiklik logu bulunamadı}

### Kurulum
1. \`MacPlayLauncher.dmg\` dosyasını indir
2. Applications klasörüne sürükle
3. Aç → **Kurulumu Başlat** butonuna bas

### SHA256
\`${SHA_LINE}\`"

echo "== 9. GitHub Release =="
if [ "$DRY_RUN" = "true" ]; then
    echo "[DRY-RUN] gh release create $VERSION $DMG_OUT $SHA256_OUT"
    echo "--- Release notları ---"
    echo "$NOTES"
    echo "-----------------------"
else
    if gh release view "$VERSION" >/dev/null 2>&1; then
        gh release upload "$VERSION" "$DMG_OUT" "$SHA256_OUT" --clobber
    else
        gh release create "$VERSION" "$DMG_OUT" "$SHA256_OUT" \
            --title "Release $VERSION" \
            --notes "$NOTES"
    fi
fi

echo ""
if [ "$DRY_RUN" = "true" ]; then
    echo "== [DRY-RUN] Kuru koşu tamamlandı — hiçbir şey değiştirilmedi. =="
else
    echo "== Release $VERSION başarıyla oluşturuldu! =="
    echo "   DMG: $DMG_OUT"
    echo "   SHA256: $SHA256_OUT"
fi
