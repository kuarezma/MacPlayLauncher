#!/usr/bin/env bash
set -euo pipefail

# Release automation script for MacPlayLauncher

VERSION="${1:-}"
if [ -z "$VERSION" ]; then
    echo "Usage: $0 <version> (e.g., v0.18.0)" >&2
    exit 1
fi

# Ensure version prefix is 'v'
if [[ ! "$VERSION" =~ ^v ]]; then
    VERSION="v$VERSION"
fi

APP_NAME="MacPlayLauncher"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "== 1. Preparing workspace =="
cd "$ROOT_DIR"
rm -rf build_output/dmg_stage
rm -f build_output/MacPlayLauncher.dmg

echo "== 2. Generating Xcode project =="
xcodegen generate

echo "== 3. Building release configuration =="
xcodebuild \
  -scheme "$APP_NAME" \
  -configuration Release \
  -destination 'platform=macOS' \
  -derivedDataPath build_output \
  clean build

APP_BUNDLE="build_output/Build/Products/Release/$APP_NAME.app"

if [ ! -d "$APP_BUNDLE" ]; then
    echo "Error: App bundle not found at $APP_BUNDLE" >&2
    exit 1
fi

echo "== 4. Locating code signing identity =="
# Find the first valid Apple Development certificate
SIGNING_IDENTITY=$(security find-identity -v -p codesigning | grep "Apple Development:" | head -n 1 | awk -F '"' '{print $2}')

if [ -z "$SIGNING_IDENTITY" ]; then
    echo "Warning: No Apple Development certificate found. Falling back to ad-hoc signing."
    SIGNING_IDENTITY="-"
else
    echo "Found signing identity: $SIGNING_IDENTITY"
fi

echo "== 5. Code signing the app bundle =="
codesign --force --options runtime --sign "$SIGNING_IDENTITY" --entitlements MacPlay.entitlements "$APP_BUNDLE"
codesign -vvv --deep --strict "$APP_BUNDLE"

echo "== 6. Creating DMG package =="
mkdir -p build_output/dmg_stage
cp -R "$APP_BUNDLE" build_output/dmg_stage/
ln -sf /Applications build_output/dmg_stage/Applications

hdiutil create -volname "$APP_NAME" -srcfolder build_output/dmg_stage -ov -format UDZO build_output/MacPlayLauncher.dmg

echo "== 7. Code signing the DMG =="
codesign --force --sign "$SIGNING_IDENTITY" build_output/MacPlayLauncher.dmg
codesign -vvv build_output/MacPlayLauncher.dmg

echo "== 8. Git tagging =="
if git rev-parse "$VERSION" >/dev/null 2>&1; then
    echo "Tag $VERSION already exists locally."
else
    git tag -a "$VERSION" -m "Release $VERSION"
    git push origin "$VERSION"
fi

echo "== 9. Creating GitHub Release =="
# Compile release notes from git history or changelog
RELEASE_NOTES="### 🚀 Features
- Sprint 18: Actionable readiness guidance across Library, Diagnostics, and Settings.
- CrossOver Integration for Cossacks 3.
- Steam-free game launch with Goldberg emulator support.

### 🐛 Bug Fixes
- Excluded build directories from swiftlint.
- Resolved MainActor isolation issues in unit tests.
- Fixed SteamInstallService to avoid Process() usage inside non-runners."

if gh release view "$VERSION" >/dev/null 2>&1; then
    echo "GitHub Release $VERSION already exists. Uploading new asset..."
    gh release upload "$VERSION" build_output/MacPlayLauncher.dmg --clobber
else
    gh release create "$VERSION" build_output/MacPlayLauncher.dmg \
      --title "Release $VERSION" \
      --notes "$RELEASE_NOTES"
fi

echo "== Release $VERSION created successfully! =="
