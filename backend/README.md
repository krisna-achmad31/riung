# Riung backend (Go)

Server API untuk app Riung: Go + PostgreSQL 16, satu binary di image distroless, di-deploy dengan Docker
Compose di VPS (`riung.e55techlab.com`, di belakang `shared-nginx`).

- Rencana & keputusan: [`docs/backend-go-plan.md`](../docs/backend-go-plan.md)
- Spesifikasi API, keamanan, rate limit, logging: [`docs/backend-api-spec.md`](../docs/backend-api-spec.md)
- Pekerjaan di luar backend (app, infra): [`docs/todo-luar-backend.md`](../docs/todo-luar-backend.md)
- **Untuk tim app**: [`docs/panduan-integrasi-app.md`](../docs/panduan-integrasi-app.md) · Postman: [`postman/`](postman/README.md)
- Riwayat perubahan per rilis: [`CHANGELOG.md`](CHANGELOG.md)

## Status

- **B0 — fondasi** ✅: binary `riung`, konfigurasi env, log JSON (user & IP di-hash), middleware (request id,
  IP asli dari `shared-nginx` saja, access log, recover, batas body, header keamanan), error JSON standar,
  `/healthz` & `/readyz`, skema PostgreSQL + hak akses role, Dockerfile, compose dev/prod, nginx, CI.
- **B1 — identitas, akun, konten** ✅: verifikasi ID token Firebase + App Check (`off|monitor|enforce`),
  akun dibuat otomatis (termasuk anonim) dengan batas akun baru per IP, rate limit per user/IP,
  idempotensi (`Idempotency-Key`), dan endpoint:

  | Endpoint | Akses |
  |---|---|
  | `GET /v1/config` (angka ekonomi + batas setelah override admin, ETag) | App Check |
  | `GET /v1/content/{kind}` (`saboteurs`, `affirmations`, `research_facts`, `meditations`, `sleep_stories`, `betterme_lessons`) | App Check |
  | `POST /v1/waitlist` (+ CORS landing, honeypot, respons seragam) | publik |
  | `GET /v1/me`, `PATCH /v1/me/profile`, `PUT /v1/me/assessment`, `POST /v1/me/link`, `GET /v1/me/export` | user (anonim boleh) |
  | `DELETE /v1/me` (login ≤ 5 menit untuk akun permanen, juga menghapus akun Firebase) | user |
  | `GET/PUT/DELETE /v1/me/journal-pin-backup`, `POST …/verify` (maks 10 gagal/hari) | akun permanen |

- **B2 — ekonomi** ✅: katalog (`docs/catalog.json`, harga dari `economy-props.json`) di `GET /v1/config`;
  wallet berbasis ledger (bucket koin latihan/beli, pelunasan utang refund, idempoten, baris wallet dikunci per
  user sehingga request paralel tidak bisa membuat saldo minus); endpoint:

  | Endpoint | Isi |
  |---|---|
  | `POST /v1/activities`, `/batch` (≤ 50, outbox offline) | check-in (streak, pelindung otomatis, bonus 7/30 hari), jurnal (batas gratis, prompt premium, batas koin admin), meditasi (sesi premium, batas admin), Better Me (premium & urutan level), misi (3/hari), minigame (4 pertarungan/hari), monster jinak +50 sekali |
  | `GET /v1/journal/access` | boleh menulis jurnal / prompt premium atau tidak |
  | `GET /v1/wallet`, `GET /v1/wallet/transactions` | saldo & riwayat (cursor) |
  | `POST /v1/premium/daily-coins` | +2/hari pelanggan tahunan (bucket beli) |
  | `POST /v1/shop/purchase` | kosmetik, paket aksesori (diskon dari item yang belum dimiliki), pelindung streak, paket Fokus |
  | `PUT /v1/loadouts/monsters/{id}`, `/characters/{testId}` | pasang kosmetik/aksesori/gaya kartu (dimiliki, slot, eksklusif, Premium) |
  | Admin API `:8081` `GET/PUT/DELETE /admin/v1/settings/{key}`, `GET /admin/v1/audit` | batas koin jurnal & meditasi, batas akun baru per IP; hanya dari VPN + klaim admin + daftar `admins`, semua perubahan diaudit |

  CLI operator: `riung settings list|set|reset`, `riung admin grant|revoke <email> <alasan>`,
  `riung cleanup` (cron harian).
- **B3 — billing Google Play** ✅: verifikasi ke Android Publisher API (state PURCHASED, `obfuscatedExternalAccountId`
  = `billingAccountId`, satu token hanya untuk satu akun & dikreditkan sekali), koin paket ke bucket beli, Premium
  dari `subscriptionsv2` (upgrade/`linkedPurchaseToken`, batal tetap aktif sampai akhir periode):

  | Endpoint / perintah | Isi |
  |---|---|
  | `POST /v1/billing/verify`, `/restore` (≤ 20) | akun permanen, idempoten, App Check limited-use untuk `verify` |
  | `GET /v1/billing/subscription` | status Premium |
  | `POST /v1/webhooks/google-play` | RTDN Pub/Sub (OIDC), dedupe, status selalu dibaca ulang dari Play |
  | `riung billing-sync` (cron tiap jam) | refund → tarik koin (sisa jadi utang) / cabut Premium; acknowledge pembelian yang terlewat app |
  | `riung reconcile` (cron harian) | saldo dompet vs jumlah ledger; selisih → `ledger_mismatch` + exit 1 |
