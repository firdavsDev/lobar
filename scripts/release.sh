#!/usr/bin/env bash
# One-command release: tests → version stamp → Rayxon.app → DMG → commit + push → GitHub release.
# Usage:
#   scripts/release.sh 0.2.0                      # notes = commit subjects since the last tag
#   scripts/release.sh 0.2.0 "Yangi kiyim, ..."   # custom notes
# Ad-hoc signed by default (users right-click → Open once). Developer ID + notarization when set:
#   RAYXON_SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" NOTARY_PROFILE=rayxon-notary
# One-time: xcrun notarytool store-credentials rayxon-notary --apple-id you@example.com --team-id TEAMID --password <app-specific>
set -euo pipefail
cd "$(dirname "$0")/.."
VERSION="${1:?version required, e.g. 0.2.0}"
VERSION="${VERSION#v}"
TAG="v$VERSION"
NOTES="${2:-}"
IDENTITY="${RAYXON_SIGN_IDENTITY:-}"

# guards (Info.plist may be dirty from an aborted run)
[ "$(git branch --show-current)" = main ] || { echo "switch to main first"; exit 1; }
[ -z "$(git status --porcelain -- . ':(exclude)Info.plist')" ] || { echo "commit or stash changes first"; exit 1; }
git fetch -q --tags
if git rev-parse -q --verify "refs/tags/$TAG" >/dev/null || gh release view "$TAG" >/dev/null 2>&1; then
  echo "$TAG already exists"; exit 1
fi
if [ -z "$NOTES" ]; then
  LAST=$(git describe --tags --abbrev=0 2>/dev/null || true)
  NOTES=$(git log ${LAST:+$LAST..}HEAD --no-merges --pretty='- %s' | grep -v '^- release: ' || true)
fi

swift test 2>&1 | tail -2

# version stamp (UpdateChecker compares this with the latest GitHub release tag)
plutil -replace CFBundleShortVersionString -string "$VERSION" Info.plist
plutil -replace CFBundleVersion -string "$(date +%Y%m%d%H%M)" Info.plist

scripts/bundle.sh release
APP=dist/Rayxon.app
if [ -n "$IDENTITY" ]; then
  codesign --force --deep --options runtime --timestamp --sign "$IDENTITY" "$APP"
  codesign --verify --deep --strict --verbose=2 "$APP"
fi

DMG="dist/Rayxon-$VERSION.dmg"
rm -f "$DMG"
STAGE=$(mktemp -d); cp -R "$APP" "$STAGE/"; ln -s /Applications "$STAGE/Applications"
hdiutil create -volname "Rayxon" -srcfolder "$STAGE" -ov -format UDZO "$DMG" >/dev/null
rm -rf "$STAGE"
if [ -n "$IDENTITY" ]; then
  codesign --force --timestamp --sign "$IDENTITY" "$DMG"
  if [ -n "${NOTARY_PROFILE:-}" ]; then
    xcrun notarytool submit "$DMG" --keychain-profile "$NOTARY_PROFILE" --wait
    xcrun stapler staple "$DMG"
    xcrun stapler staple "$APP"
  fi
fi
echo "built $DMG ($([ -n "$IDENTITY" ] && echo "signed: $IDENTITY" || echo "ad-hoc"))"

printf '\nNotes:\n%s\n\n' "$NOTES"
read -r -p "Commit, push and publish $TAG? [y/N] " OK
if [ "$OK" != y ]; then
  echo "stopped. DMG kept; Info.plist stamped but not committed (git checkout Info.plist to undo)"; exit 0
fi
git commit -q -m "release: $VERSION" Info.plist
git push -q
gh release create "$TAG" "$DMG" --target "$(git rev-parse HEAD)" --title "Rayxon $VERSION" --notes "$NOTES"
