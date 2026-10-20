# TODO di luar backend
*Dikumpulkan selama perencanaan & audit backend Go (branch `feat/go-backend`, 2026-10-11, diperbarui 2026-10-20).*

Backend dikerjakan sesuai `docs/backend-go-plan.md` dan `docs/backend-api-spec.md`. Daftar ini berisi
pekerjaan **di luar** `backend/` yang dibutuhkan supaya backend benar-benar terpakai, ditambah celah yang
ditemukan di app/infra. Backend sudah dirancang mengikuti perilaku yang benar; item di sini adalah sisi
lain yang perlu menyusul.

Prioritas: **P0** = keamanan / wajib sebelum rilis · **P1** = wajib untuk cutover ke backend · **P2** = perbaikan.

---

## A. Infra & akses (VPS `76.13.20.72`, Firebase/Google Cloud, GitHub)

- [ ] **P0 — Ganti password root VPS.** Password root sempat dibagikan di chat perencanaan.
- [ ] **P0 — Pengerasan SSH**: ~~buat user `deploy` (key-only, grup `docker`) untuk CI~~ (2026-10-19: tanpa
      password, kunci CI dengan forced command — runbook langkah 1); sisa: `PermitRootLogin prohibit-password`
      dan `PasswordAuthentication no`. Perhatikan
      `/etc/ssh/sshd_config.d/50-cloud-init.conf` saat ini menimpa jadi `PasswordAuthentication yes`.
      Pertimbangkan menutup port 22 bila SSH cukup lewat 8443.
- [ ] **P0 — Rotasi key `firebase-adminsdk`** (`riung-5e979-firebase-adminsdk-…json`). File sempat
      tersimpan di `~/Downloads` dengan izin `-rw-r--r--`, dan **sejak deploy 2026-10-13 key ini yang dipakai
      `riung-api`** (`/var/www/riung/secrets/firebase-service-account.json`) — hak admin penuh project. Buat
      **service account khusus**
      backend berperan *Firebase Authentication Admin* saja (runbook langkah 4b); akses Google Play memakai
      service account terpisah `riung-play` (langkah 4c). Ganti file di VPS, `docker restart riung-api`, lalu
      cabut key lama di Google Cloud dan hapus salinan di `~/Downloads`.
- [ ] **P0 — Salin secret prod ke password manager**: `/var/www/riung/.env` dan `.env.migrate` hanya ada di
      VPS (dibuat 2026-10-13). Tanpa salinan, VPS hilang = pembelian, backup PIN, dan `deleted_users` tidak
      bisa dipulihkan.
- [ ] **P0 — Backup Postgres off-site**: dump harian `riung` sudah jalan (`/var/backups/riung`, 14 hari, restore
      diuji 2026-10-13). Sisa: salin off-site, dan tambah dump `n8n` (masih tanpa backup).
- [x] **P1 — DNS Cloudflare**: `A riung → 76.13.20.72`, mode **DNS only** (sudah resolve, dicek 2026-10-13).
- [x] **P1 — Database**: DB `riung`, role `riung_migrator` & `riung_app` dibuat 2026-10-13.
- [x] **P1 — File env** (dibuat 2026-10-13): `/var/www/riung/.env` dari `backend/deploy/env.example` — empat secret HMAC
      berbeda (`openssl rand -hex 32`), `FOCUS_TICKET_KEY` (`openssl rand -base64 32`), path service account.
      Simpan salinan secret di password manager: `BILLING_ACCOUNT_KEY`/`LOG_PEPPER`/`PIN_PEPPER` tidak bisa
      diganti tanpa memutus pembelian, `deleted_users`, dan backup PIN.
