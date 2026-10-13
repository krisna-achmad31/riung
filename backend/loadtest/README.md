# Uji beban riung-api (B6)

Skrip: [`riung.js`](riung.js) (k6). Setiap virtual user (VU) = satu pengguna app yang memakai token dev
(`dev:lt-<n>:anonymous`), jadi **hanya** untuk server `DEV_AUTH` — tidak pernah ke produksi.

Pola per VU (jeda 1–3 detik antar aksi, seperti orang memakai app): `GET /v1/config` sekali di awal, lalu
acak — `GET /v1/me` 30%, `POST /v1/activities` 20% (check-in, misi, jurnal, minigame), `GET /v1/wallet` 15%,
`GET /v1/journal/access` 10%, `POST /v1/activities/batch` (5 event) 8%, `POST /v1/shop/purchase` 5%,
`POST /v1/focus/tickets` 5%, `GET /v1/wallet/transactions` 4%, `GET /v1/focus/tickets` 3%.
`409` (batas harian, koin kurang) dihitung sebagai jawaban normal.

## Menjalankan

```sh
make dev-up                                   # Postgres + migrate (+ api dev)
docker compose -f deploy/docker-compose.yml run --rm --no-deps api \
  settings set maxNewAccountsPerIpPerDay 1000 "uji beban lokal"   # semua VU dari satu IP
# API dengan batas sumber daya seperti produksi (1 CPU, 256 MB, read-only):
docker run -d --name riung-lt --network riungdev_default --cpus 1 --memory 256m --read-only --tmpfs /tmp \
  --cap-drop ALL --security-opt no-new-privileges -p 127.0.0.1:18080:8080 \
  -e RIUNG_ENV=dev -e DEV_AUTH=true -e APP_CHECK_MODE=off \
  -e DATABASE_URL='postgres://riung_app:riung_app_dev_pw_local@postgres:5432/riung?sslmode=disable' riungdev-api api
caffeinate -i k6 run -e BASE=http://127.0.0.1:18080 -e VUS=200 -e HOLD=3m loadtest/riung.js
```

Jangan menjalankan pekerjaan Docker lain selama tes (run pertama tercemar: laptop tidur di tengah tes, run
kedua: Grafana/Loki dinyalakan di menit yang sama → p99 1 detik dari satu menit itu saja).

## Hasil (2026-10-13, MacBook Apple Silicon, Docker Desktop, PostgreSQL 16 lokal)

Gate plan §10: **p95 < 200 ms di beban target**. Beban target = 200 pengguna aktif bersamaan
(±80 req/s — kira-kira 10–20 ribu pengguna harian).

| Skenario | Request | Laju | p50 | p95 | p99 | Maks | Error | Memori API |
|---|---|---|---|---|---|---|---|---|
| 200 VU, 3 menit | 22 728 | 84 req/s | 3,9 ms | **11,9 ms** | 20,7 ms | 117 ms | 0% | < 40 MB |
| 400 VU, 2 menit (2× target) | 33 549 | 158 req/s | 2,7 ms | **9,0 ms** | 20,5 ms | 113 ms | 0% | 39 MB |

Tidak ada `rate_limited` maupun log `ERROR`; `409` hanya dari tiket Fokus gratis yang sudah terpakai dan
pelindung streak tanpa koin.

Catatan: laptop lebih cepat daripada VPS (2 vCPU dipakai bersama n8n, kampmedia, dst.) dan jaringan
lokal tanpa TLS/nginx. Ruang sisanya besar (p95 ±12 ms vs batas 200 ms), tapi angka produksi perlu
dikonfirmasi dari Loki saat beta (query p95 di `docs/backend-b6-review.md` §3).
