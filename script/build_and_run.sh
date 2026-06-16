#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
APP_NAME="MacPlayLauncher"
BUNDLE_ID="ugur.MacPlayLauncher"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$ROOT_DIR"

pkill -x "$APP_NAME" >/dev/null 2>&1 || true

xcodegen generate
xcodebuild \
  -scheme "$APP_NAME" \
  -destination 'platform=macOS' \
  test

BUILT_PRODUCTS_DIR="$(
  xcodebuild \
    -scheme "$APP_NAME" \
    -destination 'platform=macOS' \
    -showBuildSettings 2>/dev/null \
    | awk -F '= ' '/^[[:space:]]*BUILT_PRODUCTS_DIR = / { print $2; exit }'
)"
APP_BUNDLE="$BUILT_PRODUCTS_DIR/$APP_NAME.app"
APP_BINARY="$APP_BUNDLE/Contents/MacOS/$APP_NAME"

open_app() {
  /usr/bin/open -n "$APP_BUNDLE"
}

case "$MODE" in
  run)
    open_app
    ;;
  --debug|debug)
    lldb -- "$APP_BINARY"
    ;;
  --logs|logs)
    open_app
    /usr/bin/log stream --info --style compact --predicate "process == \"$APP_NAME\""
    ;;
  --telemetry|telemetry)
    open_app
    /usr/bin/log stream --info --style compact --predicate "subsystem == \"$BUNDLE_ID\""
    ;;
  --verify|verify)
    open_app
    sleep 1
    pgrep -x "$APP_NAME" >/dev/null
    ;;
  *)
    echo "usage: $0 [run|--debug|--logs|--telemetry|--verify]" >&2
    exit 2
    ;;
esac
