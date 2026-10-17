#!/usr/bin/env bash
# Regenerate every sprite strip from the raw Gemini sheets in art/<outfit>/.
# Edit the table below when adding sheets. Usage: scripts/sprites/build_all.sh
set -euo pipefail
cd "$(dirname "$0")/../.."
OUT=Sources/Rayxon/Resources/Sprites
TMP=$(mktemp -d)
slice() { uv run --script scripts/sprites/slice.py "$@" 2>/dev/null | tail -1; }
split() { uv run --script scripts/sprites/split_strip.py "$@" >/dev/null; }

# ---- atlas ----
mkdir -p $OUT/atlas
slice art/atlas/idle.jpg    $OUT/atlas/idle.png  --frames 4
slice art/atlas/walk.jpg    $OUT/atlas/walk.png  --frames 6 --order 2,3,4,1
slice art/atlas/happy.jpg   $OUT/atlas/happy.png --frames 6
slice art/atlas/sleep.jpg   $OUT/atlas/sleep.png --frames 4 --strip-floaters
slice art/atlas/dizzy.jpg   $TMP/dizzy.png       --frames 4
split $TMP/dizzy.png $OUT/atlas dizzy:2 annoyed:2
slice art/atlas/actions.jpg $TMP/actions.png     --frames 6
split $TMP/actions.png $TMP/a fall:2 land:1 talking:2 drag_old:1
cp $TMP/a/fall.png $TMP/a/land.png $TMP/a/talking.png $OUT/atlas/
slice art/atlas/reminders.jpg $TMP/rem.png       --frames 8 --order 1,2,4,5,6,7,8
split $TMP/rem.png $OUT/atlas drag:2 drink:1 eat:1 stretch:1 eyes:2
if [ -f art/atlas/activities.jpg ]; then
  slice art/atlas/activities.jpg $TMP/act.png    --frames 6 --strip-floaters
  split $TMP/act.png $OUT/atlas read:1 cook:1 lie:1 tea:1 dastarxon:1 drag_t:1
fi
cp art/atlas/base.jpg $OUT/atlas/reference.jpg 2>/dev/null || true

# ---- adras ----
if [ -d art/adras ]; then
  mkdir -p $OUT/adras
  slice art/adras/adras_idle.jpg $OUT/adras/idle.png --frames 4
  slice art/adras/adras_walk.jpg $OUT/adras/walk.png --frames 6 --order 2,3,4,1
  if [ -f art/adras/adras_happy.jpg ]; then
    slice art/adras/adras_happy.jpg $TMP/ah.png --frames 7 --strip-floaters
    split $TMP/ah.png $OUT/adras happy:4 sleep:1 dizzy:1 annoyed:1
  fi
  cp art/adras/adras_idle.jpg $OUT/adras/reference.jpg
fi
# ---- generic outfits (bahor, tungi): idle 4, walk 6, happy sheet 7 ----
for o in bahor tungi; do
  [ -d art/$o ] || continue
  mkdir -p $OUT/$o
  [ -f art/$o/${o}_idle.jpg ] && slice art/$o/${o}_idle.jpg $OUT/$o/idle.png --frames 4 && cp art/$o/${o}_idle.jpg $OUT/$o/reference.jpg
  [ -f art/$o/${o}_walk.jpg ] && slice art/$o/${o}_walk.jpg $OUT/$o/walk.png --frames 6 --order 2,3,4,1
  if [ -f art/$o/${o}_happy.jpg ]; then
    n=$(slice art/$o/${o}_happy.jpg $TMP/${o}h.png --strip-floaters | grep -oE '[0-9]+ frames' | cut -d' ' -f1)
    if [ "$n" != "6" ] && [ "$n" != "7" ] && [ "$n" != "8" ]; then
      # sprites touching: fall back to valley split with the count noted in art/<o>/happy_frames (default 6)
      n=$(cat art/$o/happy_frames 2>/dev/null || echo 6)
      slice art/$o/${o}_happy.jpg $TMP/${o}h.png --strip-floaters --frames $n >/dev/null
    fi
    case "$n" in
      8) split $TMP/${o}h.png $OUT/$o happy:4 sleep:2 dizzy:1 annoyed:1 ;;
      7) split $TMP/${o}h.png $OUT/$o happy:4 sleep:1 dizzy:1 annoyed:1 ;;
      6) split $TMP/${o}h.png $OUT/$o happy:4 sleep:1 dizzy:1; cp $OUT/$o/dizzy.png $OUT/$o/annoyed.png ;;
      *) echo "warning: $o happy sheet has $n frames, skipped" ;;
    esac
  fi
done
rm -rf $TMP
uv run --script scripts/sprites/manifest.py $OUT
