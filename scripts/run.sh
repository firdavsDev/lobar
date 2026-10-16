#!/usr/bin/env bash
# Bundle, relaunch, and (optionally) install. Usage: scripts/run.sh [--install] [debug|release]
set -euo pipefail
cd "$(dirname "$0")/.."
INSTALL=0; CONFIG=debug
for a in "$@"; do case "$a" in --install) INSTALL=1;; debug|release) CONFIG=$a;; esac; done
[ $INSTALL = 1 ] && CONFIG=release
scripts/bundle.sh "$CONFIG"
pkill -x Rayxon 2>/dev/null || true
if [ $INSTALL = 1 ]; then
  rm -rf /Applications/Rayxon.app && cp -R dist/Rayxon.app /Applications/Rayxon.app
  open /Applications/Rayxon.app
else
  open dist/Rayxon.app
fi
echo "logs: log stream --predicate 'subsystem == \"dev.davronbek.rayxon\"' --level debug"
