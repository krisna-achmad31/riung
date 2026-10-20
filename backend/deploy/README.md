# Runbook deploy — riung backend

Server: VPS `76.13.20.72` (SSH port 8443), stack bersama `/var/www/core-shared`.
Domain: `https://riung.e55techlab.com`. Rancangan lengkap: `docs/backend-go-plan.md` §8.

## Gambaran alur

```
push ke main / feat/go-backend, atau Run workflow (deploy ✓)
   │
   ▼
GitHub Actions (.github/workflows/backend.yml)
   1. test   : go vet, go test -race (+ Postgres 16), govulncheck, golangci-lint
   2. image  : docker build (linux/amd64) → scan Trivy → push ghcr.io/krisna-achmad31/riung-api:<sha 7>
   3. deploy : hanya Run workflow dengan deploy ✓ (atau push ke main bila vars.RIUNG_DEPLOY_ENABLED)
               → backend-deploy.yml (rollback: Run workflow dengan rollback_tag, tanpa test/build)
               ssh deploy@VPS check          → hash deploy.sh + compose harus sama dengan commit
               ssh deploy@VPS deploy <sha 7> → /usr/local/bin/riung-ci-deploy (forced command)
               smoke test /healthz + /v1/config
   │
   ▼
VPS /var/www/riung/deploy.sh <image>
   a. pull image dari GHCR (login sementara dengan GITHUB_TOKEN job; tidak ada token GHCR tersimpan di VPS)
   b. riung-migrate (sekali jalan, kredensial DDL) → `riung migrate up`
      gagal? → deploy berhenti, API lama tetap jalan
   c. recreate riung-api (172.19.0.16) dengan image baru
   d. tunggu healthcheck "healthy" (maks 60 dtk), kalau tidak → exit 1 + tampilkan log
   │
   ▼
Internet → shared-nginx (TLS, rate limit) → riung-api:8080 → shared-postgres:5432 (DB riung)
riung-api stdout (JSON) → Promtail → Loki (30 hari) → Grafana
```

Image kecil (±60 MB — sebagian besar SDK Google/Firebase — distroless, user `nonroot`, filesystem read-only, tanpa port ke host). Kredensial
DDL hanya ada di `riung-migrate`; `riung-api` hanya memegang role `riung_app`.

## A. Setup pertama (sekali)

Jalankan sebagai root di VPS kecuali disebut lain.

**1. User deploy & SSH** (dibuat 2026-10-19; lihat juga `docs/todo-luar-backend.md` §A)

```sh
useradd -m -s /bin/bash -G docker -c "riung deploy (CI + admin, key only)" deploy
usermod -p '*' deploy                # tanpa password sama sekali → hanya bisa login dengan key
install -d -m 700 -o deploy -g deploy /home/deploy/.ssh
install -m 755 riung-ci-deploy.sh /usr/local/bin/riung-ci-deploy    # dari backend/deploy/
# /home/deploy/.ssh/authorized_keys (owner deploy, chmod 600):
#   restrict,command="/usr/local/bin/riung-ci-deploy" ssh-ed25519 AAAA… riung-ci@github-actions
#   ssh-ed25519 AAAA… admin-laptop                     # admin: shell biasa sebagai deploy
cd /var/www/riung && chgrp deploy . .env .env.migrate deploy.sh && chmod 750 . deploy.sh && chmod 640 .env .env.migrate
```

Grup `docker` setara akses root ke Docker, karena itu kunci CI dibatasi forced command: hanya `check`
(hash `deploy.sh` + compose) dan `deploy <sha>` (hex 7–40 karakter); shell, `scp`, port forwarding, dan
injeksi argumen ditolak (diuji 2026-10-19). Private key CI hanya ada di secret GitHub `VPS_DEPLOY_KEY`.

Masih terbuka (TODO P0): `PermitRootLogin prohibit-password`, `PasswordAuthentication no` (ingat
`50-cloud-init.conf` menimpa jadi `yes`), `systemctl reload ssh` — uji login key dari terminal lain
sebelum menutup sesi.

**2. Salin artefak deploy** (dari laptop, folder repo)

```sh
scp -P 8443 -r backend/deploy/docker-compose.prod.yml backend/deploy/deploy.sh \
  backend/deploy/env.example backend/deploy/env.migrate.example \
  backend/deploy/nginx backend/deploy/sql backend/deploy/monitoring deploy@76.13.20.72:/var/www/riung/
```

