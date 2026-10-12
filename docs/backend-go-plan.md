# Riung Backend — Go + PostgreSQL + Docker (Plan)
*Branch: `feat/go-backend` · status: rencana, belum ada kode · keputusan terakhir: 2026-10-11*

## 0. Kenapa, dan apa yang berubah

Hari ini Riung jalan di Firebase **Spark plan tanpa Cloud Functions**:

- Wallet dimutasi langsung oleh client (`FirestoreWalletFunctionsService`), dijaga hanya oleh
  allowlist delta di `riung/firestore.rules` (`isValidWalletDelta`). Client yang dimodifikasi
  masih bisa replay delta yang "bentuknya sah".
- Pembelian Play Billing **tidak diverifikasi server** — `BillingService._deliver` percaya status
  `purchased` dari perangkat lalu mengkredit koin/Premium sendiri.
- Banyak state bernilai uang hanya ada di `LocalPrefsStore`: kosmetik dimiliki, sesi Fokus prabayar,
  pelindung streak, cadangan koin-beli (`purchasedReserve`), klaim koin harian tahunan, jatah buka-waktu
  Aplikasi Beku, misi harian yang sudah dicentang.

Backend Go menggantikan peran "Cloud Functions" di `CLAUDE.md` aturan #5 dan #6, dan **PostgreSQL
menggantikan Firestore** sebagai database server. Prinsip yang TIDAK berubah:

- **Offline-first**: jurnal, isi check-in, hasil asesmen detail, afirmasi buatan tetap di perangkat.
  Server tidak pernah menerima teks jurnal atau isi check-in (mood/catatan) — cukup fakta "sudah
  check-in tanggal X".