- [x] **P1 — Nginx + TLS**: `riung.e55techlab.com` aktif 2026-10-13 (sertifikat diperpanjang cron certbot yang ada).
- [x] **P1 — Loki retensi 30 hari** (2026-10-19): `retention_stream` `{container=~"riung-api|riung-migrate"}`
      30 hari di `core-shared/monitoring/loki/config.yml`; stream lain tetap 7 hari. File di VPS belum di-commit
      ke repo `core-shared` (repo itu punya perubahan orang lain yang belum di-commit) — ikut item dokumentasi
      di bawah.
- [ ] **P2 — Promtail stage `json`** untuk riung (label hanya `level`, `event`); query sekarang memakai `| json`.
- [ ] **P1 — Dokumentasi core-shared** (commit ke branch `grafana`): IP `172.19.0.16`/`.17` dipakai
      `riung-api`/`riung-migrate`, `shared-postgres` dipakai "n8n + riung", domain baru di tabel nginx.
- [x] **P1 — GHCR & deploy lewat CI** (2026-10-19): setiap push ke `main`/`feat/go-backend` mem-push image
      `:<sha 7>` ke GHCR; deploy = *Run workflow* dengan `deploy` ✓ (user `deploy`, forced command, token GHCR
      sementara dari job). Deploy otomatis saat merge ke `main`: set `vars.RIUNG_DEPLOY_ENABLED=true` (perlu
      pemilik repo) — opsional.
- [ ] **P1 — Google Play billing** (langkah lengkap: `backend/deploy/README.md` 4c): aktifkan Android
      Publisher API & Pub/Sub API; service account `riung-play` diundang di Play Console (*View financial
      data* + *Manage orders and subscriptions*), key → `secrets/play-service-account.json`; topic `play-rtdn`
      (publisher: `google-play-developer-notifications@system.gserviceaccount.com`) + push subscription OIDC
      (`riung-rtdn-push`, audience = URL webhook); set topic RTDN di Play Console + *Send test notification*;
      isi `PLAY_PACKAGE_NAME`, `PLAY_CREDENTIALS_FILE`, `RTDN_AUDIENCE`, `RTDN_SERVICE_ACCOUNT`.
- [ ] **P1 — Produk Play Console**: id produk persis `coin_pack_small|medium|large` (in-app, consumable) dan
      langganan `premium_monthly|premium_yearly` (satu base plan per langganan, trial 7 hari di offer).
      **Multi-quantity tetap mati** (server mengkredit/menarik per token).
- [x] **P1 — Cron** (runbook langkah 9, dipasang 2026-10-13): `cleanup`, `cleanup-anon`, `billing-sync` (tiap jam), `reconcile`,
      backup `pg_dump`. Sisa: alert Grafana untuk `refund_applied`, `ledger_mismatch`, `job_run ok=false`, dan
      umur file backup terbaru (> 26 jam = gagal).
- [ ] **P1 — Uji sandbox**: license tester beli tiap paket koin & langganan, refund dari Play Console
      (koin tertarik / Premium berakhir), upgrade bulanan→tahunan, batalkan auto-renew (Premium tetap sampai
      akhir periode).
- [ ] **P1 — Firebase App Check**: aktifkan provider Play Integrity untuk app Android.
- [x] **P1 — Isi konten**: seed `dummy-data-seed.json` 2026-10-13 (ulangi bila konten berubah).
- [ ] **P1 — Admin**: tentukan email admin; pastikan admin punya akses VPN OpenVPN; jalankan
      `riung admin grant <email> <alasan>` setelah deploy.
- [x] **P1 — Alarm Telegram** (2026-10-20, runbook 8b): dikirim aplikasi sendiri sesuai konvensi `core-shared`
      (log ERROR, refund, start API) + `riung watchdog` tiap 2 menit (API, 5xx/p95, job cron, backup). Bot
      `@Riung_bot`, chat `408667565` — **penerima harus menekan Start di bot** (sebelum itu Telegram menjawab
      `chat not found`). Token bot sempat ditulis di chat → rotasi lewat @BotFather bersama pekerjaan keamanan.
