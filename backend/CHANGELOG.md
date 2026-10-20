# Changelog — backend Riung

Semua perubahan backend Go (`backend/`) yang perlu diketahui tim app dan operator. Versi = tag image
yang di-deploy ke produksi (`ghcr.io/krisna-achmad31/riung-api:<sha>`, `riung version`), terbaru di atas.
API `/v1` hanya berubah secara **aditif** — field baru boleh muncul kapan saja, field lama tidak dihapus.

Kategori: **Ditambahkan** · **Diubah** · **Diperbaiki** · **Keamanan** · **Untuk tim app** (yang perlu
diubah di Flutter).

---

## [Belum dirilis]

### Operasional
- **Staging** `riung-staging.e55techlab.com` (runbook §H): `docker-compose.staging.yml` dengan Postgres sendiri,
  login & billing palsu, akses hanya dengan header `X-Riung-Staging-Key`; `deploy.sh` menerima
  `RIUNG_COMPOSE_FILE`/`RIUNG_CONTAINER` (default = produksi); forced command `check|deploy … staging`; CI deploy
  staging tiap push ke `feat/go-backend` bila `vars.RIUNG_STAGING_ENABLED` atau `deploy_staging` ✓.
- Postman: environment `riung-staging` dan header kunci staging otomatis.

---

## [25e4266] — 2026-10-20 · produksi (alarm, watchdog, dashboard)

### Ditambahkan
- Alarm Telegram dari aplikasi (`ALERT_TELEGRAM_*`): log ERROR, `refund_applied`, pesan saat API start; dedupe
  10 menit, maks 30/jam. `riung alert-test`.
- `riung watchdog` + `deploy/monitoring/riung-watchdog.sh` (cron host tiap 2 menit): API, 5xx/p95 dari Loki, job
  cron, umur backup; alarm, pengingat 6 jam, pesan pulih.
- Migrasi `00004`: view agregat `metrics.*` untuk dashboard bisnis; role baca-saja `riung_metrics`
  (`deploy/sql/create-riung-metrics-role.sql`). Dashboard Grafana Riung — Teknis & Riung — Bisnis
  (`deploy/monitoring/dashboards.py`).

### Diperbaiki
- Notifikasi App Store tanpa objek `data` (mis. ringkasan `RENEWAL_EXTENSION`) dicatat `action=no_data`, bukan
  `other_bundle`. Hanya label log.

---

## [c43f374] — 2026-10-20 · produksi (App Store **aktif**)

### Operasional
- `APPSTORE_*` terisi (bundle `id.riung.riung`, key `6M37Z83MZ5`, app `6824618033`); key di
  `secrets/appstore-iap-key.p8`. Log start `"appStore":true`. Notifikasi TEST sandbox dari Apple diterima dan
  lolos verifikasi JWS (200, `kind=test`). Google Play masih mati.

### Ditambahkan
- `riung appstore-check [--notify]`: menguji In-App Purchase key ke Apple (sandbox wajib lolos; production `401`
  sampai app rilis = WARN) dan, dengan `--notify`, meminta Apple mengirim notifikasi TEST ke webhook lalu
  melaporkan hasil pengirimannya.

### Diperbaiki
- Verifikasi App Store: production App Store Server API menjawab `401` sampai app rilis pertama (diuji
  2026-10-20 dengan key asli; sandbox menerima key yang sama). `401` production kini diteruskan ke sandbox —
  tanpa ini pembelian TestFlight & App Review gagal `500`.

### Diubah
- Bundle id iOS = `id.riung.riung` (Apple Developer); `DEV_BILLING` memakainya sebagai default
  `APPSTORE_BUNDLE_ID`. Android tetap `com.riung.riung`. Produksi tidak berubah (App Store masih mati).

---

## [6d05579] — 2026-10-20 · produksi (App Store disiapkan, masih mati)

### Ditambahkan
- **App Store (iOS)** — siap, **mati** sampai `APPSTORE_*` diisi (runbook 4d, spec §3.9b):
  `POST /v1/billing/appstore/verify` dan `/restore` (`{productId, transactionId}`, hasil sama dengan Play; server
  mengambil transaksi dari App Store Server API, production lalu sandbox), `POST /v1/webhooks/app-store`
  (Server Notifications V2: refund/revoke paket koin menarik koin, notifikasi langganan membaca ulang status dari
  Apple). Semua JWS Apple diverifikasi sampai Apple Root CA - G3 yang tertanam. Tanpa migrasi DB.
- `GET /v1/me` → `user.appAccountToken` (UUID) untuk `applicationUserName` di iOS.
- Login Sign in with Apple (`apple.com`) didukung juga di `DEV_AUTH`; `DEV_BILLING` ikut memalsukan App Store.
- Postman: folder *6b. App Store billing (iOS)* (verify koin & langganan, restore dengan tes `transactionId`);
  **Me** menyimpan `appAccountToken`. 55 request, 72 assertion.

### Diperbaiki
- Tes `TestAppBekuEthicalGuard` dan `TestFocusFreeTicketLifecycle` tidak lagi gagal bila CI berjalan dekat
  tengah malam WIB (17:00 UTC); batas harian sendiri memang di-reset pada tengah malam waktu user.

### Untuk tim app
- iOS: panduan §11.6 (`appAccountToken`, `transactionId` = `purchaseID`, `completePurchase` setelah server).

---

## [6f3a51a] — 2026-10-19 · produksi (deploy pertama lewat CI)

### Diperbaiki
- `riung api` menunggu Postgres sampai 60 detik saat start (coba ulang 0,5 → 5 detik, log WARN `database not
  ready, retrying`). Sebelumnya API langsung keluar dengan ERROR bila `shared-postgres` belum siap, seperti
  saat VPS reboot 2026-10-17 (4 restart). Job cron & perintah admin tetap mencoba sekali.

### Keamanan
- Kunci verifikasi PIN jurnal (`pin_locked`, 1 jam setelah 10 gagal) kini tetap berlaku melewati tengah malam
  UTC. Sebelumnya kunci dicari per hari, jadi user yang terkunci pukul 23:50 UTC mendapat 10 percobaan baru
  pukul 00:00 (rate limit 5/15 menit tetap berlaku). Tes yang sesekali gagal di CI dekat tengah malam UTC
  (`TestJournalPinBackup`) kini deterministik.

### Operasional
- Deploy lewat GitHub Actions: setiap push ke `main`/`feat/go-backend` mem-push image `:<sha 7>` ke GHCR;
  deploy = *Run workflow* dengan `deploy` ✓, lewat user `deploy` di VPS (tanpa password, kunci CI dibatasi
  forced command `riung-ci-deploy`), lalu smoke test. Deploy berhenti bila `deploy.sh`/compose di VPS beda
  dengan commit. Tag image dan `riung version` = sha 7 karakter. Rollback = *Run workflow* dengan `rollback_tag`
  (image dari GHCR, tanpa build; image lokal di VPS dihapus cron prune setelah 24 jam).
- Loki menyimpan log `riung-api`/`riung-migrate` 30 hari (sebelumnya 7).

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
