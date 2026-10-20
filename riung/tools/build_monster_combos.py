"""Bangun semua kombinasi aksesoris monster jinak sebagai gambar utuh (precompose).

Kenapa: aksesoris yang ditempel saat runtime tidak menyatu dengan art 3D. Jadi
aksesoris yang DIPAKAI (kepala & leher: topi rajut, syal, topi tidur, pin) harus
dirender AI bersama monsternya ("render pakai"), sedangkan benda lantai
(bantal mini & benda khas di samping) cukup dikomposit di sini dengan aturan
yang sama untuk semua kombinasi.

Sumber  : ../design/aset3d_cut/kombinasi/<monster>/<kunci>.png
          kunci = polos | topi | syal | topi_syal | tidur | tidur_syal | pin | topi_pin
          (polos boleh tidak ada -> pakai si_<monster>.png). PNG ber-alpha, latar sudah
          dibuang; bayangan lantai yang ikut terpotong dibuang otomatis.
Keluaran: ../design/aset3d_cut/<monster>_jinak_<NN>_<isi>.png   kanvas persegi 800,
          skala monster sama di semua kombinasi, garis lantai seragam, TANPA bayangan
          (bayangan digambar kode, CLAUDE.md aturan #7).

Jalankan dari folder `riung/`:
  python tools/build_monster_combos.py              # semua monster yang render-pakainya lengkap
  python tools/build_monster_combos.py waswas kabut # monster tertentu
  python tools/build_monster_combos.py --cek        # hanya laporan render-pakai yang kurang
  python tools/build_monster_combos.py --sebagian sempurna  # bangun kombinasi yang render-pakainya sudah ada saja
"""

import itertools
import json
import os
import sys

import cv2
import numpy as np
from PIL import Image

SRC = os.path.join('..', 'design', 'aset3d_cut')
KOMBINASI = os.path.join(SRC, 'kombinasi')
CANVAS = 800
FIT = 0.90
FLOOR = 0.95

# Benda lantai: tinggi relatif tinggi badan polos.
SIDE_HEIGHT = {
    'batu_tenang': 0.26, 'lentera': 0.46, 'bintang_kintsugi': 0.36, 'senter': 0.36,
    'selimut_peluk': 0.40, 'palu_busa': 0.40, 'jam_pasir': 0.40, 'kantong_hp': 0.34,
    'kompas': 0.30, 'cangkir_teh': 0.28,
}
PILLOW_WIDTH = 1.45   # lebar bantal relatif lebar badan polos
PILLOW_SINK = 0.30    # kaki menapak di 30% tinggi bantal dari atas (tenggelam ke bantal)

# Slot per monster. 'khas' = (id kosmetik, slot, label nama file).
MONSTERS = {
    'meronta': ('selimut_peluk', 'side', 'selimut'),
    'waswas': ('batu_tenang', 'side', 'batu'),
    'kabut': ('lentera', 'side', 'lentera'),
    'cermin': ('bingkai_emas', 'overlay', 'bingkai'),
    'sempurna': ('bintang_kintsugi', 'side', 'bintang'),
    'mengelak': ('senter', 'side', 'senter'),
    'hakim': ('palu_busa', 'side', 'palu'),
    'nanti': ('jam_pasir', 'side', 'jampasir'),
    'gulir': ('kantong_hp', 'side', 'kantonghp'),
    'begadang': ('topi_tidur', 'head', 'tidur'),
    'bunglon': ('pin_berani', 'neck', 'pin'),
    'bimbang': ('kompas', 'side', 'kompas'),
    'bara': ('cangkir_teh', 'side', 'teh'),
}
# Sama dengan build_3d_assets.FRAME_ON_CERMIN['jinak'] (kanvas ternormalisasi 512, fit 0.88, lantai 0.96).
FRAME_ON_CERMIN = (0.474, 0.499, 0.781)


def items_for(mid):
    khas, slot, label = MONSTERS[mid]
    items = [('topi', 'head'), ('syal', 'neck'), (label, slot), ('bantal', 'base')]
    return items, khas