`docker-compose.prod.yml` dan `deploy.sh` disalin **oleh admin** (root atau `deploy` dengan key laptop) setiap
kali berubah; kunci CI tidak bisa menulis file. Deploy CI berhenti bila salinan di VPS beda dengan commit.

**3. Database `riung` di shared-postgres** (password hex supaya aman dipakai di URL)

```sh
cd /var/www/riung
MIG_PW="$(openssl rand -hex 32)"; APP_PW="$(openssl rand -hex 32)"
docker exec -i -e RIUNG_MIGRATOR_PASSWORD="$MIG_PW" -e RIUNG_APP_PASSWORD="$APP_PW" \
  shared-postgres psql -U n8n -d postgres -v ON_ERROR_STOP=1 < sql/create-riung-db.sql
```

Script berhenti (exit 3) bila password kosong/< 16 karakter. Simpan kedua password untuk langkah 4.

**4. File env** (`/var/www/riung`, `root:deploy`, `chmod 640`)

- `.env` dari `env.example` — `DATABASE_URL` (riung_app + `$APP_PW`), `TRUSTED_PROXIES=172.19.0.2/32`,
  `LOG_PEPPER`, `IP_HASH_KEY`, `PIN_PEPPER`, `BILLING_ACCOUNT_KEY` (masing-masing `openssl rand -hex 32`,
  semuanya berbeda), `FOCUS_TICKET_KEY` (`openssl rand -base64 32`), `FIREBASE_PROJECT_ID`,
  `FIREBASE_CREDENTIALS_FILE`, `APP_CHECK_MODE=monitor`,
  `CORS_LANDING_ORIGIN`, `MIN_APP_VERSION`. API menolak start bila ada yang kurang.
- `.env.migrate` dari `env.migrate.example` — `MIGRATE_DATABASE_URL` (riung_migrator + `$MIG_PW`).

**4b. Service account Firebase** — buat service account khusus (peran *Firebase Authentication Admin*),
unduh key JSON, simpan sebagai `/var/www/riung/secrets/firebase-service-account.json`, lalu
`chown 65532:65532` dan `chmod 400` (container berjalan sebagai uid 65532). Jangan pakai key
`firebase-adminsdk` bawaan.

**4c. Google Play billing** (bisa menyusul; tanpa ini `PLAY_PACKAGE_NAME` dikosongkan dan
`/v1/billing/*` menjawab 503)

1. Google Cloud project `riung-5e979` → aktifkan *Google Play Android Developer API* dan *Cloud Pub/Sub API*.
2. Buat service account `riung-play` (tanpa peran GCP), unduh key JSON →
   `/var/www/riung/secrets/play-service-account.json` (`chown 65532:65532`, `chmod 400`).
3. Play Console → *Users and permissions* → undang email `riung-play@…` dengan izin aplikasi Riung:
   *View financial data* dan *Manage orders and subscriptions* (tanpa izin lain).
4. Pub/Sub: topic `play-rtdn`; beri `google-play-developer-notifications@system.gserviceaccount.com`
   peran *Pub/Sub Publisher* di topic itu. Buat service account `riung-rtdn-push` (tanpa peran), lalu
   subscription **push** ke `https://riung.e55techlab.com/v1/webhooks/google-play` dengan *Enable
   authentication* = `riung-rtdn-push@…` dan audience = URL yang sama (`RTDN_AUDIENCE`). Retry policy:
   exponential backoff; acknowledgement deadline 60 detik; retensi pesan 7 hari.
5. Play Console → *Monetization setup* → *Real-time developer notifications*: topic
   `projects/riung-5e979/topics/play-rtdn`, lalu **Send test notification** → di log harus muncul
   `rtdn_received` dengan `kind=test`.
6. Isi `PLAY_*`/`RTDN_*` di `.env` (lihat `env.example`), `./deploy.sh` ulang.

**4d. App Store billing (iOS)** (**aktif sejak 2026-10-20**, lihat §G; tanpa `APPSTORE_BUNDLE_ID`,
`/v1/billing/appstore/*` menjawab 503 dan `/v1/webhooks/app-store` 404)

Langkah lengkap di sisi Apple (akun, App ID, produk, key, sandbox, App Review): `docs/panduan-apple-developer.md`.

1. Apple Developer Program aktif (tim yang sama dengan sertifikat build iOS); App ID `id.riung.riung`
   (bundle id iOS, sama dengan package Android) dengan capability *In-App Purchase* (dan *Sign in with Apple* bila dipakai).
