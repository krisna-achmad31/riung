# Riung Backend — B6: Kesiapan produksi
*Branch `feat/go-backend` · 2026-10-13, diperbarui 2026-10-20 · pendamping `docs/backend-api-spec.md` & `docs/backend-go-plan.md`*

Isi: uji beban, review keamanan (OWASP API Top 10 2023 + infrastruktur), alert, dan kapan App Check boleh
dipindah ke `enforce`.

## 1. Uji beban — gate lolos

Detail & cara menjalankan: `backend/loadtest/README.md`. API dibatasi seperti produksi (1 CPU, 256 MB,
read-only).

| Beban | Laju | p95 | p99 | Error |
|---|---|---|---|---|
| 200 pengguna aktif (target) | 84 req/s | **11,9 ms** | 20,7 ms | 0% |
| 400 pengguna aktif (2× target) | 158 req/s | **9,0 ms** | 20,5 ms | 0% |

Gate plan §10 (p95 < 200 ms) terpenuhi dengan ruang besar. Angka di VPS dikonfirmasi saat beta dari
Loki (§3, alert `riung: p95 > 500 ms`).

## 2. Review keamanan

### 2.1 Diperbaiki di B6

| # | Temuan | Perbaikan |
|---|---|---|
| SR-1 | Rate limit per user berjalan **setelah** cek pencabutan token, jadi request yang sudah melewati batas (`/me/link`, `DELETE /me`, `billing/verify`) tetap memicu panggilan ke Firebase | urutan baru: verifikasi token lokal → rate limit → cek pencabutan (`TestRevocationCheckedAfterRateLimit`) |
| SR-2 | Respons API tanpa CSP | `Content-Security-Policy: default-src 'none'; frame-ancestors 'none'` |
| SR-3 | TLS 1.2 menerima suite CBC/SHA1 (default nginx) | `ssl_ciphers` Mozilla intermediate (AEAD saja) |
| SR-4 | `nosniff`/`Referrer-Policy` terkirim dua kali (nginx + Go) | `proxy_hide_header` di nginx |
| SR-5 | Hasil App Check tidak tercatat per request, jadi kesiapan `enforce` tidak bisa diukur; replay token limited-use hanya dicek saat `enforce` | field `appCheck` di access log; `jti` juga dicek (dicatat saja) di mode `monitor` |
| SR-6 | Output job cron tidak masuk Loki (alert job tidak akan pernah menyala) | `LOG_TEE=/proc/1/fd/1` (B5) |

### 2.2 Dicek, aman

| OWASP API 2023 | Kondisi |
|---|---|
| API1 Akses objek | user selalu dari token; tidak ada id user di path/body; tiket Fokus, pembelian, PIN dicari dengan `user_id` |
| API2 Autentikasi | ID token Firebase diverifikasi lokal; cek pencabutan + `auth_time` ≤ 5 menit untuk aksi sensitif; `DEV_AUTH`/`DEV_BILLING` ditolak di prod; Admin API: VPN + claim + tabel `admins` + login ≤ 15 menit |
| API3 Properti objek | decoder JSON ketat (field asing ditolak, satu objek saja); respons dibentuk dari struct, bukan baris DB |
| API4 Konsumsi sumber daya | rate limit per user/IP (bucket per endpoint), batas body per route, batch ≤ 50, restore ≤ 20, paging ≤ 100/200, `statement_timeout` 5 s, timeout server & panggilan Google |
| API5 Fungsi admin | port terpisah (8081) yang tidak dipasang di nginx; dari luar 404, dari container lain 403 |
| API6 Alur bisnis | ledger idempoten, saldo tidak bisa minus (dikunci per user, diuji paralel), batas akun baru per IP, pengaman etis Aplikasi Beku, tiket Fokus tidak tumpang tindih |
| API7 SSRF | server tidak pernah mengambil URL dari client |
| API8 Konfigurasi | TLS 1.2/1.3 saja, HSTS, `nosniff`, `no-store`, CSP, tanpa CORS kecuali waitlist, container read-only/nonroot/`cap_drop: ALL`, `riung_app` tanpa DDL & tanpa update ledger |
| API9 Inventaris | hanya `/v1`; `/readyz` & `/admin` 404 dari luar; semua endpoint di spec §3 |
| API10 API pihak ketiga | respons Google Play dicek ulang (akun, produk, status); token Pub/Sub dicek audience/issuer/service account |

