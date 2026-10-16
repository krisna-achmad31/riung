# Changelog — Riung

Semua perubahan penting dicatat di sini. Format mengikuti [Keep a Changelog](https://keepachangelog.com/id-ID/1.1.0/).

**Aturan versi:** judul tiap rilis = `version` di [`riung/pubspec.yaml`](riung/pubspec.yaml) (`MAJOR.MINOR.PATCH+BUILD`). Setiap perubahan yang di-merge wajib:
1. naikkan `version` di pubspec (PATCH untuk perbaikan, MINOR untuk fitur, `+BUILD` selalu naik 1 — dipakai sebagai `versionCode` Play Store);
2. tambah entri baru di atas dengan versi yang sama, tanggal, committer, dan commit terkait.

Kategori: **Ditambahkan** (fitur baru) · **Diubah** · **Diperbaiki** · **Keamanan** · **Desain** (frame di `design/riung.pen`).

---

## [1.0.1+2] — 2026-10-17

**Committer:** Achmad Yukrisna · **Branch:** `fix/audit-hardening` · **Commit:** `26a7a0f`, `f27871d`, + commit rilis ini

### Keamanan
- Backup Android dimatikan (`allowBackup=false`, `data_extraction_rules.xml`) supaya jurnal, check-in, dan hasil tes tidak ikut ke cloud backup/transfer perangkat.
- Build rilis menolak berjalan dengan `StubAuthService` (penjaga di `main.dart`).
- Input teks (nama, jurnal, cerita onboarding, catatan check-in, afirmasi, refleksi Better Me, edit profil) dibatasi panjangnya dan dibersihkan dari karakter kontrol/bidi (`core/config/input_limits.dart`).

### Diperbaiki
- Pengguna baru tidak lagi diisi data dummy; profil, dompet, dan monster mulai kosong.
- Zona waktu notifikasi & tanggal check-in mengikuti perangkat (`DeviceTimeZone`: WIB/WITA/WIT, IANA, lalu `Etc/GMT`), tidak lagi dipaku WIB; zona dikirim ke server saat berbeda.
- Billing: kegagalan inisialisasi/kueri/stream tidak lagi diam — dilaporkan ke Crashlytics dan dikembalikan sebagai error ke UI; pulihkan pembelian dijalankan per 20 item dengan satu kali coba ulang, pembelian yang belum terverifikasi tidak dikonsumsi.
- Toko: langganan stream billing dilepas saat layar ditutup.
- Outbox: event yang sudah gagal 10 kali dibuang agar antrean tidak macet; retry API dibatasi maksimal 5.
- Gambar monster & karakter yang hilang tidak lagi membuat layar crash (`errorBuilder`).

### Ditambahkan
- Tes render `RiungMonster` (bossScale, slot `none`, `anchorsLiar`, rotasi, zIndex, semua kombinasi), tes terjemahan Kenali Dirimu, tes zona waktu, tes outbox/retry.
- Skrip bantu di root repo untuk eksplorasi `riung.pen` & pembersihan aset 3D (`26a7a0f`).

### Desain
- Frame baru **Glass — Monster · Latihan Si Nanti (node)** di `design/riung.pen` untuk `HabitPracticeScreen` (sebelumnya satu-satunya layar tanpa frame Glass).

---

## [1.0.0+1] — 2026-10-17

**Committer:** Achmad Yukrisna · **Branch:** `implement_and_integrations_api` → `dev` · **Commit:** `c95887a`, merge `a30df4b`

### Ditambahkan
- Integrasi REST API Riung: `ApiClient`, `ApiState`, repositori pengguna/konten, dan layanan dompet lewat server.
- Outbox SQLite untuk aktivitas offline yang disinkronkan per batch.
- Draf asesmen yang bisa dilanjutkan.

Riwayat sebelum 1.0.0 (aplikasi awal, desain Riung Glass, aset 3D, ikon, CI) ada di `git log`.
