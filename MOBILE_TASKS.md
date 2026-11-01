# Mobile Tasks — Riung

Daftar pekerjaan yang **dibutuhkan** dari app Flutter. Backend atau design, termasuk AI-nya, menulis permintaan untuk mobile di sini. Perubahan yang sudah selesai dicatat di `CHANGELOG.md`.

## Aturan untuk AI dan developer

1. Baca file ini sebelum mengerjakan app. Ambil tugas `TODO` dengan prioritas tertinggi yang tidak `BLOCKED`.
2. Saat mulai, ubah status menjadi `IN_PROGRESS`. Saat selesai, ubah menjadi `DONE` dan isi commit atau PR.
3. Satu tugas harus memenuhi semua kriteria selesai dan tesnya lolos.
4. Jangan menghapus tugas. Tugas baru memakai nomor berikutnya.
5. Jika butuh keputusan pemilik produk atau tugas tim lain, ubah status menjadi `BLOCKED` dan tulis penyebabnya.

Status: `TODO` · `IN_PROGRESS` · `BLOCKED` · `DONE`
Prioritas: `P0` wajib sebelum rilis · `P1` penting · `P2` boleh menyusul

Format tugas baru:

```
## MOB-000 — Judul
- **Status:** TODO
- **Prioritas:** P1
- **Diminta:** DD/MM/YYYY (inisial atau tim)
- **Latar belakang:** kenapa dibutuhkan.
- **Kriteria selesai:** hasil yang bisa dicek.
- **Commit/PR:** -
```

---

## MOB-001 — Hitung Premium dari waktu server

- **Status:** BLOCKED
- **Prioritas:** P0
- **Diminta:** 01/11/2026 (AY)
- **Latar belakang:** audit M-02. Kedaluwarsa Premium masih dihitung dari jam HP.
- **Terhambat oleh:** BE-001 di `BACKEND_TASKS.md`.
- **Kriteria selesai:** `premiumNow` memakai selisih waktu server, memundurkan jam HP tidak memperpanjang Premium, dan masa cache offline dibatasi.
- **Commit/PR:** -

## MOB-002 — Enkripsi cache `/me`

- **Status:** TODO
- **Prioritas:** P0
- **Diminta:** 01/11/2026 (AY)
- **Latar belakang:** audit M-02. Cache `/me` tersimpan polos di SharedPreferences.
- **Kriteria selesai:** cache terenkripsi, data lama dimigrasikan atau dibersihkan, dan ada tesnya.
- **Commit/PR:** -

## MOB-003 — Cek ulang nomor layanan krisis

- **Status:** TODO
- **Prioritas:** P0
- **Diminta:** 01/11/2026 (AY)
- **Latar belakang:** nomor di `crisis_directory.dart` belum dicek ke situs resmi tiap layanan.
- **Kriteria selesai:** semua nomor cocok dengan situs resmi, dan nomor yang tidak terverifikasi dihapus sehingga negara itu memakai cadangan.
- **Commit/PR:** -

## MOB-004 — Uji pembayaran App Store di iPhone

- **Status:** BLOCKED
- **Prioritas:** P0 untuk rilis iOS
- **Diminta:** 01/11/2026 (AY)
- **Latar belakang:** kode App Store dari `c2486c6` baru lolos tes otomatis.
- **Terhambat oleh:** BE-003 di `BACKEND_TASKS.md`.
- **Kriteria selesai:** pembelian koin, langganan, dan pulihkan pembelian lolos di sandbox iPhone.
- **Commit/PR:** -
