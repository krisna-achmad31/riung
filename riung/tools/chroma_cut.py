"""Chroma-key cut for the Monster Kebiasaan sources (green #00B140 background).

Usage: python chroma_cut.py <src.png> <dst.png>
Output: square RGBA, shadow-free, object centred with ~6% margin.
"""
import sys

import cv2
import numpy as np
from PIL import Image

src, dst = sys.argv[1], sys.argv[2]
rgb = np.asarray(Image.open(src).convert("RGB")).astype(np.float32)
r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]

# green dominance: how much greener than the strongest other channel
dom = g - np.maximum(r, b)
# sample the actual background dominance at the corners
h, w = dom.shape
corners = np.concatenate([dom[:20, :20].ravel(), dom[:20, -20:].ravel(), dom[-20:, :20].ravel(), dom[-20:, -20:].ravel()])
bg = float(np.median(corners))
lo, hi = bg * 0.25, bg * 0.6
alpha = np.clip((hi - dom) / (hi - lo), 0, 1)

# keep only the largest connected object (drop stray specks)
mask = (alpha > 0.5).astype(np.uint8)
n, lab, stats, _ = cv2.connectedComponentsWithStats(mask, 8)
if n > 1:
    keep = 1 + np.argmax(stats[1:, cv2.CC_STAT_AREA])
    big = (lab == keep).astype(np.uint8)
    big = cv2.dilate(big, np.ones((5, 5), np.uint8))
    alpha *= big
# fill interior holes (e.g. green reflections inside the body)
solid = (alpha > 0.5).astype(np.uint8)
ff = solid.copy()
cv2.floodFill(ff, np.zeros((h + 2, w + 2), np.uint8), (0, 0), 1)
holes = (ff == 0) & (dom < hi)  # enclosed background (cup handle, cord loop) stays transparent
alpha[holes] = 1.0
alpha = cv2.GaussianBlur(alpha, (3, 3), 0)

# despill: clamp green to max(r, b) on semi-transparent / edge pixels
spill = np.maximum(r, b)
g2 = np.minimum(g, spill)
out = np.dstack([r, g2, b, alpha * 255]).clip(0, 255).astype(np.uint8)

ys, xs = np.where(alpha > 0.04)
x0, x1, y0, y1 = xs.min(), xs.max() + 1, ys.min(), ys.max() + 1
crop = out[y0:y1, x0:x1]
ch, cw = crop.shape[:2]
side = int(max(ch, cw) * 1.12)
canvas = np.zeros((side, side, 4), np.uint8)
ox, oy = (side - cw) // 2, (side - ch) // 2
canvas[oy:oy + ch, ox:ox + cw] = crop
im = Image.fromarray(canvas, "RGBA")
if side > 900:
    im = im.resize((900, 900), Image.LANCZOS)
im.save(dst)
print(dst, im.size)