- **B4 — Fokus & Aplikasi Beku** ✅:

  | Endpoint | Isi |
  |---|---|
  | `POST /v1/focus/tickets`, `GET /v1/focus/tickets` | tiket Ed25519 untuk sesi offline: `free_daily` (1/hari, Premium 3), `prepaid` (sesi dari paket), `coins` (25/40/50) |
  | `focus_completed` di `/v1/activities` | menukar tiket sekali (tidak bisa "selesai" sebelum durasinya), +4 progres monster |
  | `POST /v1/appbeku/unlocks` | buka-waktu berbayar hanya dengan koin latihan, maks 3/hari, +10 tiap kali, jeda 60 detik; bundel `santai`/`sosmed` atomik; aplikasi yang dibuka tidak disimpan/dicatat |
- **B5 — deploy** ✅ (live sejak 2026-10-13): `riung cleanup-anon` (akun anonim tak dibuka > 90 hari, data server + user
  Firebase), `riung reapply-deletions` (setelah restore backup), Dependabot untuk modul Go & image. Deploy ke
  VPS mengikuti [`deploy/README.md`](deploy/README.md).
- **B6 — kesiapan produksi** ✅ ([`docs/backend-b6-review.md`](../docs/backend-b6-review.md)): uji beban
  k6 ([`loadtest/`](loadtest/README.md), p95 11,9 ms di 200 pengguna aktif), review keamanan (cek pencabutan
  token setelah rate limit, CSP, TLS AEAD, field `appCheck` di access log), 12 aturan alert Grafana (Telegram),
  kriteria App Check `enforce`.

## Menjalankan lokal

Dengan Docker:

```sh
make dev-up            # Postgres 16 + migrate + api di http://localhost:8080
docker compose -f deploy/docker-compose.yml exec -T api /riung seed-content - < ../docs/dummy-data-seed.json
curl localhost:8080/healthz
make dev-down
```

Stack dev memakai `DEV_AUTH=true`: token `Bearer dev:<uid>:<anonymous|password|google.com>` menggantikan
ID token Firebase, contoh:

```sh
curl localhost:8080/v1/me -H 'Authorization: Bearer dev:rani:anonymous'
curl -X PATCH localhost:8080/v1/me/profile -H 'Authorization: Bearer dev:rani:anonymous' \
  -H 'Content-Type: application/json' -H "Idempotency-Key: $(uuidgen)" -d '{"displayName":"Rani"}'
```

`DEV_AUTH` ditolak saat `RIUNG_ENV=prod`. Admin lokal: panggil `/v1/me` sekali dengan `dev:<uid>:google.com`, lalu
`riung admin grant dev:<uid> "alasan"` dan pakai token `dev:<uid>:google.com:admin` ke port 8081.

Stack dev juga memakai `DEV_BILLING=true` (Google Play palsu). Ambil `billingAccountId` dari `/v1/me`, lalu:

```sh
BA=ba_...   # dari /v1/me; di zsh tulis ${BA} — "$BA:c..." dibaca zsh sebagai modifier
curl -X POST localhost:8080/v1/billing/verify -H 'Authorization: Bearer dev:rani:google.com' \
  -H 'X-Firebase-AppCheck: dev' -H 'Content-Type: application/json' -H "Idempotency-Key: $(uuidgen)" \
  -d "{\"productId\":\"coin_pack_small\",\"purchaseToken\":\"dev-coin:${BA}:coin_pack_small:1\"}"
# langganan: "dev-sub:${BA}:premium_yearly:365:1"; webhook: Authorization: Bearer dev-pubsub
```

Tanpa Docker (Postgres sudah ada, role dibuat dengan `deploy/sql/create-riung-db.sql`):

```sh
make build
MIGRATE_DATABASE_URL=postgres://riung_migrator:...@localhost:5432/riung ./bin/riung migrate up
DATABASE_URL=postgres://riung_app:...@localhost:5432/riung ./bin/riung api
```

## Konfigurasi