Juga dicek: 948 baris log produksi tanpa token, email, atau private key; `govulncheck` 0; `golangci-lint`
(gosec) 0; Trivy di CI; secret prod `chmod 600`/`400`.

### 2.3 Masih terbuka (bukan kode backend — di `docs/todo-luar-backend.md` §A)

| Risiko | Tingkat | Langkah |
|---|---|---|
| API memakai key `firebase-adminsdk` (admin penuh project) | **P0** | service account khusus *Firebase Authentication Admin*, cabut key lama |
| Login SSH root dengan password masih aktif; password root pernah dibagikan di chat | **P0** | user `deploy` key-only, `PasswordAuthentication no`, ganti password root |
| Secret prod hanya ada di VPS; backup DB hanya di VPS yang sama, tidak terenkripsi | **P0** | password manager; salinan backup off-site terenkripsi |
| Versi nginx terlihat (`Server: nginx/1.30.0`) | rendah | `server_tokens off;` global di `shared-nginx` (berlaku semua situs) |
| `shared-postgres` tanpa TLS | diterima | trafik hanya di bridge Docker satu host |
| App Check masih `monitor` | sesuai rencana | §4 |

## 3. Alert

Aturan siap pakai: `backend/deploy/monitoring/grafana-alerting-riung.yml` — 12 aturan dari spec §6.6
(error server, 5xx > 1%, p95 > 500 ms, API tidak menjawab healthcheck, ledger mismatch, job gagal, cron
tidak jalan > 26 jam, pembelian ditolak/refund, lonjakan auth/App Check gagal, rate limit, batas akun baru,
Admin API) dengan contact point Telegram sendiri (`riung-telegram`) dan `notification_settings` per aturan,
jadi notification policy bersama tidak diubah.

Divalidasi di Grafana 11.6.1 + Loki 3.4 lokal: semua aturan ter-provision dan query-nya valid; dengan log
contoh berformat riung, aturan error/ledger/job/refund menyala, 5xx & p95 masuk *pending*, healthcheck
kembali normal, dan "cron tidak jalan" menyala bila `job_run` tidak ada. Temuan saat validasi: chat id
Telegram lewat `$__env{}` berubah jadi angka dan **seluruh provisioning Grafana berhenti** — karena itu
chat id ditulis langsung di file, dan file wajib diuji lokal dulu sebelum dipasang ke Grafana bersama.

Belum dipasang di VPS: konvensi `core-shared` (`provisioning/alerting/README.md`) — alarm dikirim aplikasi
ke Telegram, Grafana alerting sengaja kosong; riung butuh bot + chat Telegram. Langkah pasang di
runbook langkah 8b.

Query bantu (Grafana → Explore → Loki):

```logql
# p95 durasi (ms) per 5 menit, tanpa healthcheck
quantile_over_time(0.95, {container="riung-api"} | json | event="http_request" | route!="/healthz" | unwrap durationMs [5m]) by (container)
# porsi request app yang membawa App Check valid (24 jam)
sum(count_over_time({container="riung-api"} | json | event="http_request" | appCheck="valid" [24h]))
  / sum(count_over_time({container="riung-api"} | json | event="http_request" | appCheck!="" [24h]))
```

## 4. App Check: kapan pindah ke `enforce`

Saat ini **tetap `monitor`**: belum ada app yang memakai backend Go, dan app belum mengirim token App Check
(TODO §A–B). `enforce` sekarang tidak melindungi apa pun tapi akan memblokir build app pertama yang
belum siap.

Pindah ke `enforce` bila **semua** terpenuhi:
1. Build app dengan App Check (Play Integrity) + `getLimitedUseToken` untuk `billing/verify`, `DELETE /me`,
   verifikasi PIN sudah rilis, dan `MIN_APP_VERSION` dinaikkan ke versi itu.
2. Selama 7 hari: porsi `appCheck="valid"` ≥ 99% (query §3), `appCheck="replayed"` hampir nol, tidak ada
   lonjakan `appCheck="unavailable"`.
3. Ubah `APP_CHECK_MODE=enforce` di `/var/www/riung/.env`, jalankan `./deploy.sh <image yang sama>`, pantau
   `appcheck_failed` & 401 selama 1 jam. Kembali ke `monitor` = langkah yang sama.

