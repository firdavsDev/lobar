# /// script
# dependencies = ["pillow"]
# ///
"""Rebuild manifest.json from the strips on disk (frame count = width/256) with per-state fps/loop defaults."""
import json, os, sys
from PIL import Image
FPS = {"idle": (6, True), "walk": (8, True), "happy": (8, True), "dizzy": (4, True), "annoyed": (0.8, True),
       "sleep": (3, True), "fall": (8, True), "land": (4, False), "talking": (5, True), "drag": (3, True),
       "drink": (1, True), "eat": (1, True), "stretch": (1, True), "eyes": (0.7, True),
       "read": (1, True), "cook": (1, True), "lie": (1, True), "tea": (1, True), "dastarxon": (1, True)}
root = sys.argv[1]
m = {}
for outfit in sorted(os.listdir(root)):
    d = os.path.join(root, outfit)
    if not os.path.isdir(d): continue
    m[outfit] = {}
    for f in sorted(os.listdir(d)):
        state, ext = os.path.splitext(f)
        if ext != ".png" or state not in FPS: continue
        w = Image.open(os.path.join(d, f)).width
        fps, loop = FPS[state]
        m[outfit][state] = {"frames": max(1, w // 256), "fps": fps, "loop": loop}
json.dump(m, open(os.path.join(root, "manifest.json"), "w"), indent=2)
print("manifest:", {k: len(v) for k, v in m.items()})
