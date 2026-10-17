# /// script
# dependencies = ["pillow", "numpy"]
# ///
"""Make a 1024px rounded app icon from the base character image: head+shoulders crop on soft gradient."""
import sys
import numpy as np
from PIL import Image, ImageDraw, ImageFilter
src = Image.open(sys.argv[1]).convert("RGBA")
a = np.array(src).astype(np.int16)
dist = 255 - a[..., :3].min(axis=2)
a[..., 3] = np.clip(dist * 4, 0, 255)
char = Image.fromarray(a.astype(np.uint8), "RGBA")
char = char.crop(char.getbbox())
# face only: top 46% (hair, bow, do'ppi, eyes, cheeks)
char = char.crop((0, 0, char.width, int(char.height * 0.46)))
# re-crop to the head's own bounding box so the face fills the icon
hb = np.array(char)[..., 3] > 40
ys = np.where(hb.any(axis=1))[0]; xs = np.where(hb.any(axis=0))[0]
char = char.crop((xs.min(), ys.min(), xs.max() + 1, ys.max() + 1))
S = 1024
bg = Image.new("RGBA", (S, S), (0, 0, 0, 0))
grad = Image.new("RGBA", (S, S))
d = ImageDraw.Draw(grad)
for y in range(S):
    t = y / S
    d.line([(0, y), (S, y)], fill=(int(255 - 30 * t), int(205 - 40 * t), int(225 - 60 * t), 255))
mask = Image.new("L", (S, S), 0)
ImageDraw.Draw(mask).rounded_rectangle([0, 0, S - 1, S - 1], radius=230, fill=255)
bg.paste(grad, (0, 0), mask)
scale = min((S * 0.90) / char.width, (S * 0.90) / char.height)
char = char.resize((int(char.width * scale), int(char.height * scale)), Image.LANCZOS)
x = (S - char.width) // 2
y = (S - char.height) // 2 + int(S * 0.04)
bg.paste(char, (x, y), char)
bg.save(sys.argv[2])
print("icon written")
