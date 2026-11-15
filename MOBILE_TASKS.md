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

## MOB-005 — Konsistenkan gerbang Premium BetterMe, Kenali, Kepribadian

- **Status:** TODO
- **Prioritas:** P1
- **Diminta:** 15/11/2026 (QA)
- **Latar belakang:** BetterMe: level_intro/sesi_detail/sesi_content tanpa cek Premium; saboteur_detail:49 & hakim_detail:175 selalu push level 1. Kenali: hub tampil terbuka untuk hasil lama, quiz paywall; retake pushReplacement → hasil hilang. Kepribadian: tile terkunci tetap push quiz (hub:35).
- **Kriteria selesai:** Semua pintu masuk konten Premium memakai satu cek; user gratis tidak masuk konten Premium lewat jalur samping; retake tidak menghapus hasil.
- **Commit/PR:** -

## MOB-006 — Sambungkan layar yatim Home & Tidur

- **Status:** TODO
- **Prioritas:** P2
- **Diminta:** 15/11/2026 (QA)
- **Latar belakang:** `beranda_tiket_serangan_screen.dart` & `tidur_laporan_pagi_screen.dart` ada di desain tapi tak pernah dibuka; `tryTonightStory` cuma maybePop.
- **Kriteria selesai:** Kedua layar terjangkau sesuai alur `.dc.html`, atau dihapus bila desain berubah.
- **Commit/PR:** -

## MOB-007 — Tombol Unduh & state offline meditasi/tidur

- **Status:** TODO
- **Prioritas:** P2
- **Diminta:** 15/11/2026 (QA)
- **Latar belakang:** Unduh (`meditasi_detail:71`, `tidur_detail:66`) cuma snackbar; error audio ditelan dan timer tetap jalan (`meditasi_player:54`, `tidur_player:55`).
- **Kriteria selesai:** Unduh nyata atau tombol disembunyikan; layar "Meditasi offline" tampil saat audio gagal.
- **Commit/PR:** -

## MOB-008 — Rapikan navigasi pasca-sesi

- **Status:** TODO
- **Prioritas:** P2
- **Diminta:** 15/11/2026 (QA)
- **Latar belakang:** `meditasi_selesai:91` Ulangi balik ke Detail; `betterme_sesi_selesai:83` pop ganda; `betterme_milestone:106` popUntil(isFirst); `minigame_daily_cap:66` cara dapat tiket tak bisa ditap; `koin_kurang:120` pushReplacement hilangkan result; `focus_mode_entry:47` tanpa back.
- **Kriteria selesai:** Tiap tombol mendarat di layar yang benar tanpa asumsi stack.
- **Commit/PR:** -

## MOB-009 — Error state & busy guard yang tersisa

- **Status:** TODO
- **Prioritas:** P2
- **Diminta:** 15/11/2026 (QA)
- **Latar belakang:** `lemari_screen:50` simpan loadout tanpa try/busy; pengingat afirmasi/tidur `_simpan` tanpa error; favorit afirmasi tanpa rollback; `laporan_screen:55` gagal Health Connect menimpa laporan; LOW lain di `docs/qa-report-2026-11.md`.
- **Kriteria selesai:** Semua aksi tulis punya busy guard & pesan error; tes widget untuk yang P2.
- **Commit/PR:** -

## MOB-010 — Sapaan check-in saat nama kosong & hex literal

- **Status:** TODO
- **Prioritas:** P2
- **Diminta:** 15/11/2026 (QA)
- **Latar belakang:** "Pagi, . Gimana…" untuk user tanpa nama (D3). Hex literal di `rate_us_step.dart:144-150,242`, `card_background_painter.dart:23`.
- **Kriteria selesai:** Sapaan tanpa nama terbaca wajar; warna dari `core/theme`.
- **Commit/PR:** -