2. App Store Connect → *Business*: perjanjian **Paid Apps**, data bank & pajak lengkap — tanpa ini produk
   tidak bisa dibeli, juga di sandbox.
3. App Store Connect → app → *Monetization*: consumable `coin_pack_small|medium|large`; subscription group
   (mis. "Riung Premium") berisi `premium_monthly` dan `premium_yearly`; *introductory offer* gratis 7 hari.
   Harga per negara diatur di sini (app menampilkan `ProductDetails.price`).
4. *Users and Access → Integrations → In-App Purchase* → buat key → unduh `.p8` (**hanya sekali**), catat
   Key ID dan Issuer ID. Simpan sebagai `/var/www/riung/secrets/appstore-iap-key.p8` (`chown 65532:65532`,
   `chmod 400`) dan salinannya di password manager.
5. App → *App Information → App Store Server Notifications*: **Version 2**, URL production **dan** sandbox =
   `https://riung.e55techlab.com/v1/webhooks/app-store` (nginx tidak perlu diubah).
6. Isi `APPSTORE_*` di `.env` (lihat `env.example`; `APPSTORE_APP_APPLE_ID` = Apple ID numerik app). Cek dulu
   tanpa menyentuh API yang jalan: `docker run --rm --env-file .env -v "$PWD/secrets:/run/secrets:ro" <image>
   appstore-check` (sandbox harus menerima key; production menjawab `401` sampai app rilis pertama — WARN, bukan
   gagal). Lalu deploy ulang (Run workflow); log start harus `"appStore":true`.
6b. `docker exec riung-api /riung appstore-check --notify` → Apple mengirim notifikasi TEST ke URL sandbox (dan
   production setelah rilis); hasil harus `SUCCESS` dan log `rtdn_received` `store=app_store` `kind=test`.
7. Uji: akun sandbox (*Users and Access → Sandbox*) / TestFlight beli tiap paket & langganan → log
   `purchase_verified` dengan `test=true`; notifikasi sandbox → `rtdn_received` `store=app_store`; refund
   sandbox → `refund_applied`.

**5. Akses GHCR** — tidak ada login tersimpan di VPS. Deploy CI mengirim `GITHUB_TOKEN` job (berlaku sampai
job selesai) lewat stdin; `riung-ci-deploy` memakainya untuk satu `docker login` di direktori config sementara.
Pull manual (jarang perlu — image yang pernah di-deploy tetap ada di VPS):

```sh
export DOCKER_CONFIG="$(mktemp -d)"   # token tidak tertinggal di ~/.docker
echo "$GHCR_READ_TOKEN" | docker login ghcr.io -u <github-user> --password-stdin   # PAT read:packages
docker pull ghcr.io/krisna-achmad31/riung-api:<sha>; rm -rf "$DOCKER_CONFIG"
```

**6. DNS** — Cloudflare: `A riung → 76.13.20.72`, **DNS only**. Cek: `dig +short riung.e55techlab.com`.

**7. Nginx + TLS** (satu nginx untuk semua situs — selalu `nginx -t` sebelum reload)

```sh
cd /var/www/core-shared
cp /var/www/riung/nginx/riung.e55techlab.com.bootstrap.conf nginx/conf.d/riung.e55techlab.com.conf
docker exec shared-nginx nginx -t && docker exec shared-nginx nginx -s reload
docker compose run --rm certbot certonly --webroot --webroot-path=/var/www_certbot \
  --email admin@e55techlab.com --agree-tos --non-interactive -d riung.e55techlab.com --dry-run
# kalau dry-run sukses, ulangi tanpa --dry-run
cp /var/www/riung/nginx/riung.e55techlab.com.conf nginx/conf.d/riung.e55techlab.com.conf
docker exec shared-nginx nginx -t && docker exec shared-nginx nginx -s reload
```

Perpanjangan sertifikat sudah ditangani cron certbot core-shared (03:00).

**8. Monitoring** — gabungkan `monitoring/loki-retention.snippet.yml` ke
`core-shared/monitoring/loki/config.yml` dan `monitoring/promtail-riung.snippet.yml` ke config Promtail,
lalu `docker compose up -d --force-recreate loki promtail` di core-shared. Retensi 30 hari untuk
`riung-api`/`riung-migrate` terpasang 2026-10-19 (`-verify-config` dulu, cadangan
`config.yml.bak-2026-10-19`, `docker restart shared-loki`); stage `json` Promtail belum.

**8b. Alarm Telegram & watchdog** (terpasang 2026-10-20; konvensi `core-shared`: aplikasi mengirim alarm
sendiri, Grafana alerting tetap kosong — spec §6.6)

