# Postman — Riung API v1

| File | Isi |
|---|---|
| `riung-api.postman_collection.json` | 52 request dalam 12 folder, urut seperti alur app (akun → latihan → billing → toko → Fokus → Aplikasi Beku → admin → hapus akun) |
| `riung-local.postman_environment.json` | stack dev (`make dev-up`): token dev siap pakai, `devBilling=true` (token pembelian palsu dibuat otomatis) |
| `riung-prod.postman_environment.json` | `https://riung.e55techlab.com`: isi `idToken` (ID token Firebase, berlaku 1 jam) dan `appCheckToken` bila ada; `coinToken`/`subToken` diisi `purchaseToken` asli dari app |
| `generate.py` | sumber koleksi — ubah di sini lalu `python3 postman/generate.py postman` (jangan edit JSON manual) |

**Import**: Postman → Import → pilih ketiga file JSON → pilih environment di pojok kanan atas.

Script koleksi otomatis menambah `X-App-Version`, `X-Platform`, `X-Firebase-AppCheck`, `Idempotency-Key`
(baru setiap kirim), dan mengisi `{{now}}` / `{{today}}`. **2. Akun → Me** menyimpan `userId` dan
`billingAccountId`; request tiket Fokus menyimpan `ticketId`; dua request *Verifikasi* menyimpan `coinToken` dan
`subToken`, yang lalu dikirim ulang oleh **Restore** (seperti `restorePurchases()` di HP). Error tampil di
Postman Console beserta `requestId`.

Tes kontrak di folder **6. Google Play billing**: paket koin `credited`/`already_credited`, langganan `active`
dengan plan `premium_yearly`, dan **Restore** — satu baris per pembelian dengan urutan yang sama, setiap baris
membawa `productId` + `purchaseToken` (app mencocokkan lewat token), token yang sudah diverifikasi tidak
dikreditkan dua kali, token akun lain `purchase_invalid`.

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

Hasil yang benar (diuji 2026-10-19, database kosong): 52 request, 64 assertion, 0 gagal; semua 2xx (satu
`304` dari *Config If-None-Match*) kecuali empat `409` yang disengaja —
bundel aksesori (`price_changed`, dikirim dengan harga 0), sesi Fokus (`ticket_invalid` `too_early`), dan dua
bundel Aplikasi Beku (`cooldown` 60 detik).

## Produksi

- Ambil ID token dari app debug (`FirebaseAuth.instance.currentUser!.getIdToken()`) dan tempel di `idToken`.
- Billing belum aktif: `verify`/`restore` → `503`, webhook → `404`. Setelah aktif, isi `coinToken`/`subToken`
  dengan `purchaseToken` asli dari Play (`devBilling` kosong, jadi token tidak ditimpa); webhook RTDN hanya dari
  Pub/Sub.
- Admin API hanya lewat VPN (`http://172.19.0.16:8081`) dengan token akun admin (login ≤ 15 menit).
- Folder **11. Hapus akun** benar-benar menghapus akun yang dipakai — jangan jalankan dengan akun sungguhan.
