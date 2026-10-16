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
# keep top 62% (head + shoulders)
char = char.crop((0, 0, char.width, int(char.height * 0.62)))
S = 1024
bg = Image.new("RGBA", (S, S), (0, 0, 0, 0))
grad = Image.new("RGBA", (S, S))
d = ImageDraw.Draw(grad)
for y in range(S):
    t = y / S
    d.line([(0, y), (S, y)], fill=(int(70 + 40 * t), int(140 - 30 * t), int(200 - 60 * t), 255))
mask = Image.new("L", (S, S), 0)
ImageDraw.Draw(mask).rounded_rectangle([0, 0, S - 1, S - 1], radius=230, fill=255)
bg.paste(grad, (0, 0), mask)
scale = (S * 0.86) / char.width
char = char.resize((int(char.width * scale), int(char.height * scale)), Image.LANCZOS)
x = (S - char.width) // 2
y = S - char.height + int(S * 0.02)
bg.paste(char, (x, y), char)
bg.save(sys.argv[2])
print("icon written")