| Variabel | Default | Keterangan |
|---|---|---|
| `RIUNG_ENV` | `dev` | `dev` / `prod`. `prod` mewajibkan secret kuat dan menolak `migrate down` |
| `LISTEN_ADDR` | `:8080` | alamat API |
| `LOG_LEVEL` | `info` | `debug` / `info` / `warn` / `error` |
| `DATABASE_URL` | — | role `riung_app` (DML saja) — wajib untuk `api` |
| `MIGRATE_DATABASE_URL` | — | role `riung_migrator` (DDL) — hanya untuk `migrate`; di `prod` wajib terpisah |
| `DB_MAX_CONNS` | `10` | 1–50 (Postgres dipakai bersama n8n) |
| `DB_STATEMENT_TIMEOUT` | `5s` | batas waktu per query |
| `TRUSTED_PROXIES` | kosong | IP/CIDR yang boleh mengisi `X-Real-IP`/`X-Request-Id` (prod: `172.19.0.2/32`) |
| `LOG_PEPPER`, `IP_HASH_KEY` | dev placeholder | kunci hash log; prod wajib ≥ 32 karakter |
| `PIN_PEPPER`, `BILLING_ACCOUNT_KEY` | dev placeholder | HMAC backup PIN jurnal & id akun Play; prod wajib ≥ 32 karakter; keempat secret wajib berbeda |
| `FIREBASE_PROJECT_ID` | — | project Firebase (`riung-5e979`); wajib kecuali `DEV_AUTH` |
| `FIREBASE_CREDENTIALS_FILE` | — | service account (Firebase Auth Admin); wajib di prod (cek pencabutan, hapus akun) |
| `APP_CHECK_MODE` | dev `off`, prod `monitor` | `off` / `monitor` (catat saja) / `enforce` (tolak); `off` ditolak di prod |
| `DEV_AUTH` | `false` | token `dev:<uid>:<provider>`; hanya di `RIUNG_ENV=dev` |
| `FOCUS_TICKET_KEY` | dev: turunan dev secret | seed Ed25519 32 byte (base64, `openssl rand -base64 32`) untuk tiket Fokus; wajib di prod |
| `FOCUS_TICKET_KID` | `k1` | nama kunci tiket (ganti bersama key saat rotasi) |
| `PLAY_PACKAGE_NAME` | kosong (billing mati, 503) | `com.riung.riung`; mengaktifkan billing |
| `PLAY_CREDENTIALS_FILE` | `FIREBASE_CREDENTIALS_FILE` | service account yang diundang di Play Console |
| `RTDN_AUDIENCE`, `RTDN_SERVICE_ACCOUNT` | — | wajib bila billing aktif: audience & service account push subscription Pub/Sub |
| `DEV_BILLING` | `false` | Google Play palsu (`dev-coin:`/`dev-sub:`); hanya di `RIUNG_ENV=dev` |
| `CORS_LANDING_ORIGIN` | kosong | satu-satunya origin browser untuk `POST /v1/waitlist` |
| `MIN_APP_VERSION` | `0.0.0` | app di bawah versi ini mendapat `426 upgrade_required` |
| `ADMIN_LISTEN_ADDR` | kosong (mati) | port Admin API, mis. `:8081`; tidak pernah dipasang di nginx |
| `ADMIN_ALLOWED_CIDRS` | — | wajib bila Admin API aktif; prod `172.19.0.7/32` (OpenVPN) |
| `LOG_TEE` | kosong | file tambahan untuk log JSON; cron memakai `/proc/1/fd/1` supaya log job masuk log container |
| `ANON_RETENTION_DAYS` | `90` | akun anonim yang tidak dibuka selama ini dihapus `riung cleanup-anon` (30–3650) |
| `SHUTDOWN_TIMEOUT` | `15s` | graceful shutdown |

Contoh file: `deploy/env.example` (API) dan `deploy/env.migrate.example` (migrasi).

## Tes

```sh
make test                                   # unit test (tes integrasi di-skip tanpa DB)
make dev-up && make test-integration        # + tes integrasi & end-to-end API ke Postgres stack dev
make lint vuln                              # golangci-lint (gosec) + govulncheck
```

Tes end-to-end (`internal/api/api_test.go`) menjalankan server HTTP sungguhan ke database baru dan
mencakup: auth wajib, akun anonim otomatis, validasi & idempotensi (replay identik byte-per-byte), batas akun
per IP + override admin, rate limit per user/IP, header IP palsu diabaikan, App Check `monitor`/`enforce`/
gangguan Google, versi app minimum, ETag config/konten, CORS & honeypot waitlist, PIN (salt saja yang keluar,
lockout), hapus akun (login ulang, akun Firebase ikut terhapus), dan log tanpa uid/email/hash PIN.

Tes integrasi membuat database sementara dan memastikan: migrasi naik/turun bersih, saldo tidak bisa
negatif, ledger idempoten, `riung_app` **tidak bisa** mengubah/menghapus `coin_ledger`,
`admin_audit_log`, atau kolom non-status `purchases`, tidak bisa DDL, dan hapus akun tetap cascade
(pembelian tersimpan dengan `user_id` NULL).

## Deploy

Runbook lengkap (setup pertama, rilis rutin, verifikasi, rollback, masalah umum):
[`deploy/README.md`](deploy/README.md).

Ringkas: push ke `main`/`feat/go-backend` → CI test, build, scan, push image `:<sha 7>` ke GHCR. Deploy =
`gh workflow run Backend --ref <branch> -f deploy=true` → SSH sebagai `deploy` (forced command
`deploy/riung-ci-deploy.sh`) → `deploy/deploy.sh <image>` di VPS (pull → migrate → recreate `riung-api` →
tunggu healthy) → smoke test. Push ke `main` deploy sendiri hanya bila `vars.RIUNG_DEPLOY_ENABLED == 'true'`.
Rollback: `gh workflow run Backend --ref <branch> -f rollback_tag=<sha7>` (image dari GHCR, tanpa build).
