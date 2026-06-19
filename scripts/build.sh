#!/bin/bash
# MacPlayLauncher build script — watchdog korumalı
# Kullanım: ./scripts/build.sh

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SCHEME="MacPlayLauncher"
DERIVED_DATA="$HOME/Library/Developer/Xcode/DerivedData"
APP_OUT="$DERIVED_DATA/MacPlayLauncher-awvcrgyychqixgefthnxtatwxbzg/Build/Products/Debug/MacPlayLauncher.app"

STALL_LIMIT=120    # DerivedData büyümezse kaç saniye bekle
CHECK_INTERVAL=15  # kaç saniyede bir kontrol et

cd "$PROJECT_DIR"

# Önceki takılı build varsa temizle
pkill -9 -f xcodebuild 2>/dev/null || true
pkill -9 -f swift-build 2>/dev/null || true

# SPM build.db şişmişse temizle
BUILD_DB="$PROJECT_DIR/.build/build.db"
if [ -f "$BUILD_DB" ]; then
    DB_SIZE=$(du -k "$BUILD_DB" | cut -f1)
    if [ "$DB_SIZE" -gt 500000 ]; then
        echo "⚠️  build.db şişmiş (${DB_SIZE}KB), siliniyor..."
        rm -f "$BUILD_DB" "$BUILD_DB-wal" "$BUILD_DB-journal" "$PROJECT_DIR/.build/.build.db.lock"
    fi
fi

echo "🔨 xcodegen generate..."
xcodegen generate --quiet

echo "🔨 Build başlıyor (scheme: $SCHEME)..."

# DerivedData boyutunu izle — büyümezse watchdog devreye girer
PREV_SIZE=0
STALL_SECONDS=0

# xcodebuild'i arka planda başlat
xcodebuild \
    -scheme "$SCHEME" \
    -destination 'platform=macOS' \
    -configuration Debug \
    build \
    2>&1 | grep -E "error:|Build succeeded|BUILD FAILED|Compiling|Linking" &
BUILD_PID=$!

while kill -0 $BUILD_PID 2>/dev/null; do
    sleep $CHECK_INTERVAL
    CURR_SIZE=$(du -sk "$DERIVED_DATA/MacPlayLauncher"* 2>/dev/null | awk '{sum+=$1} END{print sum}')
    CURR_SIZE=${CURR_SIZE:-0}

    if [ "$CURR_SIZE" -le "$PREV_SIZE" ] && [ "$CURR_SIZE" -gt 0 ]; then
        STALL_SECONDS=$((STALL_SECONDS + CHECK_INTERVAL))
        echo "⏳ DerivedData büyümüyor (${STALL_SECONDS}s / ${STALL_LIMIT}s)..."
        if [ "$STALL_SECONDS" -ge "$STALL_LIMIT" ]; then
            echo "❌ Build takıldı! Öldürülüyor..."
            kill -9 $BUILD_PID 2>/dev/null || true
            pkill -9 -f xcodebuild 2>/dev/null || true
            echo "➡️  Xcode'u açıp ⌘B ile dene: open '$PROJECT_DIR/MacPlayLauncher.xcodeproj'"
            exit 1
        fi
    else
        STALL_SECONDS=0
        PREV_SIZE=$CURR_SIZE
    fi
done

wait $BUILD_PID
EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
    echo ""
    echo "✅ Build başarılı!"
    echo "📦 App: $APP_OUT"
    echo ""
    read -p "Uygulamayı aç? (y/N): " OPEN_APP
    if [[ "$OPEN_APP" =~ ^[Yy]$ ]]; then
        open "$APP_OUT"
    fi
else
    echo ""
    echo "❌ Build başarısız (exit: $EXIT_CODE)"
    echo "➡️  Xcode'da dene: open '$PROJECT_DIR/MacPlayLauncher.xcodeproj'"
    exit $EXIT_CODE
fi
