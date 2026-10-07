"""Bangun aset 3D (WebP) untuk Flutter dari hasil desain Riung Glass.

Sumber : ../design/aset3d_cut/  (PNG ber-alpha hasil potong latar, TANPA bayangan lantai —
         bayangan digambar di Flutter oleh RiungGroundShadow; cadangan potongan lama di _asli/)
Keluaran:
  assets/monsters/3d/<monster>_<liar|jinak>.webp   kanvas persegi 512, garis lantai seragam
  assets/monsters/3d/<kosmetik>.webp               kosmetik ter-crop rapat
  assets/characters/<kode>.webp                    karakter kepribadian, kanvas persegi 512
  assets/characters/accessories/<id>.webp          aksesori karakter yang punya versi 3D
  assets/icons/<nama>.webp                         ikon 3D Riung Glass (kanvas persegi 192)

Jalankan dari folder `riung/`:  python tools/build_3d_assets.py
Skrip ini juga mencetak metrik badan (bbox ternormalisasi) sebagai dasar
kalibrasi `assets/monsters/anchors.json` & `character_art.dart`.
"""

import json
import os

from PIL import Image

SRC = os.path.join('..', 'design', 'aset3d_cut')
MON_OUT = os.path.join('assets', 'monsters', '3d')
CHAR_OUT = os.path.join('assets', 'characters')
ACC_OUT = os.path.join(CHAR_OUT, 'accessories')
ICON_OUT = os.path.join('assets', 'icons')
ICON_SIZE = 192

CANVAS = 512
# Subjek dimuat ke kotak 88% kanvas, dasarnya di 96% tinggi (garis lantai sama
# untuk semua monster, supaya grid & anchor konsisten).
FIT = 0.88
FLOOR = 0.96
QUALITY = 86

MONSTERS = {
    'meronta': ('si_meronta.png', 'si_meronta_liar.png'),
    'waswas': ('si_waswas.png', 'si_waswas_liar.png'),
    'kabut': ('si_kabut.png', 'si_kabut_liar.png'),
    'cermin': ('si_cermin.png', 'si_cermin_liar.png'),
    'sempurna': ('si_sempurna.png', 'si_sempurna_liar.png'),
    'mengelak': ('si_mengelak.png', 'si_mengelak_liar.png'),
    'hakim': ('si_hakim.png', 'si_hakim_liar.png'),
    # Monster Kebiasaan (bangun dari Kuis Besar "Kenali Dirimu").
    'nanti': ('si_nanti.png', 'si_nanti_liar.png'),
    'gulir': ('si_gulir.png', 'si_gulir_liar.png'),
    'begadang': ('si_begadang.png', 'si_begadang_liar.png'),
    'bunglon': ('si_bunglon.png', 'si_bunglon_liar.png'),
    'bimbang': ('si_bimbang.png', 'si_bimbang_liar.png'),
    'bara': ('si_bara.png', 'si_bara_liar.png'),
}

COSMETICS = {
    'topi_rajut': 'topi_rajut.png',
    'syal_hangat': 'syal_hangat.png',
    'bantal_mini': 'bantal_mini.png',
    'bingkai_emas': 'bingkai_emas.png',
    # Kosmetik khas (hanya untuk satu monster, lihat toko_data.dart).
    'jam_pasir': 'jam_pasir.png',
    'kantong_hp': 'kantong_hp.png',
    'topi_tidur': 'topi_tidur.png',
    'pin_berani': 'pin_berani.png',
    'kompas': 'kompas.png',
    'cangkir_teh': 'cangkir_teh.png',
    'batu_tenang': 'batu_tenang.png',
    'lentera': 'lentera.png',
    'bintang_kintsugi': 'bintang_kintsugi.png',
    'senter': 'senter.png',
    'selimut_peluk': 'selimut_peluk.png',
    'palu_busa': 'palu_busa.png',
}

CHARACTERS = [
    'INFP', 'INFJ', 'ENFP', 'ENFJ', 'INTP', 'INTJ', 'ENTP', 'ENTJ',
    'ISFJ', 'ISTJ', 'ESFJ', 'ESTJ', 'ISFP', 'ISTP', 'ESFP', 'ESTP',
    'sanguinis', 'koleris', 'melankolis', 'flegmatis',
    'aman', 'cemas', 'menghindar', 'cemas_menghindar',
]

# id CharacterAccessory -> file sumber 3D (semua 26 aksesori).
CHAR_ACCESSORIES = {
    'beanie': 'topi_rajut.png',
    'scarf': 'syal_hangat.png',
    'roundGlasses': 'kacamata_bulat.png',
    'halo': 'halo.png',
    'wings': 'sayap.png',
    'headphones': 'headphone.png',
    **{a: f'aksesori/{a}.png' for a in [
        'ribbon', 'flower', 'witchHat', 'starStickers', 'sunglasses', 'necklace', 'backpack', 'cape',
        'jungCrown', 'jungMask', 'jungCompass', 'jungLantern',
        'tempFlame', 'tempMonocle', 'tempLeaf', 'tempWave',
        'attNightCap', 'attHeartCharm', 'attBlanket', 'attCompanion',
    ]},
}


