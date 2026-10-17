#!/usr/bin/env bash
# Bundle, relaunch, and (optionally) install. Usage: scripts/run.sh [--install] [debug|release]
set -euo pipefail
cd "$(dirname "$0")/.."
INSTALL=0; CONFIG=debug
for a in "$@"; do case "$a" in --install) INSTALL=1;; debug|release) CONFIG=$a;; esac; done
[ $INSTALL = 1 ] && CONFIG=release
scripts/bundle.sh "$CONFIG"
pkill -x Lobar 2>/dev/null || true
if [ $INSTALL = 1 ]; then
  rm -rf /Applications/Lobar.app && cp -R dist/Lobar.app /Applications/Lobar.app
  open /Applications/Lobar.app
else
  open dist/Lobar.app
fi
echo "logs: log stream --predicate 'subsystem == \"dev.davronbek.lobar\"' --level debug"
