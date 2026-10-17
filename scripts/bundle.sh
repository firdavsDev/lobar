#!/usr/bin/env bash
# Build Lobar.app with SwiftPM (no Xcode). Usage: scripts/bundle.sh [debug|release]
set -euo pipefail
cd "$(dirname "$0")/.."
CONFIG="${1:-release}"
swift build -c "$CONFIG" 2>&1 | grep -vE '^\[' | tail -3
BIN_DIR="$(swift build -c "$CONFIG" --show-bin-path)"
APP=dist/Lobar.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN_DIR/Lobar" "$APP/Contents/MacOS/Lobar"
cp Info.plist "$APP/Contents/Info.plist"
plutil -lint "$APP/Contents/Info.plist" >/dev/null
# SwiftPM resource bundle: Bundle.module looks next to the executable and in Contents/Resources
BUNDLE="$BIN_DIR/Lobar_Lobar.bundle"
[ -d "$BUNDLE" ] && cp -R "$BUNDLE" "$APP/Contents/Resources/"
[ -f Resources/AppIcon.icns ] && cp Resources/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns" || true
IDENTITY="${LOBAR_SIGN_IDENTITY:-}"
if [ -n "$IDENTITY" ] && security find-identity -v -p codesigning | grep -q "$IDENTITY"; then
  codesign --force --deep --sign "$IDENTITY" "$APP"
else
  codesign --force --deep --sign - "$APP"
fi
xattr -cr "$APP" 2>/dev/null || true
echo "built $APP"
