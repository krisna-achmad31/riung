from PIL import Image
import numpy as np
from scipy import ndimage
import cv2, shutil, os

SRC = r"D:\bismillah\riung\design\aset3d_cut\si_kabut.png"
OUT = r"C:\Users\achma\AppData\Local\Temp\opencode"

im = Image.open(SRC).convert("RGBA")
arr = np.array(im); alpha = arr[:,:,3].astype(int); H, W = alpha.shape
lab8, n8 = ndimage.label(alpha > 8)
sizes8 = ndimage.sum(np.ones_like(lab8), lab8, range(1, n8+1))
big8 = int(np.argmax(sizes8)) + 1
island = (alpha > 8) & (lab8 != big8)
island = ndimage.binary_dilation(island, np.ones((3,3), bool), iterations=2)
body = ndimage.binary_fill_holes(lab8 == big8)
ys, xs = np.where(body); cx, cy = xs.mean(), ys.mean()
NA = 1440; ang = np.arange(NA)*(2*np.pi/NA); ca, sa = np.cos(ang), np.sin(ang)
r = np.zeros(NA)
for i in range(NA):
    rr = 0
    for d in range(0, 600):
        x = int(round(cx+ca[i]*d)); y = int(round(cy+sa[i]*d))
        if x < 0 or y < 0 or x >= W or y >= H: break
        if body[y, x]: rr = d
    r[i] = rr
k = int(round(NA*26/360.0))
rs = ndimage.maximum_filter1d(ndimage.minimum_filter1d(r, k*2+1, mode="wrap"), k*2+1, mode="wrap")
poly = np.stack([cx+ca*rs, cy+sa*rs], axis=1).astype(np.int32)
pm = np.zeros((H, W), np.uint8); cv2.fillPoly(pm, [poly], 255)
pm = cv2.dilate(pm, cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (9,9)))
keep = (alpha > 8) & (pm > 0) & ~island
new_alpha = np.where(keep, alpha, 0).astype(np.uint8)
out = arr.copy(); out[:,:,3] = new_alpha
oi = Image.fromarray(out, "RGBA")
oi.save(OUT + r"\si_kabut_noshadow.png")

shutil.copyfile(SRC, OUT + r"\si_kabut_orig_backup.png")
oi.save(SRC)
print("wrote si_kabut.png", os.path.getsize(SRC), oi.size)
ys2, xs2 = np.where(np.array(oi)[:,:,3] > 6)
print("content bbox", xs2.min(), ys2.min(), xs2.max(), ys2.max())