1. Bot Telegram (@BotFather) + chat penerima. Penerima **wajib** membuka bot dan menekan *Start* sekali; tanpa
   itu Telegram menjawab `400 chat not found`.
2. `.env`: `ALERT_TELEGRAM_BOT_TOKEN`, `ALERT_TELEGRAM_CHAT_ID`, `ALERT_LABEL=riung prod` (cadangan `.env`
   dulu), deploy ulang → pesan 🟢 saat API start. Uji: `docker exec riung-api /riung alert-test` (menunggu
   jawaban Telegram, gagal = exit 1 dengan status Telegram).
3. Watchdog (cek dari luar API — tetap jalan saat `riung-api` mati):
   ```sh
   install -m 755 monitoring/riung-watchdog.sh /usr/local/bin/riung-watchdog
   install -m 600 monitoring/env.watchdog.example /var/www/riung/.env.watchdog
   install -d -m 700 -o 65532 -g 65532 /var/lib/riung-watchdog
   /usr/local/bin/riung-watchdog            # sekali manual: log "watchdog done" ok=true, checks=10
   ```
   Cron (langkah 9): `*/2 * * * * /usr/local/bin/riung-watchdog >/dev/null 2>&1`. State di
   `/var/lib/riung-watchdog/watchdog.json` (hapus untuk mulai ulang). Container watchdog tidak bisa membaca
   `/var/backups/riung`; skrip host mengirim nama/umur/ukuran dump terbaru lewat env.
4. `monitoring/grafana-alerting-riung.yml` (12 aturan Grafana) tidak dipasang — rujukan bila konvensi berubah.

**8c. Dashboard Grafana** (terpasang 2026-10-20; folder *VPS*: **Riung — Teknis** dari Loki, **Riung — Bisnis**
dari view `metrics`)

1. Role baca-saja (setelah migrasi `00004`): `docker exec -i -e RIUNG_METRICS_PASSWORD="$(openssl rand -hex 24)"
   shared-postgres psql -U n8n -d riung -v ON_ERROR_STOP=1 < sql/create-riung-metrics-role.sql` (aman diulang =
   ganti password).
2. Datasource lewat API Grafana (password tersimpan terenkripsi di Grafana, tidak di file): `POST /api/datasources`
   dengan `uid=riung-postgres`, `type=grafana-postgresql-datasource`, `url=shared-postgres:5432`,
   `user=riung_metrics`, `database=riung`, `sslmode=disable`, `maxOpenConns=2`. Kredensial admin Grafana =
   env `GF_SECURITY_ADMIN_*` container `shared-grafana`. Ganti password = ulangi 1 lalu `PUT
   /api/datasources/uid/riung-postgres`.
3. Dashboard: `python3 monitoring/dashboards.py monitoring` (sumber; jangan edit JSON), salin
   `grafana-dashboard-riung-*.json` ke `core-shared/monitoring/grafana/provisioning/dashboards/` (termuat dalam
   30 detik). File itu dikecualikan di `core-shared/.git/info/exclude` — sumbernya repo ini.

**9. Cron** (root, `crontab -e`). Job dijalankan di dalam `riung-api`; `LOG_TEE=/proc/1/fd/1` membuat
baris `job_run` ikut masuk log container → Loki (output `docker exec` sendiri tidak ditangkap Promtail).

```cron
# --- riung ---
# Pembersihan tabel bantu (idempotensi, jti App Check, penghitung lama, tiket Fokus & buka-berbayar > 90 hari)
15 2 * * * docker exec -e LOG_TEE=/proc/1/fd/1 riung-api /riung cleanup >/dev/null
# Akun anonim yang tidak dibuka > 90 hari (data server + user Firebase); --dry-run untuk menghitung saja
20 2 * * * docker exec -e LOG_TEE=/proc/1/fd/1 riung-api /riung cleanup-anon >/dev/null
# Refund Google Play + acknowledge yang terlewat (tiap jam). Sebelum billing dikonfigurasi hanya mencatat "skipped".
5 * * * * docker exec -e LOG_TEE=/proc/1/fd/1 riung-api /riung billing-sync >/dev/null
# Cocokkan saldo dompet dengan ledger; gagal = ada ledger_mismatch di log
45 2 * * * docker exec -e LOG_TEE=/proc/1/fd/1 riung-api /riung reconcile >/dev/null
# Watchdog: API, 5xx/p95 (Loki), job cron, umur backup → Telegram (langkah 8b)
*/2 * * * * /usr/local/bin/riung-watchdog >/dev/null 2>&1
# Backup harian, retensi 14 hari (mkdir -p /var/backups/riung && chmod 700 /var/backups/riung)
30 2 * * * docker exec shared-postgres pg_dump -Fc -U riung_migrator riung > /var/backups/riung/riung_$(date +\%F).dump && find /var/backups/riung -name '*.dump' -mtime +14 -delete
```

