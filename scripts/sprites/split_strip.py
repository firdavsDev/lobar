# /// script
# dependencies = ["pillow"]
# ///
"""Split a 256px-cell strip into named sub-strips.
usage: uv run --script split_strip.py IN.png OUTDIR name:count [name:count ...]"""
import sys, os
from PIL import Image
CELL = 256
img = Image.open(sys.argv[1]); outdir = sys.argv[2]; os.makedirs(outdir, exist_ok=True)
i = 0
for spec in sys.argv[3:]:
    name, n = spec.split(":"); n = int(n)
    img.crop((i * CELL, 0, (i + n) * CELL, CELL)).save(os.path.join(outdir, f"{name}.png"))
    print(name, n); i += n
