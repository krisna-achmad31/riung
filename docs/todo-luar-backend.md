# TODO di luar backend
*Dikumpulkan selama perencanaan & audit backend Go (branch `feat/go-backend`, 2026-10-11).*

Backend dikerjakan sesuai `docs/backend-go-plan.md` dan `docs/backend-api-spec.md`. Daftar ini berisi
pekerjaan **di luar** `backend/` yang dibutuhkan supaya backend benar-benar terpakai, ditambah celah yang
ditemukan di app/infra. Backend sudah dirancang mengikuti perilaku yang benar; item di sini adalah sisi
lain yang perlu menyusul.

Prioritas: **P0** = keamanan / wajib sebelum rilis · **P1** = wajib untuk cutover ke backend · **P2** = perbaikan.

---

## A. Infra & akses (VPS `76.13.20.72`, Firebase/Google Cloud, GitHub)

- [ ] **P0 — Ganti password root VPS.** Password root sempat dibagikan di chat perencanaan.
- [ ] **P0 — Pengerasan SSH**: buat user `deploy` (key-only, grup `docker`) untuk CI; set
      `PermitRootLogin prohibit-password` dan `PasswordAuthentication no`. Perhatikan
      `/etc/ssh/sshd_config.d/50-cloud-init.conf` saat ini menimpa jadi `PasswordAuthentication yes`.
      Pertimbangkan menutup port 22 bila SSH cukup lewat 8443.
- [ ] **P0 — Rotasi key `firebase-adminsdk`** (`riung-5e979-firebase-adminsdk-…json`). File sempat
      tersimpan di `~/Downloads` dengan izin `-rw-r--r--`. Setelah itu buat **service account khusus**
      backend dengan peran minimum: Firebase Authentication Admin + akses Android Publisher (ditautkan di
      Play Console → *API access*).
- [ ] **P0 — Backup Postgres**: cron harian `pg_dump -Fc` database `riung` (dan `n8n`, yang saat ini juga
      tanpa backup) ke `/var/backups/…`, retensi 14 hari, salin off-site, uji restore.
- [ ] **P1 — DNS Cloudflare**: `A riung → 76.13.20.72`, mode **DNS only**.
- [ ] **P1 — Database**: jalankan `backend/deploy/sql/create-riung-db.sql` di `shared-postgres`
      (membuat DB `riung`, role `riung_migrator` & `riung_app`), simpan password di `/var/www/riung/.env`.
- [ ] **P1 — Nginx + TLS**: pasang `backend/deploy/nginx/riung.e55techlab.com.conf` ke
      `core-shared/nginx/conf.d/` mengikuti urutan HTTP-only → certbot → config final (plan §8.4).
      Selalu `nginx -t` sebelum reload — satu nginx dipakai semua situs.
- [ ] **P1 — Loki**: tambahkan `retention_stream` 30 hari untuk `{container="riung-api"}` di
      `core-shared/monitoring/loki/config.yml` (snippet di spec §6.5), dan stage `json` di Promtail
      (label hanya `level`, `event`).
- [ ] **P1 — Dokumentasi core-shared** (commit ke branch `grafana`): IP `172.19.0.16`/`.17` dipakai
      `riung-api`/`riung-migrate`, `shared-postgres` dipakai "n8n + riung", domain baru di tabel nginx.
- [ ] **P1 — GHCR**: `docker login ghcr.io` di VPS dengan token **read-only**; secret GitHub Actions untuk
      deploy (host, port 8443, user `deploy`, private key).
- [ ] **P1 — Google Play RTDN**: buat topic Pub/Sub + push subscription ke
      `https://riung.e55techlab.com/v1/webhooks/google-play` dengan autentikasi OIDC (service account
      khusus), lalu isi `RTDN_AUDIENCE`.
