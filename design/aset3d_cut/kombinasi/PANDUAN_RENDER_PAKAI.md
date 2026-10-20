# Panduan render-pakai (aksesoris kepala & leher) — semua monster jinak

**Kenapa dibagi dua**
- Aksesoris yang **dipakai** (topi rajut, syal, topi tidur, pin) harus dirender AI bersama monsternya. Kalau ditempel, hasilnya tidak menyatu. Ini yang membuat Sempurna dan Kabut lama terlihat salah: topinya ditempel datar dan badannya tersambung-sambung.
- Benda **lantai** (bantal mini dan benda khas di samping) cukup dikomposit oleh `riung/tools/build_monster_combos.py`. Ukuran dan garis lantainya sama untuk semua kombinasi.

Jadi per monster cukup **3 render** (5 untuk Begadang dan Bunglon). Ke-16 kombinasi lalu dibangun otomatis.

## Cara membuat (Gemini, sama seperti Waswas)
1. Lampirkan 2–3 gambar:
   - `design/aset3d_cut/si_<monster>.png` (monster polos)
   - gambar aksesorisnya: `topi_rajut.png`, `syal_hangat.png`, `topi_tidur.png` atau `pin_berani.png`
2. Pakai prompt di bawah. Satu render per percakapan baru supaya monster tidak bergeser.
3. Simpan sebagai PNG atau JPG di `design/aset3d_cut/kombinasi/<monster>/<kunci>.png`, misalnya `kombinasi/kabut/topi.png`. Latar putih dibuang otomatis.
4. Dari folder `riung/`, jalankan:
   ```
   python tools/build_monster_combos.py <monster>
   ```
   Hasilnya `design/aset3d_cut/<monster>_jinak_NN_*.png`, dan board di campaign.pen ikut terbarui.

**Syarat agar komposit rapi:**
- Sudut kamera, pose, ekspresi dan proporsi sama dengan gambar polos.
- Seluruh badan terlihat, termasuk kaki.
- Latar putih polos tanpa bayangan lantai.
- Tidak ada benda lain.

### Prompt dasar (ganti `[AKSESORIS]`)
```
Use the first image as the exact character reference. Recreate this exact same 3D character — identical body shape, proportions, colors, materials, face, expression, pose and camera angle, front view, full body visible including feet — now wearing [AKSESORIS] (use the second image as the exact design reference for the accessory). The accessory must be physically worn: it wraps around / sits on the body with correct contact, overlap and soft occlusion shadows, scaled to fit this character. Soft studio lighting, cute premium 3D toy render, same render style as the reference. Plain pure white background (#FFFFFF), no floor shadow, no props, no text.
```

| Kunci file | `[AKSESORIS]` |
|---|---|
| `topi` | `the pink cable-knit beanie with cream cuff and pom-pom, sitting snugly on top of its head (horns/antennae/ears poke through or around the hat naturally)` |
| `syal` | `the periwinkle-blue chunky knit scarf wrapped once around its neck/upper body, with the two fringed ends hanging in front` |
| `topi_syal` | `BOTH the pink cable-knit beanie with pom-pom on its head AND the periwinkle-blue chunky knit scarf wrapped around its neck with fringed ends in front` (lampirkan kedua gambar aksesoris) |
| `tidur` (Begadang) | `the sleeping nightcap from the second image on its head, tip flopping to one side` |
| `syal_tidur` (Begadang) | `the sleeping nightcap on its head AND the periwinkle-blue chunky knit scarf around its neck` |
| `pin` (Bunglon) | `the small brave pin badge from the second image pinned on its chest` |
| `topi_pin` (Bunglon) | `the pink cable-knit beanie on its head AND the small brave pin badge on its chest` |

**Catatan Si Kabut:** tambahkan kalimat berikut ke prompt:
`The character is a floating fluffy cloud with a clean rounded silhouette — no extra mist wisps on the sides.`
Potongan `si_kabut.png` asli punya serpihan kabut di kiri dan kanan. Untuk kombinasi, sudah saya rapikan sebagai `kombinasi/kabut/polos.png`. Lampirkan file itu, bukan `si_kabut.png`.

## Status per monster (2026-10-17)

| Monster | Benda khas | Render yang dibutuhkan | Status |
|---|---|---|---|
| Waswas | batu tenang (lantai) | topi, syal, topi_syal | ✅ lengkap, 16 kombinasi dibangun ulang (skala seragam, tanpa bayangan) |
| Kabut | lentera (lantai) | topi, syal, topi_syal | ◐ 01/04/05/11 benar (polos dirapikan). 12 lainnya masih versi lama yang salah |
| Sempurna | bintang kintsugi (lantai) | topi, syal, topi_syal | ◐ 01/04/05/11 benar. 12 lainnya masih versi lama yang salah (badan tersambung, topi dan bantal terpotong) |
| Meronta | selimut peluk (lantai) | topi, syal, topi_syal | ⏳ |
| Cermin | bingkai emas (overlay, otomatis) | topi, syal, topi_syal | ⏳ |
| Mengelak | senter (lantai) | topi, syal, topi_syal | ⏳ |
| Hakim | palu busa (lantai) | topi, syal, topi_syal | ⏳ |
| Nanti | jam pasir (lantai) | topi, syal, topi_syal | ⏳ |
| Gulir | kantong HP (lantai) | topi, syal, topi_syal | ⏳ |
| Bimbang | kompas (lantai) | topi, syal, topi_syal | ⏳ |
| Bara | cangkir teh (lantai) | topi, syal, topi_syal | ⏳ |
| Begadang | topi tidur (**kepala**, tidak bisa bersamaan dengan topi rajut) | topi, syal, topi_syal, tidur, syal_tidur | ⏳ 12 kombinasi |
| Bunglon | pin berani (**leher**, tidak bisa bersamaan dengan syal) | topi, syal, topi_syal, pin, topi_pin | ⏳ 12 kombinasi |

Total masih **40 render** (Kabut 3, Sempurna 3, 8 monster lain × 3, Begadang 5, Bunglon 5).

Cek kekurangan kapan saja:
```
python tools/build_monster_combos.py --cek
```
Bangun yang sudah bisa saja:
```
python tools/build_monster_combos.py --sebagian <monster>
```

Set kombinasi lama ada di `design/aset3d_cut/_asli/kombinasi_lama/`.
