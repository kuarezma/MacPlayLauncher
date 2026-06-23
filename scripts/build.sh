#!/usr/bin/env bash
# MacPlayLauncher build script
# Kullanim: ./scripts/build.sh [versiyon]
# Ornek:    ./scripts/build.sh v0.23.0
#           ./scripts/build.sh          (git tag'dan okur)

set -euo pipefail

APP_NAME="MacPlayLauncher"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_PATH="/tmp/mpl_build"
APP_OUT="/tmp/$APP_NAME.app"

# Sürüm: parametre > git tag > fallback
_RAW_VERSION="${1:-}"
if [ -z "$_RAW_VERSION" ]; then
    _RAW_VERSION=$(git -C "$ROOT_DIR" describe --tags --abbrev=0 2>/dev/null || echo "0.0.0-dev")
fi
BUNDLE_VERSION="${_RAW_VERSION#v}"  # "v0.23.0" → "0.23.0"

cd "$ROOT_DIR"

echo "== 1. Swift build basliyor =="
swift build --build-path "$BUILD_PATH" -c debug

BINARY="$BUILD_PATH/arm64-apple-macosx/debug/$APP_NAME"
if [ ! -f "$BINARY" ]; then
    echo "Binary bulunamadi: $BINARY" >&2
    exit 1
fi

echo "== 2. App bundle olusturuluyor =="
rm -rf "$APP_OUT"
mkdir -p "$APP_OUT/Contents/MacOS"
mkdir -p "$APP_OUT/Contents/Resources/tr.lproj"
mkdir -p "$APP_OUT/Contents/Resources/en.lproj"

cp "$BINARY" "$APP_OUT/Contents/MacOS/$APP_NAME"

if [ -d "$ROOT_DIR/Resources" ]; then
    cp -R "$ROOT_DIR/Resources/"* "$APP_OUT/Contents/Resources/" 2>/dev/null || true
fi

XCSTRINGS="$ROOT_DIR/Resources/Localization/Localizable.xcstrings"
if [ -f "$XCSTRINGS" ]; then
    APP_OUT="$APP_OUT" XCSTRINGS="$XCSTRINGS" python3 - << 'PYEOF'
import json
import os
from pathlib import Path

xcstrings_path = Path(os.environ["XCSTRINGS"])
resources_path = Path(os.environ["APP_OUT"]) / "Contents" / "Resources"
data = json.loads(xcstrings_path.read_text())
strings = data.get("strings", {})

for language in ["tr", "en"]:
    lines = []
    for key, value in strings.items():
        localizations = value.get("localizations", {})
        text = (
            localizations.get(language, {}).get("stringUnit", {}).get("value")
            or localizations.get("en", {}).get("stringUnit", {}).get("value")
            or localizations.get("tr", {}).get("stringUnit", {}).get("value")
            or key
        )
        escaped = text.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n")
        lines.append(f'"{key}" = "{escaped}";')

    output_path = resources_path / f"{language}.lproj" / "Localizable.strings"
    output_path.write_text("\n".join(lines), encoding="utf-8")

print(f"Strings: {len(strings)} anahtar")
PYEOF
fi

python3 - << PYEOF
import plistlib

plist = {
    "CFBundleExecutable": "$APP_NAME",
    "CFBundleIdentifier": "ugur.MacPlayLauncher",
    "CFBundleName": "$APP_NAME",
    "CFBundleDisplayName": "MacPlay Launcher",
    "CFBundleVersion": "$BUNDLE_VERSION",
    "CFBundleShortVersionString": "$BUNDLE_VERSION",
    "CFBundlePackageType": "APPL",
    "LSMinimumSystemVersion": "14.0",
    "NSPrincipalClass": "NSApplication",
    "NSHighResolutionCapable": True,
    "CFBundleIconFile": "AppIcon",
    "CFBundleIconName": "AppIcon",
}

with open("$APP_OUT/Contents/Info.plist", "wb") as file:
    plistlib.dump(plist, file)
PYEOF

if [ -f "$ROOT_DIR/MacPlay.entitlements" ]; then
    echo "== 3. App imzalaniyor =="
    codesign --force --sign - --entitlements "$ROOT_DIR/MacPlay.entitlements" "$APP_OUT" >/dev/null
fi

echo ""
echo "Build basarili:"
echo "$APP_OUT"
echo ""
if [ -t 0 ]; then
    read -r -p "Uygulamayi ac? (y/N): " OPEN_APP
    if [[ "$OPEN_APP" =~ ^[Yy]$ ]]; then
        open "$APP_OUT"
    fi
fi