Salin ke penyimpanan off-site dan uji restore secara berkala. Restore (DB kosong `riung` dari
`create-riung-db.sql`, API dihentikan dulu):

```sh
docker stop riung-api
docker exec -i shared-postgres pg_restore -U riung_migrator -d riung --clean --if-exists < riung_YYYY-MM-DD.dump
docker run --rm --env-file .env --network vps-shared-net <image> reapply-deletions   # akun yang dihapus setelah backup
docker start riung-api
```

**10. Deploy pertama (manual, sebagai `deploy`)**

```sh
cd /var/www/riung && ./deploy.sh ghcr.io/krisna-achmad31/riung-api:<sha>
```

**10b. Isi konten publik** (setelah deploy pertama; ulangi kapan pun konten berubah)

```sh
docker exec -i riung-api /riung seed-content - < dummy-data-seed.json
```

**10c. Admin** (setelah orangnya pernah membuka app dan emailnya terverifikasi)

```sh
docker exec riung-api /riung admin grant admin@e55techlab.com "admin konten & batas harian"
docker exec riung-api /riung settings list
docker exec riung-api /riung settings set journalRewardsPerDay 4 "uji batas baru"   # jalur darurat tanpa VPN
```

Admin API diakses dari laptop yang tersambung VPN: `http://172.19.0.16:8081/admin/v1/settings` dengan ID
token Firebase akun admin (login ≤ 15 menit). Semua perubahan tercatat di `admin_audit_log` dan log
`admin_setting_changed`.

**11. Deploy lewat CI** (terpasang 2026-10-19) — secret repo: `VPS_HOST`, `VPS_SSH_PORT` (`8443`),
`VPS_DEPLOY_KEY` (private key CI, `ed25519 SHA256:3KcL9On+x10g3FG2ircJ9i8iAEhiv27pp2KOmGU1UIk`),
`VPS_KNOWN_HOSTS` (`ssh-keyscan -p 8443`, fingerprint dicocokkan dengan `/etc/ssh/ssh_host_*`). Deploy otomatis
saat push ke `main` hanya bila variable `RIUNG_DEPLOY_ENABLED=true` (belum diset). Environment `production`
dibuat otomatis oleh job; pemilik repo bisa menambah *required reviewers*. Ganti kunci CI: buat pasangan baru,
ganti baris `riung-ci` di `authorized_keys` dan secret `VPS_DEPLOY_KEY`.

**12. Dokumentasi core-shared** — catat IP `.16`/`.17`, domain, dan `shared-postgres` = "n8n + riung" di
`CLAUDE.md`/`README.md` core-shared, commit ke branch `grafana`.

## B. Rilis rutin

Push → CI test, build, scan, push image `:<sha 7>` ke GHCR (tanpa deploy). Deploy commit itu:

```sh
gh workflow run Backend --ref feat/go-backend -f deploy=true    # atau Actions → Backend → Run workflow
gh run watch "$(gh run list --workflow Backend --event workflow_dispatch --limit 1 --json databaseId --jq '.[0].databaseId')"
```

Kalau commit mengubah `deploy.sh` atau `docker-compose.prod.yml`, salin dulu (langkah 2), baru jalankan.
Image selalu dari CI (linux/amd64). Jangan push image hasil build Mac (arm64) ke produksi.

Cadangan bila CI tidak bisa dipakai: image dibuat lokal **untuk linux/amd64** dari commit yang sudah
di-commit, lalu dimuat langsung ke VPS (`deploy.sh` memakai image lokal tanpa pull):

```sh
SHA=$(git rev-parse --short HEAD)
docker buildx build --platform linux/amd64 --build-arg VERSION=$SHA -t ghcr.io/krisna-achmad31/riung-api:$SHA --load backend
docker save ghcr.io/krisna-achmad31/riung-api:$SHA | gzip -1 | ssh -p 8443 deploy@76.13.20.72 'gunzip | docker load'
ssh -p 8443 deploy@76.13.20.72 "cd /var/www/riung && ./deploy.sh ghcr.io/krisna-achmad31/riung-api:$SHA"
```