- [x] **P1 — Dashboard Grafana** (2026-10-20, runbook 8c): **Riung — Teknis** (Loki) & **Riung — Bisnis** (view
      `metrics`, role baca-saja `riung_metrics`).
- [ ] **P1 — Staging** (runbook §H): stack, Postgres sendiri, nginx bootstrap, CI, Postman siap; **sisa: DNS
      `A riung-staging → 76.13.20.72` (DNS only)** → certbot → config nginx dengan kunci → `RIUNG_STAGING_ENABLED`.
      Kunci staging dibagikan ke tim app lewat kanal privat.
- [ ] **P2 — Pemantau dari luar VPS**: watchdog berjalan di VPS yang sama; VPS/Docker mati total tidak terdeteksi.
      Opsi: UptimeRobot/healthchecks.io ke `https://riung.e55techlab.com/healthz`.
- [ ] **P2 — Staging dengan Firebase sungguhan** (project `riung-staging`) bila login asli/App Check/billing
      sandbox perlu diuji sebelum produksi; sekarang staging memakai token dev.
- [ ] **P1 — App Check `enforce`** setelah app mengirim token: kriteria di `docs/backend-b6-review.md` §4.
- [ ] **P2 — Uji beban di VPS** saat beta (token Firebase sungguhan), pantau p95 dari Loki.
- [x] **P2 — Backend menunggu DB saat start** (2026-10-19): `riung api` mencoba ulang koneksi DB sampai 60 detik
      (WARN `database not ready, retrying`), baru keluar dengan ERROR bila DB tetap tidak ada.
- [ ] **P2 — `server_tokens off;`** di `shared-nginx` (versi nginx terlihat di header `Server`; berlaku semua situs).
- [ ] **P2 — CI Flutter**: tambahkan `paths-ignore: ['backend/**']` di
      `.github/workflows/firebase_app_distribution.yml` supaya perubahan backend tidak memicu build APK.

- [x] **App Store di backend aktif** (2026-10-20): In-App Purchase key `6M37Z83MZ5`, Issuer ID, app `6824618033`,
      URL Server Notifications V2 terpasang, notifikasi TEST sandbox diterima. Simpan `.p8` di password manager
      lalu hapus salinan `~/Downloads/SubscriptionKey_6M37Z83MZ5.p8`. `AuthKey_S76JA9YKP5.p8` (APNs + DeviceCheck)
      untuk Firebase, bukan backend. Production API Apple menjawab 401 sampai app rilis pertama (normal).
- [ ] **P1 (saat rilis iOS dijadwalkan) — App Store Connect, sisa** (`docs/panduan-apple-developer.md`, tabel
      status): Paid Apps agreement + bank/pajak; produk dengan id sama seperti Play (consumable `coin_pack_*`, satu
      subscription group berisi `premium_monthly|yearly`, intro offer 7 hari, Family Sharing mati); sandbox tester;
      capability Push/Sign in with Apple/App Attest di App ID lalu buat ulang profil. Key, Server Notifications, dan
      `APPSTORE_*` sudah selesai (server aktif 2026-10-20).
- [x] **P1 — Package `id.riung.riung` (iOS & Android)** (tim app, `dev` 2026-10-20): bundle id, `applicationId`, app
      Firebase, secret CI `GOOGLE_SERVICE_INFO_PLIST`, `GOOGLE_SERVICES_JSON`, `FIREBASE_APP_ID_ANDROID`. Saat Google Play
      diaktifkan: `PLAY_PACKAGE_NAME=id.riung.riung` (listing Play baru — package lama tidak bisa diganti).