- **Garis etis** (aturan #4) ditegakkan di server, bukan cuma di UI: progres monster tidak pernah
  naik karena pembelian, buka-waktu berbayar hanya pakai koin hasil latihan, tiket tidak dijual, layar
  krisis tidak dilog (backend tidak punya endpoint/log apa pun untuk krisis).
- Client tidak pernah mengirim **jumlah** koin. Client mengirim *apa yang terjadi* (`type` + `ref`),
  server yang menentukan nominal dari konfigurasi ekonomi.

Yang tetap di Firebase (client-side): **Auth** untuk sementara (token diverifikasi di Go, lihat §1),
Analytics, Crashlytics, Remote Config (lihat §6), dan FCM bila nanti dipakai (app sekarang hanya
notifikasi lokal).

### 0.1 Kondisi data Firestore `riung-5e979` (dicek read-only 2026-10-11)

| Data | Isi |
|---|---|
| Root collection | hanya `/users` (8 dok) dan `/waitlist` (2 dok). **`/content` tidak ada** — app selama ini memakai fallback `dummy-data-seed.json`. |
| `/users` per jenis akun Auth | 5 anonim (dibuat sebelum alur "lokal-dulu"), 1 email/password, 1 Google, 1 yatim (user Auth-nya sudah tidak ada) |
| Wallet | total saldo 326 koin; 290 di 2 akun permanen. Semua konsisten `coins == lifetimeEarned − lifetimeSpent`. |
| Premium / pembelian | 0 Premium aktif, tidak ada jejak pembelian |
| `coinRequests` | hanya 5 entri — tidak lengkap, tidak bisa di-replay |
| Firebase Auth | 10 user (8 anonim, 1 password, 1 Google), hanya 1 aktif 30 hari terakhir |

**Keputusan: tidak ada migrasi data** — semuanya data tester. Backend mulai dari database kosong
(+ seed konten). Akun tester cukup login ulang; saldo/progres tester tidak dibawa.

## 1. Keputusan teknis

| Area | Pilihan | Catatan |
|---|---|---|
| Bahasa | Go (versi stabil terbaru, ≥1.25) | |
| Router | `net/http` stdlib (pattern routing Go 1.22+) + middleware kecil | minim dependensi |
| DB | PostgreSQL 16 `shared-postgres` (stack `core-shared` di VPS), DB `riung` + role sendiri | tidak ikut di compose riung (§8); kode tidak memakai fitur khusus PG17 |
| Driver/query | `pgx/v5`, query ditulis tangan di `internal/store` | semua parameterized, diuji integrasi ke PostgreSQL 16 (sqlc tidak dipakai: lebih sedikit tooling, tanpa CGO) |
| Migrasi | `goose` (SQL di `backend/db/migrations`, di-embed ke binary) | |
| Auth | **Fase 1: Firebase Auth** (verifikasi ID token via `firebase.google.com/go/v4`). **Fase berikutnya: auth sendiri.** | dirancang bisa diganti tanpa migrasi data — §3.1; `DEV_AUTH` (hanya `RIUNG_ENV=dev`) untuk lokal |
| App Check | verifikasi header `X-Firebase-AppCheck` | anti-tamper |
| Play Billing | `google.golang.org/api/androidpublisher/v3` + RTDN (Pub/Sub push) | verifikasi receipt server-side (aturan #6) |
| Log | `log/slog` JSON, tanpa PII/isi konten | |
| Deploy | Docker Compose di VPS sendiri, join network `vps-shared-net`, di belakang `shared-nginx` (TLS certbot yang sudah ada) | §8 — domain `riung.e55techlab.com` |
| Registry/CI | GitHub Actions → GHCR → deploy via SSH | |

## 2. Struktur folder

Monorepo, sejajar `riung/` (Flutter) dan `landing/`:

```
backend/
  cmd/
    riung/               # satu binary: api | migrate | seed-content | healthcheck | version; cleanup-anon, settings, admin menyusul (B2+)
  internal/
    config/              # env → struct typed
    economy/             # angka ekonomi, di-load dari docs/economy-props.json (embed)
    catalog/             # katalog kosmetik/aksesori/gaya kartu/bundel + harga
    authn/               # interface Verifier + implementasi Firebase (nanti: auth sendiri)
    logx/                # logger JSON slog + hash user/IP untuk log (B0)
    database/            # pool pgx + runner migrasi goose (B0)
    health/              # /healthz, /readyz (B0)
    httpx/               # router JSON 404/405, middleware request id, real IP, access log, recover, body limit (B0); rate limit & CORS menyusul
    profile/             # profil, premium, streak, asesmen ringkas
    wallet/              # ledger, bucket koin earned/purchased, idempotensi
    activities/          # event latihan → koin, progres monster, streak, cap harian
    monsters/            # progres penjinakan
    shop/                # belanja kosmetik, bundel, pelindung streak, sesi fokus
    focus/               # tiket Fokus bertanda tangan + rekonsiliasi
    appbeku/             # buka-waktu berbayar (cap, eskalasi, jeda)
    billing/             # verifikasi Play, RTDN, voided purchases
    content/             # konten publik (saboteurs, affirmations, ...)
    settings/            # app_settings (pengaturan yang diubah admin) + cache
    admin/               # Admin API port 8081 (allowlist sumber + claim admin + audit)
    waitlist/
    store/               # akses DB (pgx, query tulisan tangan) (B1)
    ratelimit/           # token bucket per user/IP (B1)
    catalog/             # catalog.json (salinan docs/catalog.json) + harga dari economy (B2)
    settings/            # pengaturan yang bisa diubah admin + cache (B2)
    rules/               # aturan ekonomi: activities, streak, taming, toko, loadout, jurnal (B2)
    api/                 # routing, middleware auth/App Check/idempotensi/rate limit, handler (B1)
    testdb/              # database sementara untuk tes integrasi
  db/
    migrations/
  api/openapi.yaml       # kontrak API (sumber model request/response Dart & Go)
  deploy/
    docker-compose.yml          # dev lokal (termasuk Postgres 16 lokal)
    docker-compose.prod.yml     # VPS: riung-api + riung-migrate di vps-shared-net
    deploy.sh                   # di VPS: pull → migrate → recreate api → tunggu healthy
    env.example, env.migrate.example
    nginx/riung.e55techlab.com{.bootstrap,}.conf   # disalin ke core-shared/nginx/conf.d
    sql/create-riung-db.sql     # sekali jalan: DB + role riung di shared-postgres
    monitoring/                 # snippet retensi Loki 30 hari + pipeline Promtail
    dev/initdb.sh               # init DB di compose dev
  Dockerfile
  Makefile
  sqlc.yaml
  .env.example
```

## 3. Skema PostgreSQL (draf `0001_init.sql`)

### 3.1 Identitas — siap ganti ke auth sendiri

`users.id` adalah **UUID internal milik kita**, bukan uid Firebase. Uid Firebase hanya disimpan sebagai
salah satu "identitas login". Saat nanti pindah ke auth sendiri, cukup tambah baris identitas baru untuk
user yang sama — seluruh data (wallet, ledger, monster, pembelian) tetap menempel ke `users.id` dan
tidak perlu dipindahkan.

```sql
users (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at timestamptz NOT NULL DEFAULT now(),
  last_seen_at timestamptz NOT NULL DEFAULT now(),
  is_anonymous bool NOT NULL,
  display_name text NOT NULL DEFAULT '', avatar_id text NOT NULL DEFAULT 'av1',
  locale text NOT NULL DEFAULT 'id', persona text, onboarding_done bool NOT NULL DEFAULT false,
  tz text NOT NULL DEFAULT 'Asia/Jakarta'           -- penentu "hari ini" untuk cap harian & streak
)
auth_identities (
  provider text NOT NULL,        -- 'firebase' sekarang; nanti 'password', 'google', ...
  subject text NOT NULL,         -- uid Firebase / id dari provider
  user_id uuid NOT NULL REFERENCES users ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (provider, subject)
)
```

Middleware `authn` hanya bergantung pada interface `Verifier` (`token → provider, subject, isAnonymous`).
Handler lain hanya melihat `users.id`. Ganti auth = tambah implementasi `Verifier` baru.

### 3.2 Domain

Sumber kebenaran skema: **`backend/db/migrations/00001_init.sql`** (sudah ditulis & diuji di B0 terhadap
PostgreSQL 16). Ringkasannya:

- Semua tabel per-user `user_id uuid REFERENCES users ON DELETE CASCADE`, **kecuali** `purchases`
  (`ON DELETE SET NULL` + `user_hash`, disimpan untuk sengketa/refund) dan `admin_audit_log`.
- `wallets`: `earned_coins`, `purchased_coins`, `debt_coins`, `lifetime_earned`, `lifetime_spent`,
  semua `CHECK >= 0`.
- `coin_ledger`: **satu baris per event bisnis** dengan `earned_delta` / `purchased_delta` / `debt_delta`
  (belanja yang memotong dua bucket tetap satu baris idempoten), `UNIQUE (user_id, idempotency_key)`,
  `CHECK (amount = earned_delta + purchased_delta)`.
- `streaks.current_days/longest_days`, `monster_progress` (progress 0–100), `subscriptions`,
  `inventory`, `consumables`, loadout, `focus_tickets`, `appbeku_unlocks` (hanya hitungan & harga),
  `daily_counters`, `journal_pin_backups`, `pin_attempts`, `idempotency_keys`, `content_items`,
  `waitlist` (`citext`), `app_settings`, `admins`, `admin_audit_log`, `rtdn_messages`, `deleted_users`,
  `signup_counters`, `appcheck_jti`.
- Hak `riung_app` diatur di migrasi yang sama: `coin_ledger` & `admin_audit_log` append-only,
  `purchases` hanya update kolom status, tanpa DDL. Penghapusan akun tetap bisa cascade karena aksi
  referensial dijalankan dengan hak pemilik tabel — diverifikasi oleh tes integrasi
  `internal/database/database_integration_test.go`.

Tabel tambahan (idempotensi, loadout, admin, dll) ada di `docs/backend-api-spec.md` §7.

Saldo yang ditampilkan = `earned_coins + purchased_coins`. Belanja biasa memotong `purchased_coins`
dulu (sama seperti `WalletNotifier.spend` sekarang); buka-waktu Aplikasi Beku hanya boleh memotong
`earned_coins`.

**Konkurensi**: setiap mutasi wallet = satu transaksi DB, `SELECT … FROM wallets WHERE user_id=$1 FOR UPDATE`,
lalu `INSERT INTO coin_ledger … ON CONFLICT (user_id, idempotency_key) DO NOTHING`. Kalau konflik,
kembalikan hasil lama (replay aman). CHECK `>= 0` jadi pengaman terakhir.

## 4. API v1

Daftar lengkap endpoint, format request/response, keamanan, rate limit, dan logging ada di
**`docs/backend-api-spec.md`**. Ringkasnya (35 endpoint):

- Sistem & publik: `healthz`, `readyz` (internal), `GET /v1/config` (ekonomi + katalog), `GET /v1/content/{kind}`, `POST /v1/waitlist`.
- Akun: `GET /v1/me` (bootstrap + buat akun baru), `PATCH /me/profile`, `PUT /me/assessment`, `POST /me/link`, `DELETE /me`, `GET /me/export`, backup PIN jurnal (+ `verify`).
- Latihan: `POST /v1/activities` (+ `/batch` untuk outbox offline) — check-in, jurnal, meditasi, Better Me, misi, minigame, fokus selesai. Server menghitung koin, progres monster, streak.
- Jurnal: `GET /v1/journal/access` — cek jurnal/prompt premium atau tidak, batas gratis harian, boleh menulis atau tidak.
- Wallet: `GET /v1/wallet`, `GET /v1/wallet/transactions`, `POST /v1/premium/daily-coins`.
- Toko & loadout: `POST /v1/shop/purchase`, `PUT /v1/loadouts/monsters/{id}`, `PUT /v1/loadouts/characters/{testId}`.
- Fokus: `POST/GET /v1/focus/tickets` (tiket Ed25519, jalan offline).
- Aplikasi Beku: `POST /v1/appbeku/unlocks` (maks 3/hari, +10, jeda 60 dtk, koin latihan saja).
- Billing: `POST /v1/billing/verify`, `POST /v1/billing/restore`, `GET /v1/billing/subscription`, `POST /v1/webhooks/google-play`.
- Admin (port internal `8081`, hanya via VPN + claim `riungAdmin`): `GET/PUT/DELETE /admin/v1/settings/{key}`, `GET /admin/v1/audit` — untuk batas koin harian jurnal & meditasi dan batas akun baru per IP.

Tidak ada endpoint `spend` generik dan tidak ada endpoint yang menghubungkan pembelian dengan progres
monster (aturan #4).

## 5. Aturan bisnis server

- **Nominal earn** (dari `economy`): check-in 5, jurnal 4, meditasi 3, misi 3, menang game 8, jinak 50,
  Better Me 10, streak 7 hari 20, 30 hari 100, koin harian tahunan 2.
- **Idempotency key** per jenis: `checkin:<date>`, `journal:<entryId>`, `meditation:<sessionId>:<date>`,
  `mission:<date>:<index>`, `minigame:<ref>`, `betterme:<lessonId>`, `premium_daily:<date>`, `tamed:<saboteur>`.
- **Cap harian** via `daily_counters` (hari dihitung di `users.tz`):
  check-in 1 · **misi 3** (jumlah misi harian di Beranda = 3, jadi maks 3 × 3 = 9 koin/hari dari misi) ·
  pertarungan minigame (menang + kalah) ≤ `maxFightPerHari` (4) · buka-waktu berbayar 3 · koin harian
  tahunan 1 · jurnal & meditasi yang dapat koin sesuai pengaturan admin (`journalRewardsPerDay`,
  `meditationRewardsPerDay`). Melewati cap → tanpa koin & tanpa progres monster, bukan error.
  `occurredAt` diterima maks 7 hari ke belakang (antrian offline) dan maks 5 menit ke depan.
  Angka cap masuk `economy-props.json` (`missionsPerDay: 3`, dst), bukan hardcode.
- **Premium**: status dari `subscriptions.expires_at` + grace 3 hari. Koin harian tahunan hanya untuk
  plan `premium_yearly` aktif, masuk bucket `purchased`.
- **Tiket serangan** (minigame) tetap lokal di v1 — tidak dijual (baik dengan uang maupun koin),
  tidak bernilai uang. Server hanya membatasi `minigame_finished` maks 4/hari.
- **Sesi Fokus gratis harian** (1 / Premium 3) dijatah server lewat tiket `free_daily` bertanda tangan
  yang diambil di muka saat online, jadi tetap jalan offline (spec §3.7).

## 6. Sumber kebenaran angka ekonomi (disetujui)

`CLAUDE.md` merujuk `docs/economy-props.json`, tapi file itu **belum ada**; angka sekarang tersebar di
`economy.dart`, `assets/remote_config_defaults.json`, dan allowlist `firestore.rules`.

Rencana:
1. Buat `docs/economy-props.json` (+ `docs/catalog.json` untuk kosmetik/aksesori/gaya kartu/bundel dari
   `toko_data.dart`, `kenali_dirimu_config.dart`, `appbeku_catalog.dart`).
2. Go meng-embed file itu (`internal/economy`, `internal/catalog`).
3. Tes parity di Flutter (`test/economy_parity_test.dart`) memastikan `economy.dart` == JSON.
4. App menampilkan harga dari `GET /v1/config` (simpan cache, fallback `economy.dart` saat offline).
   Harga & reward **tidak lagi diatur dari Remote Config**; Remote Config tetap untuk saklar fitur dan
   uji A/B tampilan.
5. Ubah harga = ubah `economy-props.json` + deploy.
6. Pengecualian yang bisa diubah admin **tanpa deploy** (tabel `app_settings`, Admin API — spec §3.11):
   `journalRewardsPerDay`, `meditationRewardsPerDay`, `maxNewAccountsPerIpPerDay`. Key lain hanya
   ditambahkan ke allowlist lewat perubahan kode yang di-review.

## 7. Akun anonim — tercatat di server sejak awal

Keputusan: akun anonim **langsung tercatat di server**, tidak lagi "lokal-dulu".

- Saat app pertama dibuka, Firebase sign-in anonim (memang sudah butuh internet sekarang) → panggilan
  pertama `GET /v1/me` membuat user anonim di server dengan wallet 0. Semua koin, monster, streak,
  kosmetik sejak menit pertama sudah di server.
- **Daftar/link akun** (anonim → email/Google): Firebase `linkWithCredential` mempertahankan uid yang
  sama, jadi server cukup diberi tahu lewat `POST /v1/me/link` (`is_anonymous=false`). Tidak ada lagi
  "salin snapshot" — `migrateAnonymousSnapshot` dan aturan `isValidNewUserDoc` hilang.
- **Masuk ke akun lain yang sudah ada** dari perangkat yang tadinya anonim: progres anonim **tidak
  digabung** (sama seperti perilaku sekarang); akun anonim lama ditinggal dan nanti dibersihkan.
- **Pembersihan**: `riung cleanup-anon` (cron harian) menghapus user anonim yang tidak aktif
  > 90 hari (baris DB + user Firebase Auth). Angka 90 hari masuk config.
- **Pembelian** tetap mensyaratkan akun permanen (guard `ensureAccountForPurchase` dipertahankan) —
  supaya uang user tidak hilang kalau app di-uninstall saat masih anonim.
- Saat offline, event earn/progres masuk antrian lokal (outbox) dan dikirim ulang saat online dengan
  idempotency key; saldo di layar menampilkan angka terakhir dari server + penanda "menunggu sinkron".

## 8. Docker & deploy (VPS `76.13.20.72`, stack `core-shared`)

### 8.1 Kondisi server (dicek read-only 2026-10-11)

- Ubuntu 24.04, 2 vCPU, RAM 7,8 GB (±4,9 GB tersedia), disk 96 GB (21% terpakai). Docker 29.4 + Compose v5.1.
- Semua app berbagi stack `/var/www/core-shared` (repo git, branch produksi `grafana`) dan network
  `vps-shared-net` (172.19.0.0/16, IP statis per container). Panduan resminya:
  `/var/www/core-shared/INTEGRASI-APP-BARU.md` — plan ini mengikutinya.
- **Nginx**: container `shared-nginx` (nginx 1.30) memegang port 80/443; satu file per domain di
  `core-shared/nginx/conf.d/`; default server menolak host tak dikenal (403). TLS dari certbot webroot,
  diperpanjang otomatis oleh cron root harian 03:00. Belum ada `limit_req`/`real_ip` global.
- **DNS** `e55techlab.com` di Cloudflare, subdomain lain **DNS-only** (langsung ke IP VPS, bukan
  proxy Cloudflare) → `$remote_addr` di nginx = IP asli client. `riung.e55techlab.com` **belum ada**.
- **PostgreSQL**: `shared-postgres` = `postgres:16-alpine` (16.13), IP `172.19.0.14`, publish hanya
  `127.0.0.1:5432`. Isi: DB `n8n` (31 MB) + `postgres`. Satu-satunya role: `n8n` (**superuser**).
  `pg_hba`: `host all all all scram-sha-256` untuk koneksi dari network Docker; `ssl = off`;
  `max_connections 100`, `shared_buffers 128MB` (default); extension `pgcrypto`, `citext`,
  `pg_stat_statements` tersedia. Dokumentasi core-shared menandai container ini "khusus n8n —
  jangan dipakai app baru"; diputuskan tetap dipakai untuk riung dengan DB & role terpisah (§11 #3).
- **Backup**: tidak ada backup Postgres otomatis (crontab hanya certbot renew; `/root/backups` tidak ada).
- **Logging**: Promtail mengambil stdout semua container → Loki → Grafana (`grafana.e55techlab.com`).
- **IP bebas** di `vps-shared-net`: `172.19.0.16`–`.19`, `.23+` (`.5`, `.10`–`.15` sudah dipesan).
- **Firewall (ufw)**: 80, 443, 22, 8443 (SSH), 1194/udp, 1195 terbuka.

### 8.2 Container riung

Folder `/var/www/riung`, `docker-compose.prod.yml` mengikuti aturan core-shared (tanpa `ports:`, network
`external: true`, `restart: unless-stopped`, `TZ: Asia/Jakarta`, `container_name` eksplisit):

| Container | IP | Isi |
|---|---|---|
| `riung-api` | `172.19.0.16` | `riung api` di port internal `8080` (publik via nginx) dan `8081` (Admin API, **tidak** di nginx, hanya dari VPN `172.19.0.7`), healthcheck `riung healthcheck` |
| `riung-migrate` | `172.19.0.17` | one-shot `riung migrate up` (role `riung_migrator`), `restart: "no"`, dijalankan saat deploy sebelum `riung-api` di-recreate |

`riung cleanup` (pembersihan harian tabel bantu) dan nanti `riung cleanup-anon` dijalankan dari cron
host via `docker exec riung-api /riung …` (tidak perlu container ketiga).

**Dockerfile** multi-stage: `golang:<versi>-alpine` build `CGO_ENABLED=0 go build -trimpath
-ldflags="-s -w"` → `gcr.io/distroless/static-debian12:nonroot`. Satu binary `riung` dengan subcommand
`api | migrate | cleanup-anon | seed-content | settings | admin | healthcheck`; migrasi di-embed.

### 8.3 Database `riung` di `shared-postgres`

`deploy/sql/create-riung-db.sql` (dijalankan sekali oleh admin via `docker exec -i shared-postgres psql -U n8n`):
- `CREATE ROLE riung_migrator LOGIN` (pemilik DB, schema & semua tabel, boleh DDL) dan
  `CREATE ROLE riung_app LOGIN` dengan hak terbatas per tabel (spec §4.5): `coin_ledger` &
  `admin_audit_log` hanya `INSERT/SELECT`, `purchases` + `UPDATE` kolom status saja, tabel lain DML biasa.
  **Keduanya bukan superuser.** Grant ditulis di migrasi supaya tabel baru tidak lupa diatur.
- `CREATE DATABASE riung OWNER riung_migrator`; `REVOKE ALL ON DATABASE riung FROM PUBLIC`;
  `CREATE EXTENSION citext` (dan `pgcrypto` bila perlu).
- `DATABASE_URL=postgres://riung_app:…@shared-postgres:5432/riung?sslmode=disable` — trafik tetap di
  bridge network Docker, tidak keluar host. Pool `pgx` maks 10 koneksi (max_connections 100 dipakai
  bersama n8n).
- **Dokumentasi core-shared** ikut diubah (commit ke branch `grafana`): `CLAUDE.md` & `README.md` tabel
  container (`shared-postgres` → "n8n + riung"), `INTEGRASI-APP-BARU.md` tabel layanan. Catatan operasional:
  restart/upgrade `shared-postgres` sekarang berdampak ke n8n **dan** riung — jadwalkan di luar jam sibuk.
- **Backup baru** (cron host, harian): `docker exec shared-postgres pg_dump -Fc -U riung_migrator riung`
  ke `/var/backups/riung/`, retensi 14 hari, salin off-site; uji restore sebelum rilis. Disarankan
  sekalian menambah dump `n8n` di cron yang sama (saat ini juga tanpa backup).

### 8.4 Nginx `riung.e55techlab.com` (Template B core-shared)

1. Cloudflare: `A riung → 76.13.20.72`, **DNS only** (sama seperti subdomain lain).
2. `core-shared/nginx/conf.d/riung.e55techlab.com.conf` versi HTTP-only (ACME challenge) →
   `docker exec shared-nginx nginx -t` → `nginx -s reload`.
3. `docker compose run --rm certbot certonly --webroot … -d riung.e55techlab.com` (coba `--dry-run` dulu).
4. Ganti ke config final (`deploy/nginx/riung.e55techlab.com.conf` di repo ini): redirect 80→443,
   header keamanan, `client_max_body_size 1M`, `resolver 127.0.0.11` + `set $riung_upstream
   http://riung-api:8080` (supaya nginx tetap hidup kalau riung-api mati), tanpa baris WebSocket,
   `limit_req`/`limit_conn` sesuai spec §5.1, `location / { return 404; }` untuk path di luar `/v1/` &
   `/healthz` → `nginx -t` → reload. Port `8081` (Admin API) **tidak** dipasang di nginx.
5. Go hanya mempercayai `X-Real-IP` dari `shared-nginx` (`172.19.0.2`); `X-Forwarded-For` diabaikan
   karena bisa diisi client (spec §4.1).
6. Update `core-shared/CLAUDE.md` + `README.md` (IP terpakai, tabel domain) dan commit ke branch
   `grafana` sesuai Langkah 10 panduan.

> ⚠️ Semua domain berbagi satu nginx: config yang salah menjatuhkan **semua** situs. Selalu `nginx -t`
> sebelum reload.

### 8.5 Secrets, logging, CI

- **Secrets** di `/var/www/riung/.env` (`chmod 600`, tidak di repo): `DATABASE_URL`,
  `MIGRATE_DATABASE_URL`, `FIREBASE_PROJECT_ID`, path service account (scope Firebase Auth + Android
  Publisher — service account **khusus**, bukan key `firebase-adminsdk` bawaan), `TICKET_SIGNING_KEYS`,
  `RTDN_AUDIENCE`, `CORS_LANDING_ORIGIN`, `PIN_PEPPER`, `LOG_PEPPER`, `IP_HASH_KEY`,
  `BILLING_ACCOUNT_KEY`, `APP_CHECK_MODE`, `ADMIN_LISTEN_ADDR`, `ADMIN_ALLOWED_CIDRS`.
  `MIGRATE_DATABASE_URL` hanya diberikan ke service `riung-migrate`; `riung-api` tidak pernah memegang
  kredensial DDL.
- **Log**: `slog` JSON ke stdout → otomatis masuk Loki. Label hanya `level` & `event` (jangan
  `user_id`/`request_id` — panduan core-shared). Tanpa PII, tanpa isi konten. Retensi **30 hari** khusus
  `riung-api` lewat `retention_stream` Loki (global VPS tetap 7 hari) — detail di spec §6.5.
- **CI** (`.github/workflows/backend.yml`, `paths: backend/**`): `go vet`, `golangci-lint`, `sqlc diff`,
  `go test -race` (Postgres 16 sebagai service container GitHub Actions), govulncheck, Trivy, build &
  push `ghcr.io/krisna-achmad31/riung-api:<sha>` (hanya dari `main`), lalu
  deploy via SSH ke user `deploy` (key-only, anggota grup `docker`): `docker compose pull` →
  `docker compose run --rm riung-migrate` → `docker compose up -d riung-api`. VPS butuh
  `docker login ghcr.io` dengan token read-only. Workflow Flutter yang ada diberi
  `paths-ignore: backend/**`.

## 9. Di luar backend

Perubahan app Flutter, landing, infra VPS, Firebase/Google Cloud, dan keputusan produk yang masih
terbuka dicatat di **`docs/todo-luar-backend.md`**. Dokumen ini dan spec hanya mengatur `backend/`.

## 10. Fase kerja & gate

| Fase | Isi | Gate |
|---|---|---|
| **B0 Fondasi** ✅ | skeleton `backend/`, config, slog, `/healthz`, goose, compose dev (dengan Postgres 16 lokal), Dockerfile, CI | `docker compose up` → `/readyz` 200; CI hijau |
| **B1 Identitas & konten** ✅ | `users` + `auth_identities`, `Verifier` Firebase + App Check, auto-create user (termasuk anonim), `/v1/me/link`, profil/asesmen/streak, content + `riung seed-content`, waitlist | Flutter dev build (`BACKEND=go`) membuat user anonim di server & membaca konten dari Go |
| **B2 Ekonomi** ✅ | `economy-props.json` + katalog, wallet ledger + bucket, activities + cap, check-in/streak, monster progress, shop, Admin API + `app_settings` | tes konkurensi (N request paralel, saldo tidak pernah negatif/dobel), tes idempotensi, tes parity ekonomi |
| **B3 Billing** ✅ | `/billing/verify` & `/billing/restore` & `/billing/subscription`, RTDN Pub/Sub (OIDC), `riung billing-sync` (refund → tarik koin/utang, cabut Premium, acknowledge yang terlewat), `riung reconcile`, Premium status | beli sandbox dengan license tester: koin & Premium masuk HANYA lewat server |
| **B4 Fokus & Aplikasi Beku** | tiket bertanda tangan + consume, unlock dengan cap/eskalasi/jeda | Fokus jalan offline penuh; rekonsiliasi idempoten; unlock ke-4 ditolak |
| **B5 Deploy** | artefak deploy siap pakai (compose prod, nginx conf, SQL DB/role, snippet Loki/Promtail, workflow deploy), deploy `riung-api`, cron `cleanup-anon`. Langkah infra & cutover app ada di `docs/todo-luar-backend.md` §A–B | `https://riung.e55techlab.com/healthz` 200 dari luar; `/readyz` 200 dari dalam; smoke test semua endpoint |
| **B6 Produksi** | App Check `enforce`, query alert Grafana, uji beban (k6), security review | p95 < 200 ms di beban target |
| **Nanti: Auth sendiri** | implementasi `Verifier` baru + endpoint login/daftar/reset, tambah baris `auth_identities` untuk user lama saat mereka login, lalu lepas Firebase Auth | user lama tetap punya data yang sama setelah pindah auth |

## 11. Status keputusan

| # | Pertanyaan | Keputusan |
|---|---|---|
| 1 | Auth | Firebase Auth dulu, nanti auth sendiri → skema identitas terpisah (§3.1) |
| 2 | Akun anonim | Tercatat di server sejak anonim (§7) |
| 3 | Postgres | `shared-postgres` (PG 16) di VPS, DB + role `riung` sendiri, bukan superuser (§8.3); dokumentasi core-shared diperbarui |
| 4 | Server | VPS `76.13.20.72` (stack core-shared, di belakang `shared-nginx`), domain `riung.e55techlab.com` (§8) |
| 5 | Data Firestore | Tidak ada user sungguhan → tanpa migrasi, mulai DB kosong |
| 6 | Sumber harga | Disetujui: server sumber harga, Remote Config hanya saklar fitur/A-B (§6) |
| 7 | Misi harian | 3 misi/hari (dari daftar misi Beranda) → cap 3 klaim/hari |
| 8 | Batas koin jurnal & meditasi | Diatur admin lewat Admin API (`journalRewardsPerDay`, `meditationRewardsPerDay`, default 3) |
| 9 | Retensi log | 30 hari untuk `riung-api` (per-stream di Loki) |
| 10 | Akun baru per IP | Maks 10/hari, bisa diubah admin (`maxNewAccountsPerIpPerDay`) |
