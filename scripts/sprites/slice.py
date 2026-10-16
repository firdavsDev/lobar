# /// script
# dependencies = ["pillow", "numpy", "scipy"]
# ///
"""Slice a generated sprite sheet into a 256px-cell horizontal strip.

usage: uv run --script slice.py IN.png OUT.png [--frames N] [--bg auto|white|alpha] [--scale S]

Cells are found as connected clusters of non-background columns (so uneven spacing is fine),
then each sprite is scaled to a common height and placed with feet on the baseline (y=232).
"""
import sys, argparse
import numpy as np
from PIL import Image
from scipy import ndimage

CELL, BASELINE, TARGET_H = 256, 232, 200

def to_alpha(img, mode):
    img = img.convert("RGBA")
    a = np.array(img).astype(np.int16)
    if mode == "alpha" or (mode == "auto" and (a[..., 3] < 250).any()):
        return img
    # near-white → transparent; soften edges a bit
    rgb = a[..., :3]
    dist = 255 - rgb.min(axis=2)              # 0 for pure white
    alpha = np.clip(dist * 4, 0, 255).astype(np.uint8)
    a[..., 3] = alpha
    return Image.fromarray(a.astype(np.uint8), "RGBA")

def find_cells(img, min_gap=6, min_w=20):
    a = np.array(img)[..., 3] > 40
    cols = a.any(axis=0)
    cells, start, gap = [], None, 0
    for x, on in enumerate(cols):
        if on:
            if start is None: start = x
            gap = 0
        elif start is not None:
            gap += 1
            if gap >= min_gap:
                cells.append((start, x - gap)); start = None; gap = 0
    if start is not None: cells.append((start, len(cols)))
    cells = [(s, e) for s, e in cells if e - s >= min_w]
    return cells

def valley_split(img, n):
    """Pick n-1 cut columns at the lowest alpha coverage, spaced at least 0.55*cell apart."""
    a = (np.array(img)[..., 3] > 40).sum(axis=0).astype(float)
    k = 9
    cov = np.convolve(a, np.ones(k) / k, mode="same")
    bbox = img.getbbox(); x0, x1 = bbox[0], bbox[2]
    cell = (x1 - x0) / n
    cuts = []
    for i in range(1, n):
        center = x0 + i * cell
        lo, hi = int(center - cell * 0.3), int(center + cell * 0.3)
        seg = cov[lo:hi]
        cuts.append(lo + int(seg.argmin()))
    edges = [x0] + cuts + [x1]
    return [(edges[i], edges[i + 1]) for i in range(n)]

def strong_bbox(im, thr=40):
    a = np.array(im)[..., 3] > thr
    ys = np.where(a.any(axis=1))[0]; xs = np.where(a.any(axis=0))[0]
    if len(ys) == 0: return None
    return (int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1)

def remove_edge_fragments(sub):
    """Drop connected components that touch the left/right cut edge unless they belong to the main body."""
    arr = np.array(sub)
    mask = arr[..., 3] > 40
    labels, n = ndimage.label(mask)
    if n <= 1: return sub
    sizes = ndimage.sum(mask, labels, range(1, n + 1))
    main = int(np.argmax(sizes)) + 1
    w = mask.shape[1]
    kill = np.zeros_like(mask)
    for i in range(1, n + 1):
        if i == main: continue
        comp = labels == i
        cols = np.where(comp.any(axis=0))[0]
        touches_edge = cols.min() <= 1 or cols.max() >= w - 2
        if touches_edge:
            kill |= comp
    if kill.any():
        # also wipe the soft halo around killed fragments
        kill = ndimage.binary_dilation(kill, iterations=6)
        arr[kill, 3] = 0
    return Image.fromarray(arr, "RGBA")

def remove_floaters(sub):
    """Remove detached components lying entirely above the main body's top edge."""
    arr = np.array(sub)
    mask = arr[..., 3] > 40
    labels, n = ndimage.label(mask)
    if n <= 1: return sub
    sizes = ndimage.sum(mask, labels, range(1, n + 1))
    main = int(np.argmax(sizes)) + 1
    main_top = np.where((labels == main).any(axis=1))[0].min()
    kill = np.zeros_like(mask)
    for i in range(1, n + 1):
        if i == main: continue
        comp = labels == i
        rows = np.where(comp.any(axis=1))[0]
        if rows.max() < main_top + 6:
            kill |= comp
    if kill.any():
        arr[ndimage.binary_dilation(kill, iterations=6), 3] = 0
    return Image.fromarray(arr, "RGBA")

STRIP_FLOATERS = False

def crop_cell(img, x0, x1):
    sub = remove_edge_fragments(img.crop((x0, 0, x1, img.height)))
    if STRIP_FLOATERS: sub = remove_floaters(sub)
    bbox = strong_bbox(sub)
    return sub.crop(bbox) if bbox else sub

def main():
    p = argparse.ArgumentParser()
    p.add_argument("inp"); p.add_argument("out")
    p.add_argument("--frames", type=int, default=0)
    p.add_argument("--bg", default="auto")
    p.add_argument("--height", type=int, default=TARGET_H)
    p.add_argument("--order", default="", help="comma list of 1-based frame indices to emit, e.g. 2,3,4,1")
    p.add_argument("--anchor", default="feet", choices=["feet", "bbox"], help="horizontal alignment reference")
    p.add_argument("--strip-floaters", action="store_true", help="remove detached parts above the body (baked z's, stars)")
    args = p.parse_args()
    global STRIP_FLOATERS
    STRIP_FLOATERS = args.strip_floaters
    img = to_alpha(Image.open(args.inp), args.bg)
    cells = find_cells(img)
    if args.frames and len(cells) != args.frames:
        print(f"warning: found {len(cells)} clusters, expected {args.frames}; splitting at coverage valleys", file=sys.stderr)
        cells = valley_split(img, args.frames)
    sprites = [crop_cell(img, s, e) for s, e in cells]
    if args.order:
        idx = [int(i) - 1 for i in args.order.split(",")]
        sprites = [sprites[i] for i in idx]
    # common scale so the tallest sprite is `height` px
    heights = sorted(s.height for s in sprites)
    median = heights[len(heights) // 2]
    scale = args.height / median
    out = Image.new("RGBA", (CELL * len(sprites), CELL), (0, 0, 0, 0))
    for i, s in enumerate(sprites):
        s = s.resize((max(1, round(s.width * scale)), max(1, round(s.height * scale))), Image.LANCZOS)
        if args.anchor == "feet":
            a = np.array(s)[..., 3] > 40
            rows = a[int(a.shape[0] * 0.8):]          # bottom 20%: legs/feet
            cols = np.where(rows.any(axis=0))[0]
            cx = (cols.min() + cols.max()) / 2 if len(cols) else s.width / 2
        else:
            cx = s.width / 2
        x = i * CELL + int(round(CELL / 2 - cx))
        y = BASELINE - s.height
        out.paste(s, (x, y), s)
    out.save(args.out)
    print(f"{args.out}: {len(sprites)} frames")

if __name__ == "__main__":
    main()