## C. Verifikasi setelah deploy

```sh
curl -s https://riung.e55techlab.com/healthz                    # {"status":"ok"}
curl -s -o /dev/null -w '%{http_code}\n' https://riung.e55techlab.com/readyz   # 404 (tidak publik)
docker inspect -f '{{.State.Health.Status}}' riung-api          # healthy
docker run --rm --network vps-shared-net curlimages/curl:8.10.1 -s http://riung-api:8080/readyz   # {"status":"ready"}
docker logs --tail 20 riung-api                                 # JSON, event=http_request
```

Grafana → Explore → Loki: `{container="riung-api"} | json | level="ERROR"`.

## D. Rollback

Deploy ulang tag sebelumnya (lihat CHANGELOG.md atau `gh api /users/krisna-achmad31/packages/container/riung-api/versions`):

```sh
gh workflow run Backend --ref feat/go-backend -f rollback_tag=<sha-sebelumnya>
```

Image di VPS dihapus cron `/etc/cron.d/docker-image-prune` (`docker image prune -af --filter until=24h`,
milik VPS bersama), jadi rollback mengambil image dari GHCR — hanya tag yang di-push CI (mulai `f8e9489`).
Tanpa CI: `ssh -p 8443 deploy@76.13.20.72 'cd /var/www/riung && ./deploy.sh ghcr.io/krisna-achmad31/riung-api:<sha>'`
(image harus masih ada di VPS, atau pull manual dulu — langkah 5).

Aturan migrasi supaya rollback selalu aman: perubahan skema bersifat **menambah** (kolom/tabel baru,
nullable/default) dan baru dihapus di rilis berikutnya setelah tidak dipakai (expand → contract).
`riung migrate down` ditolak di prod.

## E. Masalah umum

| Gejala | Penyebab & langkah |
|---|---|
| Deploy berhenti di "migrate" | kredensial `.env.migrate` / migrasi gagal — API lama tetap jalan. Lihat output `deploy.sh`. |
| `did not become healthy` | `docker logs riung-api` — biasanya `.env` (DATABASE_URL, secret < 32 karakter). |
| 502 dari nginx | `riung-api` mati/restart; situs lain tidak terdampak (pola `resolver`). |
| `/readyz` 503 di dalam network | shared-postgres tidak terjangkau / password `riung_app` salah. |
| Pull gagal | CI: job deploy butuh `packages: read` dan package `riung-api` harus memberi akses Actions ke repo ini; manual: lihat langkah 5. Tag salah = sha 7 karakter. |
| CI: `differ from this commit` | `deploy.sh`/compose di VPS beda dengan commit — salin (langkah A.2), jalankan ulang workflow. |
| API tidak start: `read APPSTORE_PRIVATE_KEY_FILE` / `app store: private key …` | file `.p8` tidak ada/terbaca uid 65532 di `secrets/` (`chown 65532:65532`, `chmod 400`) atau bukan key EC P-256. Selalu uji dulu dengan `appstore-check` di container sementara (langkah 4d.6). |
| Verifikasi iOS `500`, log `app store: API key rejected` | key dicabut/salah: `docker exec riung-api /riung appstore-check`. Production `401` saja (sandbox lolos) normal sampai app rilis. |
| `appstore-check --notify` bukan `SUCCESS` | URL Server Notifications di App Store Connect salah / bukan Version 2, atau webhook ditolak — cek log `rtdn_rejected` `store=app_store`. |
| Alarm tidak sampai, log `alert: telegram: status 400` | penerima belum menekan *Start* di bot, atau chat id salah (`docker exec riung-api /riung alert-test`). Status `401` = token bot dicabut. |
| Pesan "riung watchdog tidak bisa jalan" | container watchdog gagal start (image tidak ada, Docker bermasalah) — `/usr/local/bin/riung-watchdog` manual untuk melihat errornya. |
| Restart berulang setelah reboot | API menunggu Postgres ±60 detik (`database not ready, retrying`, WARN); lebih dari itu = `shared-postgres` mati. |

## F. Gladi resik lokal (2026-10-11)

Diuji di Docker Desktop dengan salinan compose produksi (subnet tiruan), registry lokal sebagai
pengganti GHCR, dan Postgres 16 sebagai `shared-postgres`:
- `create-riung-db.sql` lewat psql asli: role tanpa superuser, hak `riung_app` sesuai; tanpa password
  → berhenti exit 3.