def combos(mid):
    """Semua kombinasi valid (satu benda per slot), urut jumlah lalu urutan item."""
    items, _ = items_for(mid)
    out = []
    for n in range(len(items) + 1):
        for c in itertools.combinations(items, n):
            slots = [s for _, s in c]
            if len(slots) == len(set(slots)):
                out.append([name for name, _ in c])
    return out


def worn_key(mid, names):
    """Render-pakai yang dibutuhkan untuk kombinasi ini (isi kepala + leher)."""
    _, slot, label = MONSTERS[mid]
    worn = [n for n in names if n in ('topi', 'syal') or (n == label and slot in ('head', 'neck'))]
    return '_'.join(worn) or 'polos'


def file_name(mid, idx, names, total_items):
    body = 'polos' if not names else ('lengkap' if len(names) == total_items else '_'.join(names))
    return f'{mid}_jinak_{idx:02d}_{body}.png'


def cut_white(im, tol=14):
    """Buang latar putih/abu terang (hasil Gemini) dengan flood fill dari tepi gambar."""
    rgb = im[:, :, :3].astype(np.int16)
    h, w = rgb.shape[:2]
    border = np.concatenate([rgb[0], rgb[-1], rgb[:, 0], rgb[:, -1]])
    bg = np.median(border, axis=0)
    near = (np.abs(rgb - bg).max(axis=2) <= tol).astype(np.uint8)
    mask = np.zeros((h + 2, w + 2), np.uint8)
    seeds = [(x, y) for x in range(0, w, 16) for y in (0, h - 1)] + [(x, y) for y in range(0, h, 16) for x in (0, w - 1)]
    fill = near.copy()
    for x, y in seeds:
        if fill[y, x] == 1:
            cv2.floodFill(fill, mask, (x, y), 2)
    alpha = np.where(fill == 2, 0, 255).astype(np.uint8)
    alpha = cv2.GaussianBlur(cv2.erode(alpha, np.ones((3, 3), np.uint8)), (0, 0), 1.0)
    im[:, :, 3] = alpha
    return im


def load_rgba(path):
    im = np.array(Image.open(path).convert('RGBA'))
    if im[:, :, 3].min() == 255:
        im = cut_white(im)
    a = im[:, :, 3]
    solid = np.where(a > 200)
    if solid[0].size:
        # Buang bayangan lantai: semua di bawah dasar badan solid, plus piksel
        # semi-transparan di pita kaki (bayangan yang melebar ke samping kaki).
        top, bottom = solid[0].min(), solid[0].max()
        im[bottom + 4:, :, 3] = 0
        band = im[bottom - int(0.06 * (bottom - top)):bottom + 4, :, 3]
        band[band < 160] = 0
    return im


def solid_bbox(im):
    ys, xs = np.where(im[:, :, 3] > 200)
    return xs.min(), ys.min(), xs.max(), ys.max()


def align(ref, mov):
    """Transform similaritas (2x3) yang memetakan render-pakai ke ruang polos."""
    sift = cv2.SIFT_create(4000)

    def feats(im):
        g = cv2.cvtColor(im[:, :, :3], cv2.COLOR_RGB2GRAY)
        mask = (im[:, :, 3] > 200).astype(np.uint8) * 255
        return sift.detectAndCompute(g, mask)

    k1, d1 = feats(ref)
    k2, d2 = feats(mov)
    good = []
    if d1 is not None and d2 is not None:
        for m in cv2.BFMatcher().knnMatch(d2, d1, k=2):
            if len(m) == 2 and m[0].distance < 0.72 * m[1].distance:
                good.append(m[0])
    if len(good) >= 12:
        src = np.float32([k2[m.queryIdx].pt for m in good])
        dst = np.float32([k1[m.trainIdx].pt for m in good])
        M, inl = cv2.estimateAffinePartial2D(src, dst, method=cv2.RANSAC, ransacReprojThreshold=4)
        if M is not None and inl.sum() >= 10:
            return M, int(inl.sum())
    # Cadangan: samakan lebar & dasar bbox (kurang akurat bila syal melebarkan badan).
    rx0, ry0, rx1, ry1 = solid_bbox(ref)
    mx0, my0, mx1, my1 = solid_bbox(mov)
    k = (ry1 - ry0) / (my1 - my0)
    return np.float32([[k, 0, (rx0 + rx1) / 2 - k * (mx0 + mx1) / 2], [0, k, ry1 - k * my1]]), 0


