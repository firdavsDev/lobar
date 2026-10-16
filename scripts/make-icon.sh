#!/usr/bin/env bash
# Build Resources/AppIcon.icns from a square 1024px PNG. Usage: scripts/make-icon.sh icon1024.png
set -euo pipefail
cd "$(dirname "$0")/.."
SRC="$1"; TMP=$(mktemp -d); SET="$TMP/AppIcon.iconset"; mkdir -p "$SET"
for s in 16 32 128 256 512; do
  sips -z $s $s "$SRC" --out "$SET/icon_${s}x${s}.png" >/dev/null
  d=$((s*2)); sips -z $d $d "$SRC" --out "$SET/icon_${s}x${s}@2x.png" >/dev/null
done
iconutil -c icns "$SET" -o Resources/AppIcon.icns
echo "wrote Resources/AppIcon.icns"