- `deploy.sh`: deploy pertama ±9 detik sampai healthy; redeploy versi baru → "database already up to
  date", API diganti; image tidak ada → exit 1; migrasi gagal (password salah) → exit 1; pada kedua
  kegagalan API lama tetap jalan & healthy.
- Container: read-only, `cap_drop: ALL`, memori 256 MB, pids 200, user `nonroot`, tanpa port ke host,
  tidak memegang `MIGRATE_DATABASE_URL`.
- Trust proxy: request dari IP nginx memakai `X-Request-Id`/`X-Real-IP`-nya; dari container lain
  header diabaikan.

## G. Deploy pertama (2026-10-13)

Dijalankan sebagai root lewat SSH, image `ghcr.io/krisna-achmad31/riung-api:825085e` (build lokal amd64):
- Langkah 3 (DB `riung`, role `riung_migrator`/`riung_app` bukan superuser), 4 (`.env`, `.env.migrate`
  dibuat di server, `chmod 600`, secret acak baru), 4b (key `firebase-adminsdk` — **sementara**, lihat TODO
  P0), 7 (bootstrap → certbot → config final; `nginx -t` lolos di tiap langkah, situs lain tetap 200),
  9 (cron + backup pertama; crontab lama disalin ke `/root/crontab.before-riung.2026-10-13`), 10b (seed konten).
- Belum: langkah 1 (user `deploy` & pengerasan SSH), 4c (billing, `PLAY_PACKAGE_NAME` kosong → 503),
  5 (GHCR), 8 (retensi Loki 30 hari & stage `json` — `core-shared` punya perubahan orang lain yang belum
  di-commit), 10c (admin), 11 (deploy otomatis), 12 (dokumentasi core-shared).
- Hasil: `https://riung.e55techlab.com/healthz` 200 (TLS s.d. 2027-01-10, HSTS, HTTP → 301), `/readyz` &
  `/admin` 404 dari luar, `/readyz` ready dari dalam, Admin API 403 dari container non-VPN, request tanpa token
  401, `X-Request-Id` nginx diteruskan, container read-only/nonroot/`cap_drop: ALL`/256 MB, kredensial Firebase
  Admin terhubung ke Google, restore backup ke DB sementara lolos (31 tabel, migrasi v3), log `riung-api`
  (termasuk `job_run` cron) masuk Loki.
- Belum diuji dengan ID token Firebase sungguhan dari app (butuh build app yang memakai backend Go).
- Redeploy B6 (2026-10-13): image `e5f0110` + config nginx (suite TLS AEAD, header tidak ganda). Config
  sebelumnya disimpan di `/root/riung.nginx.before-b6.conf`; image `825085e` tetap ada untuk rollback.
  Dicek: header & CSP, suite CBC ditolak, situs lain tetap 200/302, field `appCheck` di log.
- Redeploy 2026-10-13: image `81f763f` (webhook billing → 404 selama billing mati, bukan 503/ERROR).
- Redeploy 2026-10-18: image `92ef4ed` (`purchaseToken` di setiap baris `/v1/billing/restore`). Sebelum deploy:
  tes + race, lint, govulncheck bersih, Newman 52 request di stack dev bersih. Di VPS kini hanya `92ef4ed`
  dan `81f763f` (image lama sempat dibersihkan) — rollback: `./deploy.sh ghcr.io/krisna-achmad31/riung-api:81f763f`.
- 2026-10-19: user `deploy` + kunci CI (forced command), retensi Loki 30 hari untuk riung, lalu **deploy pertama
  lewat CI**: `f8e9489` (API menunggu Postgres saat start) dan `6f3a51a` (kunci PIN melewati tengah malam UTC) —
  pull dari GHCR, migrasi, healthy, smoke test 200, 0 ERROR; situs lain tetap 200/302. Jalur rollback
  (`rollback_tag=6f3a51a`) diuji: container tidak dibuat ulang karena image sama. Cron prune VPS menghapus image
  > 24 jam, jadi rollback selalu lewat GHCR.
- 2026-10-20: `6d05579` lewat CI (jalur App Store siap tapi mati: log start `"appStore":false`, webhook
  `/v1/webhooks/app-store` 404; `GET /v1/me` membawa `appAccountToken`). Healthy, 0 ERROR, situs lain normal.
