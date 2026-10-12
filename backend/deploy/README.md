# Runbook deploy — riung backend

Server: VPS `76.13.20.72` (SSH port 8443), stack bersama `/var/www/core-shared`.
Domain: `https://riung.e55techlab.com`. Rancangan lengkap: `docs/backend-go-plan.md` §8.

## Gambaran alur

```
push/merge ke main
   │
   ▼
GitHub Actions (.github/workflows/backend.yml)
   1. test   : go vet, go test -race (+ Postgres 16), govulncheck, golangci-lint
   2. image  : docker build (linux/amd64) → scan Trivy → push ghcr.io/krisna-achmad31/riung-api:<sha>
   3. deploy : scp compose + deploy.sh → ssh deploy@VPS "./deploy.sh <image>"
   │
   ▼
VPS /var/www/riung/deploy.sh <image>
   a. pull image dari GHCR
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

**1. User deploy & SSH** (lihat juga `docs/todo-luar-backend.md` §A — ganti password root dulu)

```sh
adduser --disabled-password --gecos "" deploy
usermod -aG docker deploy            # catatan: grup docker setara akses root ke Docker
install -d -o deploy -g deploy -m 700 /home/deploy/.ssh
# tempel public key CI ke /home/deploy/.ssh/authorized_keys (chmod 600, owner deploy)
install -d -o deploy -g deploy -m 750 /var/www/riung /var/www/riung/secrets
```

Lalu `/etc/ssh/sshd_config.d/`: `PermitRootLogin prohibit-password`, `PasswordAuthentication no`
(ingat `50-cloud-init.conf` saat ini menimpa jadi `yes`), `systemctl reload ssh`. Uji login key dari
terminal lain sebelum menutup sesi.

**2. Salin artefak deploy** (dari laptop, folder repo)

```sh
scp -P 8443 -r backend/deploy/docker-compose.prod.yml backend/deploy/deploy.sh \
  backend/deploy/env.example backend/deploy/env.migrate.example \
  backend/deploy/nginx backend/deploy/sql backend/deploy/monitoring deploy@76.13.20.72:/var/www/riung/
```

CI menyalin ulang `docker-compose.prod.yml` dan `deploy.sh` di setiap deploy; sisanya hanya untuk setup.

**3. Database `riung` di shared-postgres** (password hex supaya aman dipakai di URL)

```sh
cd /var/www/riung
MIG_PW="$(openssl rand -hex 32)"; APP_PW="$(openssl rand -hex 32)"
docker exec -i -e RIUNG_MIGRATOR_PASSWORD="$MIG_PW" -e RIUNG_APP_PASSWORD="$APP_PW" \
  shared-postgres psql -U n8n -d postgres -v ON_ERROR_STOP=1 < sql/create-riung-db.sql
```

Script berhenti (exit 3) bila password kosong/< 16 karakter. Simpan kedua password untuk langkah 4.

**4. File env** (`/var/www/riung`, owner `deploy`, `chmod 600`)

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

**5. Akses GHCR** (sebagai user `deploy`; token GitHub dengan scope `read:packages` saja)

```sh
echo "$GHCR_READ_TOKEN" | docker login ghcr.io -u <github-user> --password-stdin
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
lalu `docker compose up -d --force-recreate loki promtail` di core-shared.

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

**11. Aktifkan deploy otomatis** — GitHub repo → Settings:
- Secrets: `VPS_HOST`, `VPS_SSH_PORT` (`8443`), `VPS_DEPLOY_KEY` (private key CI),
  `VPS_KNOWN_HOSTS` (`ssh-keyscan -p 8443 76.13.20.72`, cocokkan fingerprint).
- Variable: `RIUNG_DEPLOY_ENABLED=true`.
- Environment `production` (opsional: wajib persetujuan sebelum deploy).

**12. Dokumentasi core-shared** — catat IP `.16`/`.17`, domain, dan `shared-postgres` = "n8n + riung" di
`CLAUDE.md`/`README.md` core-shared, commit ke branch `grafana`.

## B. Rilis rutin

Merge ke `main` → CI otomatis test, build, scan, push, deploy. Manual (misalnya CI mati):

```sh
ssh -p 8443 deploy@76.13.20.72 'cd /var/www/riung && ./deploy.sh ghcr.io/krisna-achmad31/riung-api:<sha>'
```

Image selalu dari CI (linux/amd64). Jangan push image hasil build Mac (arm64) ke produksi.

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

Jalankan `deploy.sh` dengan tag image sebelumnya:

```sh
./deploy.sh ghcr.io/krisna-achmad31/riung-api:<sha-sebelumnya>
```

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
| Pull gagal | `docker login ghcr.io` di user `deploy` kedaluwarsa / tag salah. |

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

Belum diuji: config nginx dengan `nginx -t` dan certbot sungguhan (hanya bisa di VPS).