def place(layer_list, im, M):
    layer_list.append((im, M))


def affine_of(scale, tx, ty):
    return np.float32([[scale, 0, tx], [0, scale, ty]])


def bounds_of(layers):
    xs, ys = [], []
    for im, M in layers:
        x0, y0, x1, y1 = solid_or_any_bbox(im)
        pts = np.float32([[x0, y0], [x1, y0], [x0, y1], [x1, y1]])
        p = pts @ M[:, :2].T + M[:, 2]
        xs += list(p[:, 0]); ys += list(p[:, 1])
    return min(xs), min(ys), max(xs), max(ys)


def solid_or_any_bbox(im):
    ys, xs = np.where(im[:, :, 3] > 8)
    return xs.min(), ys.min(), xs.max() + 1, ys.max() + 1


def render(layers, G):
    """Gabungkan layer (urut bawah->atas) ke kanvas dengan transform global G."""
    out = np.zeros((CANVAS, CANVAS, 4), np.float32)
    for im, M in layers:
        T = compose(G, M)
        w = cv2.warpAffine(im, T, (CANVAS, CANVAS), flags=cv2.INTER_LANCZOS4,
                           borderMode=cv2.BORDER_CONSTANT, borderValue=(0, 0, 0, 0)).astype(np.float32)
        a = w[:, :, 3:4] / 255.0
        out[:, :, :3] = w[:, :, :3] * a + out[:, :, :3] * (1 - a)
        out[:, :, 3:4] = a + out[:, :, 3:4] * (1 - a)
    rgb = np.where(out[:, :, 3:4] > 0, out[:, :, :3] / np.maximum(out[:, :, 3:4], 1e-6) * 1.0, 0)
    # out[:, :, :3] sudah premultiplied terhadap alpha; kembalikan ke straight alpha.
    res = np.dstack([np.clip(rgb, 0, 255), np.clip(out[:, :, 3] * 255, 0, 255)]).astype(np.uint8)
    return res


def compose(A, B):
    A3 = np.vstack([A, [0, 0, 1]])
    B3 = np.vstack([B, [0, 0, 1]])
    return (A3 @ B3)[:2].astype(np.float32)