- 2026-10-20: App Store **diaktifkan** — `c43f374` + `APPSTORE_*` di `.env` (cadangan `.env` sebelumnya:
  `/root/riung.env.before-appstore.2026-10-20`), key `secrets/appstore-iap-key.p8` (65532, 400). Sebelum deploy:
  `appstore-check` di container sementara lolos (sandbox; production 401 karena app belum rilis). Sesudah:
  `"appStore":true`, `appstore-check --notify` → notifikasi TEST sandbox `SUCCESS`, diterima API 200 dan lolos
  verifikasi Apple Root CA G3; JWS palsu → 400. Situs lain normal.
- 2026-10-20: alarm Telegram dari aplikasi + watchdog (`7e63bf3`, `25e4266`; cron tiap 2 menit; 10 cek lolos),
  migrasi `00004` (view `metrics`), role `riung_metrics`, datasource `riung-postgres`, dashboard **Riung — Teknis**
  & **Riung — Bisnis** (36 query diuji lewat API Grafana, 0 error). Staging berdiri (§H), menunggu DNS.
  Cadangan: `/root/riung.env.before-alert.2026-10-20`, `/root/riung.deploy.sh.before-staging.2026-10-20`,
  `/root/crontab.before-watchdog.2026-10-20`.
- Catatan 2026-10-17: VPS reboot 09:40 WIB; `riung-api` gagal 4× dalam 2 detik karena `shared-postgres` belum
  menyala (nama host belum bisa di-resolve), lalu jalan normal — `restart: unless-stopped` menanganinya.

## H. Staging (`riung-staging.e55techlab.com`)

Server bersama untuk tim app dan uji rilis sebelum produksi (dibuat 2026-10-20):
- `/var/www/riung-staging`: `docker-compose.staging.yml` + `deploy.sh` yang sama (`RIUNG_COMPOSE_FILE`,
  `RIUNG_CONTAINER`), `.env` (`RIUNG_ENV=dev`, `DEV_AUTH`, `DEV_BILLING`, App Check mati, secret acak sendiri),
  `.env.migrate`, `.env.postgres` (semua `root:deploy 640`).
- **Postgres sendiri** (`riung-staging-postgres`, volume `riung-staging-pgdata`, hanya di jaringan
  `riung-staging-internal`): migrasi memberi hak ke nama role `riung_app`/`riung_migrator`, jadi staging tidak
  boleh berbagi server dengan produksi. Role dibuat dengan `sql/create-riung-db.sql` (superuser `postgres`).
- `riung-staging-api` `172.19.0.18`, 192 MB, 0,5 CPU. Tanpa Admin API, tanpa cron, tanpa alarm, tidak dipantau
  watchdog. Log masuk Loki (retensi 7 hari).
- Akses hanya dengan header `X-Riung-Staging-Key` (nginx; tanpa itu 404). Kunci: `/root/riung-staging.key` di VPS
  dan secret GitHub `RIUNG_STAGING_KEY`; nilainya hanya di config nginx VPS (dikecualikan dari git `core-shared`).

Setup yang tersisa setelah DNS `A riung-staging → 76.13.20.72` (DNS only) ada:
```sh
cd /var/www/core-shared        # bootstrap HTTP sudah terpasang
docker compose run --rm certbot certonly --webroot --webroot-path=/var/www_certbot \
  --email admin@e55techlab.com --agree-tos --non-interactive -d riung-staging.e55techlab.com --dry-run   # lalu tanpa --dry-run
sed "s/CHANGE_ME_STAGING_KEY/$(cat /root/riung-staging.key)/" /var/www/riung/nginx/riung-staging.e55techlab.com.conf \
  > nginx/conf.d/riung-staging.e55techlab.com.conf      # salin file dari repo ke /var/www/riung/nginx dulu
docker exec shared-nginx nginx -t && docker exec shared-nginx nginx -s reload
gh variable set RIUNG_STAGING_ENABLED --body true     # dari laptop: push ke feat/go-backend → deploy staging
```

Deploy: otomatis tiap push ke `feat/go-backend` (bila variable di atas `true`), atau `gh workflow run Backend
--ref feat/go-backend -f deploy_staging=true`. Manual: `ssh -p 8443 deploy@76.13.20.72 'cd /var/www/riung-staging
&& RIUNG_COMPOSE_FILE=docker-compose.staging.yml RIUNG_CONTAINER=riung-staging-api ./deploy.sh <image>'`.
Konten: `docker exec -i riung-staging-api /riung seed-content - < dummy-data-seed.json`. Reset data:
`docker compose -f docker-compose.staging.yml down` + `docker volume rm riung-staging-pgdata`, lalu buat ulang
role (langkah 3 produksi, terhadap `riung-staging-postgres`) dan deploy.