## 5. Audit ulang pasca-deploy (2026-10-13)

| Area | Hasil |
|---|---|
| Produksi | `riung-api` `e5f0110` sehat, 0 restart, 0 log ERROR; job malam pertama (`cleanup`, `cleanup_anon`, `reconcile`) sukses dan tercatat di Loki; `billing-sync` tiap jam; backup 02:30 ada |
| Uji negatif produksi | token dev → 401; bearer `dev-pubsub` → 503 (billing mati, tidak diproses — menghasilkan log ERROR, lihat audit 2); CORS dari origin asing tanpa `Access-Control-Allow-Origin`; body > 2 KB waitlist → 413; metode salah → 405; `/admin`, `/readyz` dari luar → 404 |
| Analisis statis tambahan | 27 linter (contextcheck, nilerr, gocritic, unparam, forcetypeassert, …): tidak ada bug; sisa temuan disengaja (`context.WithoutCancel` untuk cleanup setelah request, `nil, nil` = "tidak ada") |
| Diperbaiki | `GET /admin/v1/audit` tidak lagi meng-*encode* dua kali dengan error diabaikan; panduan app: pengecualian header untuk `/v1/waitlist`, beda `idempotency_key_reuse` vs `request_in_progress`, `DELETE /v1/me` yang diulang setelah sukses dijawab 401 |
| Tetap terbuka | risiko P0 di §2.3 (key Firebase, SSH root, secret & backup off-site) |

### Audit 2 (2026-10-13)

| Area | Hasil |
|---|---|
| Panduan app | 6 rujukan § salah sejak penomoran berubah — diperbaiki; tiga contoh Dart dikompilasi dengan Flutter 3.44.0 + versi paket app (`flutter analyze`: bersih) |
| Klaim panduan dibuktikan tes | `Idempotency-Key` sama tetap bisa dipakai setelah `429`; batch dikirim ulang dengan key baru → `replayed`, hanya event baru yang memberi koin |
| Webhook saat billing mati | dulu `503` → setiap orang bisa membuat log ERROR (dan memicu alert error server) tanpa login. Sekarang `404` selama tidak ada publisher Play |

### Audit 3 (2026-10-19 – 2026-10-20)

| Area | Hasil |
|---|---|
| Deploy | User `deploy` tanpa password; kunci CI hanya `check` / `deploy <sha>` lewat forced command (shell, injeksi argumen, port forwarding diuji ditolak); token GHCR = `GITHUB_TOKEN` job, tidak tersimpan di VPS. Grup `docker` tetap setara root — batasnya ada di kunci, bukan di user |
| Diperbaiki | Kunci PIN jurnal dulu dicari per hari UTC: user terkunci pukul 23:50 mendapat 10 percobaan baru pukul 00:00 (rate limit 5/15 menit tetap berlaku) — kini kunci berlaku melewati tengah malam. API tidak lagi keluar dengan ERROR bila Postgres belum siap saat reboot |
| App Store | Semua JWS Apple diverifikasi: rantai x5c ke Apple Root CA - G3 tertanam (SHA-256 dicek tes), penanda sertifikat Apple, valid pada `signedDate`, ES256 dari sertifikat daun; data transaksi dari HP tidak dipakai (server bertanya ke Apple); pembeli terikat `appAccountToken` HMAC; webhook idempoten per `notificationUUID`, `bundleId`/`appAppleId` dicek; tidak ada token/`.p8` di log. Diuji dengan notifikasi TEST asli Apple (200) dan JWS palsu (400) |
| Ditemukan saat uji key asli | Production App Store Server API menjawab `401` sebelum rilis pertama (sandbox menerima key yang sama). Tanpa fallback, semua pembelian TestFlight/App Review akan `500` — kini diteruskan ke sandbox |
| Risiko diterima | Pembelian sandbox App Store dikreditkan di produksi (dibutuhkan App Review) — TestFlight eksternal bisa mendapat koin/Premium gratis (keputusan di TODO §D). `REFUND_REVERSED` belum mengembalikan koin (TODO §C) |
| Rahasia baru | `secrets/appstore-iap-key.p8` (uid 65532, `chmod 400`); salinan perlu di password manager, file di `~/Downloads` dihapus setelahnya |
| Tetap terbuka | §2.3: key `firebase-adminsdk`, login SSH root dengan password (`PasswordAuthentication yes`), secret & backup off-site |
