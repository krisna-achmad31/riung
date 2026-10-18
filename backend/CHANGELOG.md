# Changelog — backend Riung

Semua perubahan backend Go (`backend/`) yang perlu diketahui tim app dan operator. Versi = tag image
yang di-deploy ke produksi (`ghcr.io/krisna-achmad31/riung-api:<sha>`, `riung version`), terbaru di atas.
API `/v1` hanya berubah secara **aditif** — field baru boleh muncul kapan saja, field lama tidak dihapus.

Kategori: **Ditambahkan** · **Diubah** · **Diperbaiki** · **Keamanan** · **Untuk tim app** (yang perlu
diubah di Flutter).

---

## [Belum dirilis]

### Diubah
- Postman collection (`backend/postman/`): request *Verifikasi* menyimpan `coinToken`/`subToken`, lalu
  **Restore** mengirim ulang keduanya ditambah satu token akun lain. Restore dites: satu baris per pembelian,
  urutan sama, `purchaseToken` di setiap baris, tanpa koin dobel, `purchase_invalid`. Folder billing & hapus
  akun mengikuti perilaku sekarang (webhook `404` selama billing mati, peringatan `premium.autoRenewing`).
  52 request, 64 assertion. Tidak mengubah API.

---

## [92ef4ed] — 2026-10-18 · produksi

### Ditambahkan
- `POST /v1/billing/restore`: setiap baris `results` membawa `purchaseToken` (urutan baris tetap sama
  dengan request). (`7b1bd12`)

### Untuk tim app
- Cocokkan hasil restore dengan `purchaseToken`, bukan posisi baris. Kode lama yang memakai urutan tetap
  benar sampai diganti.

---

## [81f763f] — 2026-10-13 · produksi

### Diubah
- `POST /v1/webhooks/google-play` menjawab `404` selama billing Google Play belum dikonfigurasi (sebelumnya
  `503`). Saat billing aktif perilakunya tidak berubah.
- `riung admin grant|revoke dev:<uid> <alasan>` bisa dipakai di stack lokal (`DEV_AUTH`); tetap tertutup di
  produksi. (`42a913b`)

### Ditambahkan
- Postman collection di `backend/postman/` (52 request, environment lokal & produksi). (`42a913b`)
- Tes: `Idempotency-Key` yang sama tetap bisa dipakai setelah `429`; batch outbox yang dikirim ulang dengan
  key baru dijawab `replayed` tanpa koin dobel.

### Diperbaiki
- `GET /admin/v1/audit` tidak lagi meng-*encode* daftar dua kali dengan error diabaikan. (`7fe3d50`)

### Keamanan
- Endpoint webhook publik tidak lagi menghasilkan `5xx`/log ERROR untuk siapa pun selama billing mati
  (sebelumnya bisa dipakai membanjiri log dan memicu alert error server).

---

## [e5f0110] — 2026-10-13 · produksi (B6: kesiapan produksi)

### Diubah
- Cek pencabutan token Firebase (panggilan ke Firebase) kini berjalan **setelah** rate limit, jadi request di
  atas batas tidak pernah sampai ke Firebase.
- Mode App Check `monitor` juga mencatat pemakaian ulang token limited-use (`jti`), tanpa menolak.

### Ditambahkan
- Field `appCheck` di access log (`valid`, `missing`, `invalid`, `replayed`, `unavailable`) — dasar keputusan
  pindah ke `enforce` (`docs/backend-b6-review.md` §4).
- Header `Content-Security-Policy: default-src 'none'; frame-ancestors 'none'` di semua respons API.
- 12 aturan alert Grafana untuk Loki (`deploy/monitoring/grafana-alerting-riung.yml`, belum dipasang).
- Uji beban k6 (`loadtest/`): p95 11,9 ms di 200 pengguna aktif (84 req/s), 9 ms di 400.

### Keamanan
- nginx: TLS 1.2 hanya suite AEAD (Mozilla intermediate); header keamanan tidak lagi terkirim ganda.

---

## [825085e] — 2026-10-13 · produksi (rilis pertama, B0–B5)

Rilis pertama `https://riung.e55techlab.com`. Migrasi database `00001`–`00003`.

### Ditambahkan — API (`docs/backend-api-spec.md`)
- **Akun**: `GET /v1/me` (bootstrap, akun dibuat otomatis termasuk anonim, `billingAccountId`), profil,
  ringkasan asesmen, tautkan akun anonim, hapus akun (ikut menghapus user Firebase), ekspor data, backup PIN
  jurnal dengan lockout.
- **Konten & konfigurasi**: `GET /v1/config` (ekonomi, katalog berharga, `minAppVersion`, kunci tiket Fokus,
  ETag), `GET /v1/content/{kind}`, `POST /v1/waitlist`.
- **Latihan**: `POST /v1/activities` & `/batch` (check-in + streak + pelindung, jurnal, meditasi, Better Me,
  misi, minigame, Fokus selesai, jinak +50); batas harian dijawab `200 capped`.
- **Ekonomi**: wallet berbasis ledger (koin latihan/beli, utang refund), riwayat transaksi, koin harian
  Premium tahunan, toko (kosmetik, bundel, pelindung streak, paket Fokus), loadout monster & karakter.
- **Mode Fokus**: tiket Ed25519 (`free_daily` 1/hari · Premium 3, `prepaid`, `coins`) untuk sesi offline;
  penukaran sekali, tidak bisa "selesai" sebelum durasinya, tidak boleh tumpang tindih.
- **Aplikasi Beku**: buka-waktu berbayar hanya koin latihan, maks 3/hari, +10 tiap kali, jeda 60 detik,
  bundel `santai`/`sosmed` atomik; aplikasi yang dibuka tidak disimpan/dicatat.
- **Google Play**: `/v1/billing/verify`, `/restore`, `/subscription`, webhook RTDN (Pub/Sub OIDC); refund
  menarik koin (sisanya jadi utang), Premium dari `subscriptionsv2`. Belum aktif di produksi (butuh setup
  Play Console & Pub/Sub).
- **Admin API** (port 8081, hanya via VPN): batas koin jurnal/meditasi & batas akun baru per IP, diaudit.

### Ditambahkan — operasional
- Satu binary `riung`: `api`, `migrate`, `seed-content`, `settings`, `admin`, `cleanup`, `cleanup-anon`,
  `billing-sync`, `reconcile`, `reapply-deletions`, `healthcheck`, `version`.
- Cron di VPS: pembersihan harian, hapus akun anonim tak aktif > 90 hari, sinkron billing tiap jam,
  rekonsiliasi saldo vs ledger, backup `pg_dump` 14 hari. `LOG_TEE` supaya log job masuk Loki.
- Docker distroless (read-only, nonroot), compose produksi di `vps-shared-net`, nginx + TLS, `deploy.sh`
  (pull/muat image → migrasi → ganti container → tunggu healthy), CI (tes + race, lint, govulncheck, Trivy),
  Dependabot.

### Keamanan
- Verifikasi ID token Firebase + App Check (`monitor`), rate limit per user/IP per endpoint, `Idempotency-Key`
  untuk semua mutasi, decoder JSON ketat, batas body per route, IP asli hanya dari `shared-nginx`.
- Role database `riung_app` tanpa DDL; ledger & audit append-only; pembelian hanya bisa diubah kolom statusnya.
- Log tanpa PII: user & IP di-*hash*, token pembelian hanya 6 karakter terakhir, isi jurnal/check-in tidak
  pernah diterima server.