- [x] **P1 (iOS) — Build otomatis ke TestFlight** (PR #2 → `dev`): build `1.0.3 (1013)` VALID 2026-10-20.
- [ ] **P1 (iOS) — Uji sandbox App Store**: pastikan `appAccountToken` dari `applicationUserName` muncul di
      transaksi (kalau kosong, server menolak `purchase_invalid`), beli/refund/upgrade/batal di sandbox.
- [ ] **P2 (iOS) — Riwayat refund Apple**: notifikasi `REFUND` yang terlewat (5 kali gagal) belum disusul job;
      tambahkan sinkron lewat *Get Refund History* / *Get Notification History* bila volume iOS sudah ada.
- [ ] **P2 (iOS) — `REFUND_REVERSED`**: Apple bisa membatalkan refund; sekarang hanya dicatat (`action=logged`),
      koin paket yang sudah ditarik tidak dikembalikan. Jarang terjadi — tangani manual sampai ada kasus.

## B. App Flutter (`riung/`) — integrasi backend (P1)

Panduan lengkap untuk tim app: **`docs/panduan-integrasi-app.md`** (header, error, alur, outbox, Fokus, Toko,
Aplikasi Beku, pembelian).

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
- [ ] Outbox offline (`sqflite`, DB versi 2) untuk `POST /v1/activities/batch`: `entryId`/`ref`/`ticketId` dibuat
      sekali saat kejadian; `Idempotency-Key` baru per kiriman batch (panduan app §8).
- [ ] `BillingService`: `applicationUserName` (= `obfuscatedAccountId`) = `billingAccountId` dari `/v1/me`;
      tombol beli hanya untuk akun permanen (anonim → ajak tautkan akun dulu, server menjawab 403);
      paket koin `buyConsumable(autoConsume: false)`; panggil `/v1/billing/verify` (Idempotency-Key + App Check
      limited-use) untuk setiap update pembelian; setelah `credited|already_credited` → `consumePurchase`,
      setelah `active|inactive` → `completePurchase` — **tidak** untuk `pending` dan tidak untuk error; `503` →
      coba lagi nanti (pembelian tetap ada di Play); `/v1/billing/restore` saat app dibuka/login dengan hasil
      `restorePurchases()` (status `restored`); status Premium dari
      `GET /v1/billing/subscription` / `GET /v1/me`; berhenti mengkredit koin/Premium dari perangkat.
- [ ] Hapus akun saat langganan aktif: tampilkan peringatan "batalkan langganan di Play Store dulu" —
      langganan terikat ke `billingAccountId` akun lama dan tidak bisa dipindah ke akun baru.
- [ ] **Mode Fokus lewat tiket**: saat online ambil tiket `free_daily` di muka (`POST /v1/focus/tickets`),
      simpan terenkripsi, cek tanda tangan dengan `focusTicketKeys` dari `/v1/config` (payload §3.7); tiket
      `prepaid`/`coins` diminta **saat user memulai sesi** (sesinya langsung terpakai, tidak dikembalikan bila
      kedaluwarsa); sesi selesai → `focus_completed` `{ticketId, saboteurId}` lewat outbox; tangani
      `limit_reached` (`free_daily`, `no_prepaid_sessions`) dan `ticket_invalid`. Hapus pemotongan
      sesi/koin Fokus di perangkat.
- [ ] **Aplikasi Beku lewat server**: `POST /v1/appbeku/unlocks` dengan `appId` = package name (satuan:
      `minutes` 10/20/30/60) atau `bundleId` (`santai`; `sosmed` + `appIds` aplikasi sosmed yang dibekukan),
      `expectedPrice` = harga dasar dari `/v1/config` + 10 × `today.paidUnlocksUsed`; buka menit sesuai
      `result.grants`; tangani `cooldown` (`retryAfterSeconds` — jeda juga berlaku di Toko, bukan hanya
      interstisial), `limit_reached`, `insufficient_coins` dengan `earnedOnly`, `price_changed`. Hitungan
      buka-berbayar dari `GET /v1/me` (`today.paidUnlocksUsed`), bukan prefs lokal; jalur napas tetap lokal.
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
- [x] `CLAUDE.md`: rujukan backend Go, `docs/catalog.json`, dan panduan integrasi (2026-10-13).
- [ ] Setelah cutover: `firestore.rules` → deny-all (kecuali yang masih dipakai), hapus kode Firestore
      user/wallet, hapus catatan "Firestore masih dipakai" di `CLAUDE.md`, rapikan `docs/firebase-architecture.md`
      & `docs/setup-firebase.md` (sudah diberi catatan status 2026-10-13).

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

## C2. Hasil uji frontend branch `implement_and_integrations_api` (`c95887a`) — dicek ulang 2026-10-18

Setiap temuan agent testing dicocokkan dengan kode branch itu dan source plugin `in_app_purchase_android` 0.5.3.

- [ ] **C-01 (Critical) — terkonfirmasi.** Data lokal bocor antar akun di HP yang sama: `AuthNotifier.signOut()`
      hanya `FirebaseAuth.signOut()` lalu kembali ke Splash (`pengaturan_screen.dart`); `journal_entries` &
      `checkin_history` tanpa `user_id` (outbox sudah punya); kunci enkripsi jurnal (`JournalCryptoService`),
      PIN (`JurnalPinService`, disimpan apa adanya, bukan hash) dan `LocalPrefsStore` satu untuk seluruh
      perangkat. Perbaikan: saat logout kirim outbox lalu hapus DB lokal + secure storage + prefs (atau
      simpan per `uid`); saat login akun lain, mulai dari data kosong lalu tarik `GET /v1/me`.
- [ ] **H-01 — terkonfirmasi.** `paywall_step.dart` & `paywall_premium_screen.dart`: update `pending`
      memasang `_processing = true` sampai update berikutnya (VA/Indomaret bisa berjam-jam); "Lanjut versi
      gratis" dan tombol tutup ikut nonaktif. Perbaikan: `pending` → tampilkan "menunggu pembayaran" dan
      lepas tombol; status akhir datang lewat `purchaseStream`/restore saat app dibuka.
- [ ] **H-02 — terkonfirmasi, lebih luas.** `_products = {for p in productDetails: p.id: p}` menimpa offer:
      plugin mengembalikan satu `ProductDetails` per offer dengan `id` sama dan `price` = fase pertama
      (trial → "Gratis"). Akibatnya harga yang tampil **dan offer yang dibeli** acak. Lama trial diambil dari
      `rc.premiumTrialHari`, bukan dari Play. Perbaikan: panduan app §11.2.
- [ ] **H-03 — terkonfirmasi.** `_pulihkanPembelian` memasang `_restoring/_processing` lalu menunggu update;
      `restorePurchases()` tanpa riwayat mengirim list kosong → tidak ada update → macet. Perbaikan: lepas
      status setelah `await restorePurchases()` selesai dan tampilkan "tidak ada pembelian untuk dipulihkan"
      bila tidak ada item `restored`.
- [ ] **H-04 — terkonfirmasi.** Tidak ada `changeSubscriptionParam` di app → beli tahunan saat bulanan aktif
      membuat langganan kedua (tertagih ganda). Backend memilih langganan yang berakhir paling lama, tapi
      tidak bisa mencegah tagihan. Perbaikan: panduan app §11.2.
- [ ] **H-05 — sebagian.** `hapus_akun_screen.dart` sudah menambah peringatan bila `premiumNow`, tapi tetap
      bisa lanjut dan tidak ada tautan ke halaman langganan Play; `premiumNow` juga benar untuk langganan
      yang sudah dibatalkan. Perbaikan: peringatan + tombol Play hanya bila `premium.autoRenewing` (panduan
      §7). Opsi backend di §D.
- [ ] **M-01 — terkonfirmasi.** Harga per negara sudah dari Play (`ProductDetails.price`) di paywall, tapi
      cadangan paywall, `langganan_screen.dart` (`rc.premiumHarga*Idr`), `premium_locked_screen.dart`
      (`EconomyPremium.hargaBulananIdr`), dan analytics pembelian (`priceIdr`) masih Rupiah. Satu app cukup
      (harga per negara di Play Console). Perbaikan: selalu `ProductDetails.price`; analytics `rawPrice` +
      `currencyCode`.
- [ ] **M-04 — terkonfirmasi; sisi backend selesai 2026-10-20.** Tidak ada jalur StoreKit di app. Backend
      aktif sejak 2026-10-20 (§A): `/v1/billing/appstore/verify|restore` (App Store
      Server API, JWS diverifikasi sampai Apple Root CA G3), `/v1/webhooks/app-store` (Notifications V2:
      refund, perpanjangan, kedaluwarsa), `user.appAccountToken` di `/v1/me`, login `apple.com`. Sisa di app:
      panduan §11.6.
- [x] **Backend — `purchaseToken` di setiap baris `/v1/billing/restore`** (2026-10-18). App bisa beralih dari
      pencocokan urutan baris ke pencocokan token (urutan tetap sama dengan request, jadi kode lama tetap benar
      sampai diganti).

## D. Keputusan produk yang belum final

Backend memakai default di kolom kanan sampai diputuskan lain.

| Pertanyaan | Default backend |
|---|---|
| Sesi Fokus gratis & prabayar dibatasi durasi 25 menit, atau durasi apa pun seperti app sekarang? | durasi apa pun (mengikuti app) |
| Jurnal/meditasi di atas batas harian: tanpa koin saja, atau tanpa koin **dan** tanpa progres monster? | tanpa koin & tanpa progres |
| Nilai awal `journalRewardsPerDay` / `meditationRewardsPerDay` | 3 / 3 (bisa diubah admin) |
| Jendela laporan offline: 7 hari (sekarang) atau 72 jam (lebih ketat terhadap client yang dimodifikasi)? | 7 hari |
| Refund satu periode langganan tanpa pencabutan akses oleh Google: Premium tetap jalan atau langsung dicabut? | mengikuti Google (tetap jalan bila Google tidak mencabut) |
| Tiket Fokus `prepaid`/`coins` yang tidak dipakai sampai kedaluwarsa (30 hari): hangus atau sesi/koin dikembalikan? | hangus (app hanya meminta tiket saat sesi dimulai) |
| Sesi Fokus yang dibayar koin (bisa dari koin beli) memberi progres monster +4 seperti app sekarang. Aturan #4 dibaca "progres tidak dijual langsung — pembelian hanya membuka akses ke latihan" (sama seperti konten Premium). Atau tiket `coins` dibatasi ke koin latihan saja? | sesuai app: semua koin boleh, progres dari sesi yang dijalankan |
| Jeda 60 detik antar buka-berbayar Aplikasi Beku juga berlaku untuk pembelian dari Toko (sekarang app hanya menunggu di interstisial)? | ya, server menerapkan jeda untuk semua buka-berbayar |
| Utang koin hasil refund (`debtCoins`) ditampilkan ke user? Teks apa? | tidak ada copy; API mengembalikan `debtCoins` |
| Backend menolak `DELETE /v1/me` (`409 subscription_active`) selama langganan masih diperpanjang otomatis, kecuali app mengirim konfirmasi eksplisit? Lebih aman dari bug app, tapi menambah langkah sebelum user bisa menghapus akunnya | tidak — app yang memperingatkan (panduan §7) |
| Rilis iOS: kapan? (backend aktif 2026-10-20; tinggal StoreKit di app + App Store Connect) | belum direncanakan |
| Pembelian **sandbox** App Store (TestFlight, App Review, akun sandbox) dikreditkan ke akun produksi (`test=true`), seperti license tester Play — wajib agar App Review bisa membeli. Risiko: penguji TestFlight **eksternal** mendapat koin/Premium gratis. Batasi TestFlight ke penguji internal/terpercaya, atau tambahkan saklar `APPSTORE_ACCEPT_SANDBOX` (mati setelah rilis kecuali saat review)? | diterima; pantau `purchase_verified` `test=true` |
