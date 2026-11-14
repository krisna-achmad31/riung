# Design Tasks — Riung

Daftar pekerjaan yang **dibutuhkan** dari design. Backend atau mobile, termasuk AI-nya, menulis permintaan untuk design di sini. Sumber desain ada di `design/riung.pen` dan `design/*.dc.html`.

## Aturan untuk AI dan desainer

1. Baca file ini sebelum mengerjakan desain. Ambil tugas `TODO` dengan prioritas tertinggi yang tidak `BLOCKED`.
2. Saat mulai, ubah status menjadi `IN_PROGRESS`. Saat selesai, ubah menjadi `DONE` dan isi nama frame atau file hasilnya.
3. Jika layar perlu dibangun, tambahkan tugas lanjutan di `MOBILE_TASKS.md`.
4. Jangan menghapus tugas. Tugas baru memakai nomor berikutnya.
5. Jika butuh keputusan pemilik produk atau tugas tim lain, ubah status menjadi `BLOCKED` dan tulis penyebabnya.

Status: `TODO` · `IN_PROGRESS` · `BLOCKED` · `DONE`
Prioritas: `P0` wajib sebelum rilis · `P1` penting · `P2` boleh menyusul

Format tugas baru:

```
## DES-000 — Judul
- **Status:** TODO
- **Prioritas:** P1
- **Diminta:** DD/MM/YYYY (inisial atau tim)
- **Latar belakang:** kenapa dibutuhkan.
- **Kriteria selesai:** layar, state, dan aset yang harus ada.
- **Hasil:** -
```

---

## DES-001 — Tautan bantuan krisis di check-in & jurnal
- **Status:** TODO
- **Prioritas:** P1
- **Diminta:** 14/11/2026 (AY, QA)
- **Latar belakang:** Aturan etis: layar krisis selalu bisa diakses. Kode sudah menambah tautan teks "Butuh bantuan sekarang" (`BantuanKrisisLink`) di bawah tombol utama Hasil check-in dan Simpan jurnal, tapi belum ada di desain.
- **Kriteria selesai:** frame `Glass — Checkin · Hasil` dan `Glass — Jurnal · Simpan` memuat tautan krisis (posisi, ikon, warna); putuskan perlu juga di Beranda atau tidak.
- **Hasil:** -
