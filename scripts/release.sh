#!/usr/bin/env bash
# Signed, notarized release: Rayxon.app + DMG. Requires Xcode selected and a Developer ID certificate.
# Usage:
#   RAYXON_SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" \
#   NOTARY_PROFILE=rayxon-notary scripts/release.sh 0.2.0
# One-time: xcrun notarytool store-credentials rayxon-notary --apple-id you@example.com --team-id TEAMID --password <app-specific>
set -euo pipefail
cd "$(dirname "$0")/.."
VERSION="${1:?version required, e.g. 0.2.0}"
: "${RAYXON_SIGN_IDENTITY:?set RAYXON_SIGN_IDENTITY to your Developer ID Application identity}"
: "${NOTARY_PROFILE:?set NOTARY_PROFILE (notarytool keychain profile name)}"

# version stamp
plutil -replace CFBundleShortVersionString -string "$VERSION" Info.plist
plutil -replace CFBundleVersion -string "$(date +%Y%m%d%H%M)" Info.plist

scripts/bundle.sh release
APP=dist/Rayxon.app
codesign --force --deep --options runtime --timestamp --sign "$RAYXON_SIGN_IDENTITY" "$APP"
codesign --verify --deep --strict --verbose=2 "$APP"

DMG="dist/Rayxon-$VERSION.dmg"
rm -f "$DMG"
STAGE=$(mktemp -d); cp -R "$APP" "$STAGE/"; ln -s /Applications "$STAGE/Applications"
hdiutil create -volname "Rayxon" -srcfolder "$STAGE" -ov -format UDZO "$DMG" >/dev/null
rm -rf "$STAGE"
codesign --force --timestamp --sign "$RAYXON_SIGN_IDENTITY" "$DMG"

xcrun notarytool submit "$DMG" --keychain-profile "$NOTARY_PROFILE" --wait
xcrun stapler staple "$DMG"
xcrun stapler staple "$APP"
echo "release ready: $DMG"
echo "next: gh release create v$VERSION $DMG --title 'Rayxon $VERSION' --notes '...'"