def build(mid, write=True, partial=False):
    items, khas = items_for(mid)
    _, slot, label = MONSTERS[mid]
    folder = os.path.join(KOMBINASI, mid)
    polos_path = os.path.join(folder, 'polos.png')
    if not os.path.exists(polos_path):
        polos_path = os.path.join(SRC, f'si_{mid}.png')
    ref = load_rgba(polos_path)
    x0, y0, x1, y1 = solid_bbox(ref)
    bw, bh, cx, feet = x1 - x0, y1 - y0, (x0 + x1) / 2, y1

    all_combos = combos(mid)
    needed = sorted({worn_key(mid, c) for c in all_combos})
    missing = [k for k in needed if k != 'polos' and not os.path.exists(os.path.join(folder, f'{k}.png'))]
    if not write or (missing and not partial):
        return missing, None
    if missing:
        all_combos = [c for c in all_combos if worn_key(mid, c) not in missing]
        needed = [k for k in needed if k not in missing]

    worn = {'polos': (ref, affine_of(1, 0, 0))}
    report = {}
    for k in needed:
        if k == 'polos':
            continue
        im = load_rgba(os.path.join(folder, f'{k}.png'))
        M, inliers = align(ref, im)
        worn[k] = (im, M)
        report[k] = {'inliers': inliers, 'scale': round(float(np.hypot(M[0, 0], M[1, 0])), 3)}

    pillow = load_rgba(os.path.join(SRC, 'bantal_mini.png'))
    px0, py0, px1, py1 = solid_or_any_bbox(pillow)
    ps = PILLOW_WIDTH * bw / (px1 - px0)
    ph = (py1 - py0) * ps
    p_top = feet - PILLOW_SINK * ph
    pillow_M = affine_of(ps, cx - ps * (px0 + px1) / 2, p_top - ps * py0)

    side = None
    if slot == 'side':
        side = load_rgba(os.path.join(SRC, f'{khas}.png'))
        sx0, sy0, sx1, sy1 = solid_or_any_bbox(side)
        ss = SIDE_HEIGHT[khas] * bh / (sy1 - sy0)
        sw = (sx1 - sx0) * ss

    frame = None
    if slot == 'overlay':
        frame = load_rgba(os.path.join(SRC, 'bingkai_emas.png'))

    scenes = []
    for names in all_combos:
        layers = []
        has_pillow = 'bantal' in names
        floor = p_top + ph if has_pillow else feet
        if has_pillow:
            layers.append((pillow, pillow_M))
        layers.append(worn[worn_key(mid, names)])
        if frame is not None and label in names:
            # Bingkai mengikuti kanvas polos ternormalisasi milik build_3d_assets.
            ax0, ay0, ax1, ay1 = solid_or_any_bbox(ref)
            n = 512 * 0.88 / max(ax1 - ax0, ay1 - ay0)
            fcx, fcy, fw = FRAME_ON_CERMIN
            nx0 = (512 - (ax1 - ax0) * n) / 2
            ny0 = 512 * 0.96 - (ay1 - ay0) * n
            fx0, fy0, fx1, fy1 = solid_or_any_bbox(frame)
            fsc = (fw * 512 / n) / (fx1 - fx0)
            ccx = ax0 + (fcx * 512 - nx0) / n
            ccy = ay0 + (fcy * 512 - ny0) / n
            layers.append((frame, affine_of(fsc, ccx - fsc * (fx0 + fx1) / 2, ccy - fsc * (fy0 + fy1) / 2)))
        if side is not None and label in names:
            reach = max(0.60 * bw, 0.5 * PILLOW_WIDTH * bw * 0.80) if has_pillow else 0.60 * bw
            bottom = floor - (0.06 * ph if has_pillow else -0.02 * bh)
            sx = cx + reach - sw / 2
            layers.append((side, affine_of(ss, sx - ss * sx0, bottom - ss * sy1)))
        scenes.append((names, layers))

    # Satu transform global untuk semua kombinasi -> skala & lantai sama.
    bx = [bounds_of(l) for _, l in scenes]
    U = (min(b[0] for b in bx), min(b[1] for b in bx), max(b[2] for b in bx), max(b[3] for b in bx))
    base_floor = max(b[3] for b in bx)
    k = CANVAS * FIT / max(U[2] - U[0], U[3] - U[1])
    G = affine_of(k, CANVAS / 2 - k * (U[0] + U[2]) / 2, CANVAS * FLOOR - k * base_floor)

    outs = []
    index = {tuple(c): i for i, c in enumerate(combos(mid), 1)}
    for names, layers in scenes:
        res = render(layers, G)
        name = file_name(mid, index[tuple(names)], names, len(items))
        Image.fromarray(res).save(os.path.join(SRC, name))
        outs.append(name)
    return missing, {'files': outs, 'align': report}


def main():
    args = [a for a in sys.argv[1:] if not a.startswith('--')]
    check = '--cek' in sys.argv
    partial = '--sebagian' in sys.argv
    ids = args or list(MONSTERS)
    for mid in ids:
        missing, res = build(mid, write=not check, partial=partial)
        if res:
            print(f'{mid}: {len(res["files"])} kombinasi  align={json.dumps(res["align"])}')
        if missing:
            print(f'{mid}: render-pakai kurang -> {", ".join(missing)}  (taruh di design/aset3d_cut/kombinasi/{mid}/)')
        elif not res:
            print(f'{mid}: lengkap ({len(combos(mid))} kombinasi)')


if __name__ == '__main__':
    main()