# Ikon 3D (ikon_<nama>.png) -> assets/icons/<nama>.webp, dipusatkan di kanvas persegi.
ICONS = [
    'afirmasi', 'aplikasi_beku', 'bantuan', 'beranda', 'checkin', 'fokus', 'jurnal', 'kepribadian',
    'koin', 'laporan', 'meditasi', 'pelindung', 'premium', 'streak', 'tidur', 'tiket',
]


# bingkai_emas (slot "none", khusus Cermin): di-precompose ke kanvas penuh per
# wujud supaya renderer cukup menimpanya 1:1 (CLAUDE.md aturan #7).
# Nilai = (pusat x, pusat y, lebar) ternormalisasi, mengikuti tepi cermin.
FRAME_ON_CERMIN = {'jinak': (0.474, 0.499, 0.781), 'liar': (0.449, 0.521, 0.725)}


def body_bbox(im, threshold=190):
    """Bbox badan (alpha tinggi), mengabaikan bayangan lantai yang semi-transparan."""
    a = im.getchannel('A').point(lambda v: 255 if v >= threshold else 0)
    return a.getbbox()


def tight(im, threshold=8):
    a = im.getchannel('A').point(lambda v: 255 if v >= threshold else 0)
    return im.crop(a.getbbox())


def normalize(im):
    """Muat subjek ke kanvas persegi dengan garis lantai seragam."""
    sub = tight(im)
    w, h = sub.size
    k = (CANVAS * FIT) / max(w, h)
    sub = sub.resize((max(1, round(w * k)), max(1, round(h * k))), Image.LANCZOS)
    canvas = Image.new('RGBA', (CANVAS, CANVAS), (0, 0, 0, 0))
    x = (CANVAS - sub.width) // 2
    y = round(CANVAS * FLOOR) - sub.height
    canvas.paste(sub, (x, max(0, y)), sub)
    return canvas


def save(im, path):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    im.save(path, 'WEBP', quality=QUALITY, method=4)


def metrics(im):
    l, t, r, b = body_bbox(im)
    return {
        'left': round(l / CANVAS, 4), 'top': round(t / CANVAS, 4),
        'right': round(r / CANVAS, 4), 'bottom': round(b / CANVAS, 4),
    }


def main():
    report = {'monsters': {}, 'cosmetics': {}, 'characters': {}}
    for mid, (jinak, liar) in MONSTERS.items():
        for state, f in (('jinak', jinak), ('liar', liar)):
            im = normalize(Image.open(os.path.join(SRC, f)).convert('RGBA'))
            save(im, os.path.join(MON_OUT, f'{mid}_{state}.webp'))
            report['monsters'][f'{mid}_{state}'] = metrics(im)
    for cid, f in COSMETICS.items():
        im = tight(Image.open(os.path.join(SRC, f)).convert('RGBA'))
        im.thumbnail((384, 384), Image.LANCZOS)
        save(im, os.path.join(MON_OUT, f'{cid}.webp'))
        report['cosmetics'][cid] = {'aspect': round(im.width / im.height, 4)}
    frame = tight(Image.open(os.path.join(SRC, COSMETICS['bingkai_emas'])).convert('RGBA'))
    for state, (cx, cy, wf) in FRAME_ON_CERMIN.items():
        w = round(CANVAS * wf)
        h = round(w * frame.height / frame.width)
        overlay = Image.new('RGBA', (CANVAS, CANVAS), (0, 0, 0, 0))
        overlay.paste(frame.resize((w, h), Image.LANCZOS), (round(cx * CANVAS - w / 2), round(cy * CANVAS - h / 2)))
        save(overlay, os.path.join(MON_OUT, f'bingkai_emas_cermin_{state}.webp'))
    for code in CHARACTERS:
        im = normalize(Image.open(os.path.join(SRC, 'karakter_ai', f'{code}.png')).convert('RGBA'))
        save(im, os.path.join(CHAR_OUT, f'{code.lower()}.webp'))
        report['characters'][code] = metrics(im)
    for aid, f in CHAR_ACCESSORIES.items():
        im = tight(Image.open(os.path.join(SRC, f)).convert('RGBA'))
        im.thumbnail((384, 384), Image.LANCZOS)
        save(im, os.path.join(ACC_OUT, f'{aid}.webp'))
        report['cosmetics'][f'acc_{aid}'] = {'aspect': round(im.width / im.height, 4)}
    for name in ICONS:
        im = tight(Image.open(os.path.join(SRC, f'ikon_{name}.png')).convert('RGBA'))
        im.thumbnail((ICON_SIZE, ICON_SIZE), Image.LANCZOS)
        canvas = Image.new('RGBA', (ICON_SIZE, ICON_SIZE), (0, 0, 0, 0))
        canvas.paste(im, ((ICON_SIZE - im.width) // 2, (ICON_SIZE - im.height) // 2), im)
        save(canvas, os.path.join(ICON_OUT, f'{name}.webp'))
    print(json.dumps(report, indent=1))


if __name__ == '__main__':
    main()