- [ ] **P1 — Firebase App Check**: aktifkan provider Play Integrity untuk app Android.
- [ ] **P1 — Isi konten**: setelah deploy, `docker exec -i riung-api /riung seed-content - < dummy-data-seed.json`.
- [ ] **P1 — Admin**: tentukan email admin; pastikan admin punya akses VPN OpenVPN; jalankan
      `riung admin grant --email …` setelah deploy.
- [ ] **P2 — Grafana**: kontak notifikasi (email tim) untuk alert di spec §6.6.
- [ ] **P2 — CI Flutter**: tambahkan `paths-ignore: ['backend/**']` di
      `.github/workflows/firebase_app_distribution.yml` supaya perubahan backend tidak memicu build APK.

## B. App Flutter (`riung/`) — integrasi backend (P1)

- [ ] `ApiClient` (`lib/core/services/api/`): base URL, ID token, App Check token, `Idempotency-Key`,
      retry, pemetaan error `code` → strings (CLAUDE.md aturan #2). Paket baru: `http`, `firebase_app_check`
      (termasuk `getLimitedUseToken` untuk `billing/verify`, `DELETE /me`, verifikasi PIN).
- [ ] `ApiUserRepository`, `ApiContentRepository`, pemilihan lewat `--dart-define=BACKEND=go`.
- [ ] Hapus `HybridWalletFunctionsService` dan routing "anonim → lokal": akun anonim langsung memakai API.
- [ ] `WalletFunctionsService` → aksi typed (`postActivity(type, ref)`, `purchase(itemType, itemId,
      expectedPrice)`); app berhenti mengirim nominal koin.
- [ ] `WalletNotifier`: inventori, sesi prabayar, pelindung streak, cadangan koin-beli, klaim harian
      tahunan, misi hari ini → dari `GET /v1/me`, bukan `LocalPrefsStore`.
- [ ] `AuthNotifier._linkAndMigrate` → `POST /v1/me/link` (hapus `migrateAnonymousSnapshot`).
- [ ] Outbox offline untuk `POST /v1/activities/batch` (idempotency key per event).
- [ ] `BillingService`: `applicationUserName` = `billingAccountId` dari `/v1/me`; panggil
      `/v1/billing/verify` & `/v1/billing/restore`; `completePurchase` hanya setelah server sukses; berhenti
      mengkredit koin/Premium dari perangkat.
- [ ] Tiket Fokus bertanda tangan disimpan terenkripsi di perangkat; ambil tiket `free_daily` saat online.
- [ ] Harga & batas dari `GET /v1/config` (cache + fallback `economy.dart`); hapus key ekonomi dari
      Remote Config.
- [ ] `JurnalHomeScreen` / `JurnalPromptScreen`: cek boleh menulis & prompt premium lewat
      `GET /v1/journal/access` (hitungan lokal `journalEntryCountForDate` tetap jadi cadangan saat offline).
- [ ] Pemulihan PIN jurnal memakai `POST /v1/me/journal-pin-backup/verify` (bukan membandingkan hash di HP).
- [ ] Tampilkan `requestId` di pesan error ("Kode: …") dan kirim sebagai custom key Crashlytics.
- [ ] Teks baru untuk error: `signup_limited`, `price_changed`, `pin_locked`, `limit_reached`, `cooldown`,
      `upgrade_required`, `recent_login_required` (minta login ulang sebelum hapus akun),
      `request_in_progress`, `rate_limited` (pakai `details.retryAfterSeconds`) — Bahasa Indonesia & Inggris.
- [ ] `Idempotency-Key`: satu UUID baru per aksi pengguna; pakai ulang hanya saat me-retry error jaringan/5xx.
      Setelah 4xx (mis. `insufficient_coins`), aksi berikutnya pakai key baru.
- [ ] Kirim header `X-App-Version` (mis. `1.0.0+1`) dan `X-Platform: android` di setiap request — dipakai
      untuk `minAppVersion` dan log.
- [ ] Panggil `GET /v1/me` saat app dibuka (akun dibuat otomatis, termasuk anonim); hapus akun lewat
      `DELETE /v1/me` (server ikut menghapus akun Firebase).
- [ ] Tes parity `test/economy_parity_test.dart`: `economy.dart` == `docs/economy-props.json`, dan katalog
      app (`toko_data.dart`, `character_accessory.dart`, `card_style.dart`, `meditation_catalog.dart`,
      `journal_prompts.dart`, `betterme_content.dart`) == `docs/catalog.json`.
- [ ] Toko & loadout lewat server: `POST /v1/shop/purchase` (`itemId` = id inventori, mis. `acc_beanie`,
      `cardstyle_taman`; kirim `expectedPrice` dari `/v1/config`), `PUT /v1/loadouts/...`; tangani `not_owned`,
      `already_owned`, `price_changed`, `insufficient_coins` (`details.shortfall` → tawarkan latihan dulu).
- [ ] Laporan latihan lewat `POST /v1/activities` / `/batch`: kirim `promptId` untuk jurnal ber-prompt;
      tampilkan `capReason` dengan nada ramah (batas harian bukan kegagalan).
- [ ] `CLAUDE.md`: tambahkan rujukan `docs/catalog.json` sebagai sumber katalog item (selain economy-props.json).
- [ ] Setelah cutover: `firestore.rules` → deny-all (kecuali yang masih dipakai), hapus kode Firestore
      user/wallet, update `CLAUDE.md` aturan #5/#6, `docs/firebase-architecture.md`, `docs/setup-firebase.md`.

## C. App Flutter — celah & bug yang ditemukan (P2, sebagian jadi P1 saat integrasi)

- [ ] **Bundel "Sesi santai" Aplikasi Beku tidak atomik** (`appbeku_toko_section.dart`): menit Instagram
      dibuka gratis dulu, koin baru dipotong di langkah TikTok; kalau langkah kedua gagal, Instagram tetap
      terbuka gratis. Backend memproses bundel atomik — app cukup memanggil satu request bundel.
- [ ] **Progres Fokus selalu ke `waswas`** (`sesi_selesai_screen.dart` hardcode) — kirim monster yang
      sedang dijinakkan sebagai `saboteurId`.
- [ ] **Bonus streak 7/30 hari (+20/+100)** ada di `economy.dart` tapi tidak pernah diberikan. Backend
      memberikannya di event `checkin` — app perlu menampilkannya.
- [ ] **Pelindung streak** bisa dibeli tapi tidak pernah dipakai. Backend memakainya otomatis saat satu hari
      bolong — app perlu menampilkan status pelindung terpakai.
- [ ] **`EconomySpend.tiketTambahan` (30 koin)** tidak dipakai di mana pun dan bertentangan dengan aturan
      "tiket tidak dijual" — hapus dari `economy.dart` & `remote_config_defaults.json`.
- [ ] **Landing** `landing/public/waitlist.js` → `POST /v1/waitlist` (bukan Firestore). Body `{email, lang,
      source}` + field honeypot `website` yang disembunyikan (harus kosong). Isi `CORS_LANDING_ORIGIN` di
      server dengan domain landing.

## D. Keputusan produk yang belum final

Backend memakai default di kolom kanan sampai diputuskan lain.

| Pertanyaan | Default backend |
|---|---|
| Sesi Fokus gratis & prabayar dibatasi durasi 25 menit, atau durasi apa pun seperti app sekarang? | durasi apa pun (mengikuti app) |
| Jurnal/meditasi di atas batas harian: tanpa koin saja, atau tanpa koin **dan** tanpa progres monster? | tanpa koin & tanpa progres |
| Nilai awal `journalRewardsPerDay` / `meditationRewardsPerDay` | 3 / 3 (bisa diubah admin) |
| Jendela laporan offline: 7 hari (sekarang) atau 72 jam (lebih ketat terhadap client yang dimodifikasi)? | 7 hari |
