# Backend Tasks — Riung

Daftar pekerjaan yang **dibutuhkan** dari backend. Mobile atau design, termasuk AI-nya, menulis permintaan untuk backend di sini, dan permintaan backend ke tim lain ditulis di `MOBILE_TASKS.md` atau `DESIGN_TASKS.md`. Perubahan yang sudah selesai dicatat di `CHANGELOG.md` (app) dan `backend/CHANGELOG.md` (backend).

## Aturan untuk AI dan developer BE

1. Baca file ini sebelum mengerjakan backend. Ambil tugas `TODO` dengan prioritas tertinggi yang tidak `BLOCKED`.
2. Saat mulai, ubah status menjadi `IN_PROGRESS`. Saat selesai, ubah menjadi `DONE` dan isi commit atau PR.
3. Satu tugas harus memenuhi semua kriteria selesai dan tesnya lolos.
4. Jangan menghapus tugas. Tugas `DONE` tetap di sini sampai app memakainya.
5. Jika butuh keputusan pemilik produk, ubah status menjadi `BLOCKED` dan tulis pertanyaannya.

Status: `TODO` · `IN_PROGRESS` · `BLOCKED` · `DONE`
Prioritas: `P0` wajib sebelum rilis · `P1` penting · `P2` boleh menyusul

---

## BE-001 — Kirim waktu server di `/v1/me`

- **Status:** TODO
- **Prioritas:** P0
- **Diminta:** 01/11/2026 (AY)
- **Latar belakang:** audit M-02. Kedaluwarsa Premium masih dihitung dari jam HP, jadi memundurkan jam bisa memperpanjang Premium. `serverTime` baru ada di `backend/internal/api/public.go`, dan belum ditemukan di respons `/me`.
- **Kriteria selesai:**
  - Respons `/v1/me` berisi `serverTime` UTC (`s.now().UTC()`).
  - Kontrak di `docs/backend-api-spec.md` dan `docs/panduan-integrasi-app.md` diperbarui.
  - Ada tes API untuk field ini.
- **Lanjutan di app:** hitung `premiumNow` dari selisih waktu server dan batasi masa cache offline.
- **Commit/PR:** -

## BE-002 — Buang pengenal pembayaran dari `/v1/me/export`

- **Status:** TODO
- **Prioritas:** P1
- **Diminta:** 01/11/2026 (AY)
- **Latar belakang:** berkas ekspor bisa tersalin ke mana saja. App sudah membuang `billingAccountId` dan `appAccountToken`, tetapi server belum dipastikan bersih.
- **Kriteria selesai:**
  - Audit seluruh isi `/v1/me/export`: tidak ada token, secret, atau pengenal pembayaran internal.
  - Tes memastikan `billingAccountId` dan `appAccountToken` tidak ada di respons ekspor.
  - **Jangan** menghapus keduanya dari `/v1/me`, karena dipakai saat pembelian.
- **Commit/PR:** -

## BE-003 — Aktifkan App Store di produksi

- **Status:** BLOCKED
- **Prioritas:** P0 untuk rilis iOS
- **Diminta:** 01/11/2026 (AY)
- **Latar belakang:** App sudah mendukung App Store (`c2486c6`), tetapi di produksi layanan ini mati sampai `APPSTORE_*` diisi.
- **Terhambat oleh:** tanggal rilis iOS dan pengujian pembelian sandbox di iPhone.
- **Kriteria selesai:**
  - `APPSTORE_BUNDLE_ID`, `APPSTORE_ISSUER_ID`, `APPSTORE_KEY_ID`, `APPSTORE_PRIVATE_KEY_FILE`, dan `APPSTORE_APP_APPLE_ID` terisi di produksi.
  - Pembelian koin, langganan, dan pulihkan pembelian lolos di sandbox.
  - Webhook App Store diterima.
- **Commit/PR:** -

## BE-004 — Sediakan server dev

- **Status:** BLOCKED
- **Prioritas:** P2
- **Diminta:** 01/11/2026 (AY)
- **Latar belakang:** saat ini hanya ada produksi dan backend lokal. Mode dev app masih menuju `http://10.0.2.2:8080`.
- **Terhambat oleh:** keputusan apakah server dev dibutuhkan, dan alamatnya.
- **Kriteria selesai:**
  - Server dev aktif dengan database terpisah dari produksi.
  - Google Play dan App Store memakai mode uji.
  - `AppData.baseUrlDev` diganti ke alamat itu.
- **Commit/PR:** -
