"""Siluet misteri Monster Kebiasaan untuk landing (teaser).

Bentuk dari alpha `si_<id>_liar.png`, diisi gradien malam (g-sleep) + rim
lembut di tepi atas supaya bentuknya terbaca tapi detailnya tetap rahasia.
Output: siluet/misteri_<n>.png (urutan = urutan Kuis Besar) — nama file
sengaja tidak memuat nama monster.
"""
from pathlib import Path
from PIL import Image, ImageChops, ImageFilter

HERE = Path(__file__).resolve().parent
SRC = HERE.parent
ORDER = ['nanti', 'gulir', 'begadang', 'bunglon', 'bimbang', 'bara']
TOP, BOTTOM, RIM = (0x5A, 0x53, 0x8C), (0x2C, 0x35, 0x57), (0xB9, 0xB2, 0xE6)
SIZE = 512

for i, mid in enumerate(ORDER, 1):
    src = Image.open(SRC / f'si_{mid}_liar.png').convert('RGBA')
    a = src.getchannel('A')
    l, t, r, b = a.getbbox()
    grad = Image.new('RGB', src.size)
    h = max(1, b - t)
    px = grad.load()
    for y in range(src.size[1]):
        k = min(1, max(0, (y - t) / h))
        c = tuple(round(TOP[j] + (BOTTOM[j] - TOP[j]) * k) for j in range(3))
        for x in range(src.size[0]):
            px[x, y] = c
    # rim: alpha minus alpha geser ke bawah-kanan → tepi atas-kiri menyala
    shifted = ImageChops.offset(a, 6, 8)
    rim = ImageChops.subtract(a, shifted).filter(ImageFilter.GaussianBlur(3))
    grad = Image.composite(Image.new('RGB', src.size, RIM), grad, rim.point(lambda v: int(v * .55)))
    out = Image.merge('RGBA', (*grad.split(), a))
    out = out.crop((l, t, r, b))
    s = SIZE * 0.86 / max(out.size)
    out = out.resize((round(out.size[0] * s), round(out.size[1] * s)), Image.LANCZOS)
    canvas = Image.new('RGBA', (SIZE, SIZE))
    canvas.paste(out, ((SIZE - out.size[0]) // 2, SIZE - 24 - out.size[1]), out)
    canvas.save(HERE / f'misteri_{i}.png')
    print('ok', i, mid, out.size)
