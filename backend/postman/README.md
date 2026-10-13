# Postman — Riung API v1

| File | Isi |
|---|---|
| `riung-api.postman_collection.json` | 52 request dalam 12 folder, urut seperti alur app (akun → latihan → billing → toko → Fokus → Aplikasi Beku → admin → hapus akun) |
| `riung-local.postman_environment.json` | stack dev (`make dev-up`): token dev siap pakai |
| `riung-prod.postman_environment.json` | `https://riung.e55techlab.com`: isi `idToken` (ID token Firebase, berlaku 1 jam) dan `appCheckToken` bila ada |
| `generate.py` | sumber koleksi — ubah di sini lalu `python3 postman/generate.py postman` (jangan edit JSON manual) |

**Import**: Postman → Import → pilih ketiga file JSON → pilih environment di pojok kanan atas.

Script koleksi otomatis menambah `X-App-Version`, `X-Platform`, `X-Firebase-AppCheck`, `Idempotency-Key`
(baru setiap kirim), dan mengisi `{{now}}` / `{{today}}`. **2. Akun → Me** menyimpan `userId` dan
`billingAccountId`; request tiket Fokus menyimpan `ticketId`. Error tampil di Postman Console beserta
`requestId`.

## Lokal

```sh
cd backend && make dev-up
docker compose -f deploy/docker-compose.yml exec -T api /riung seed-content - < ../docs/dummy-data-seed.json
# Admin API (folder 10): buat user admin dev sekali
curl -s localhost:8080/v1/me -H 'Authorization: Bearer dev:postman-admin:google.com' -H 'X-Firebase-AppCheck: dev' >/dev/null
docker compose -f deploy/docker-compose.yml exec api /riung admin grant dev:postman-admin "postman lokal"
```

Seluruh koleksi bisa dijalankan sekaligus (Collection Runner atau Newman):

```sh
docker run --rm -v "$PWD/postman:/etc/newman" postman/newman:6-alpine run riung-api.postman_collection.json \
  -e riung-local.postman_environment.json \
  --env-var baseUrl=http://host.docker.internal:8080 --env-var adminBaseUrl=http://host.docker.internal:8081
```

Hasil yang benar (diuji 2026-10-13, database kosong): semua 2xx kecuali empat `409` yang disengaja —
bundel aksesori (`price_changed`, dikirim dengan harga 0), sesi Fokus (`ticket_invalid` `too_early`), dan dua
bundel Aplikasi Beku (`cooldown` 60 detik).

## Produksi

- Ambil ID token dari app debug (`FirebaseAuth.instance.currentUser!.getIdToken()`) dan tempel di `idToken`.
- Billing belum aktif (503) dan butuh `purchaseToken` asli dari Play; webhook RTDN hanya dari Pub/Sub.
- Admin API hanya lewat VPN (`http://172.19.0.16:8081`) dengan token akun admin (login ≤ 15 menit).
- Folder **11. Hapus akun** benar-benar menghapus akun yang dipakai — jangan jalankan dengan akun sungguhan.
