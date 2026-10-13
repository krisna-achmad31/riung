# Panduan integrasi app ↔ backend Riung
*Untuk tim Flutter (`riung/`) · backend Go di `backend/` · berlaku untuk API `/v1` · 2026-10-13*

Backend Go menggantikan peran "Cloud Functions" di `CLAUDE.md`: semua koin, progres monster, pembelian,
tiket Fokus, dan buka-waktu Aplikasi Beku sekarang diputuskan server. App mengirim **apa yang terjadi**,
server yang menentukan **berapa nilainya**. Firebase tetap dipakai untuk login (Auth), App Check,
Analytics, Crashlytics, dan Remote Config (hanya saklar fitur/A-B, bukan harga).

Dokumen ini panduan praktis. Kontrak lengkap (semua field, batas, keamanan): `docs/backend-api-spec.md`.
Daftar pekerjaan app yang sudah dipetakan: `docs/todo-luar-backend.md` §B–C.

---

## 1. Lingkungan

| | URL | Login | App Check |
|---|---|---|---|
| Produksi | `https://riung.e55techlab.com/v1` | ID token Firebase (`riung-5e979`) | `monitor` (belum menolak) |
| Lokal | `http://localhost:8080/v1` (`cd backend && make dev-up`) | token dev `dev:<uid>:<provider>` | mati |

Lokal memakai `DEV_AUTH`: token `Bearer dev:rani:anonymous` (atau `:password`, `:google.com`) menggantikan ID
token Firebase, App Check cukup `dev`, dan Google Play dipalsukan (§9.4). Di Android emulator, host laptop =
`http://10.0.2.2:8080`.

Status produksi: API live, database kosong, **billing Google Play belum aktif** (`/v1/billing/*` → 503)
sampai Play Console & Pub/Sub disiapkan.

## 2. Setiap request

| Header | Isi | Kapan |
|---|---|---|
| `Authorization` | `Bearer <Firebase ID token>` (`getIdToken()`; perbarui saat 401) | semua kecuali `/v1/config`, `/v1/content/*` |
| `X-Firebase-AppCheck` | token App Check (`FirebaseAppCheck.getToken()`) | semua `/v1/*`; **limited-use** (`getLimitedUseToken()`) untuk `POST /v1/billing/verify`, `DELETE /v1/me`, `POST /v1/me/journal-pin-backup/verify` |
| `Idempotency-Key` | UUID v4 | semua `POST/PUT/PATCH/DELETE` yang mengubah data (kecuali `DELETE /v1/me` dan verifikasi PIN) |
| `X-App-Version` | versi app, mis. `1.4.0+27` | semua — app di bawah `minAppVersion` dijawab `426` |
| `X-Platform` | `android` | semua |
| `Content-Type` | `application/json` | request ber-body |

**Idempotency-Key**: satu UUID baru per **aksi pengguna**. Pakai ulang key yang sama **hanya** saat
mengulang request yang gagal di jaringan atau dijawab 5xx — server mengembalikan respons yang sama persis
dan tidak memotong/menambah koin dua kali. Setelah jawaban 4xx (mis. koin kurang), aksi berikutnya memakai
key baru. Body berbeda dengan key yang sama → `409 idempotency_key_reuse`.

Format waktu RFC 3339 UTC (`2026-10-13T03:04:05Z`); tanggal kalender `YYYY-MM-DD` menurut zona waktu user
(`users.tz`, default `Asia/Jakarta`; kirim zona waktu HP lewat `PATCH /v1/me/profile`).

## 3. Error

```json
{ "error": { "code": "insufficient_coins", "message": "not enough coins",
             "requestId": "01M4R9F7Q3EBQ8B8YW7MZ5HG8Q",
             "details": { "balance": 12, "required": 25, "shortfall": 13, "earnedOnly": false } } }
```

`message` hanya untuk debugging. Teks di layar selalu dari file strings app, dipetakan dari `code`
(CLAUDE.md aturan #2). Tampilkan `requestId` di pesan error ("Kode: …") dan kirim ke Crashlytics sebagai
custom key — dengan itu satu kejadian bisa dilacak sampai log server.

| HTTP | `code` | Yang dilakukan app |
|---|---|---|
| 400 | `invalid_request` | bug di app (`details.fields`); jangan diulang |
| 401 | `unauthenticated` | perbarui ID token sekali, ulangi; masih 401 → login ulang |
| 401 | `app_check_failed` | ambil token App Check baru, ulangi sekali |
| 401 | `recent_login_required` | minta login ulang (hapus akun permanen butuh login ≤ 5 menit) |
| 403 | `permanent_account_required` | ajak tautkan akun (email/Google) dulu |
| 403 | `premium_required` | tampilkan paywall Premium |
| 404 | `not_found` | item/konten tidak ada (katalog app tertinggal → muat ulang `/v1/config`) |
| 409 | `insufficient_coins` | **tawarkan latihan dulu**, baru tombol beli koin (aturan #4); `details.earnedOnly` = hanya koin latihan yang dihitung |
| 409 | `price_changed` | harga berubah: muat ulang `/v1/config`, tampilkan harga baru (`details.price`) |
| 409 | `already_owned` / `not_owned` | sinkronkan inventori dari `GET /v1/me` |
| 409 | `limit_reached` | batas harian/etis (`details.reason`, `details.resetsAt`) |
| 409 | `cooldown` | tunggu `details.retryAfterSeconds` |
| 409 | `ticket_invalid` | tiket Fokus tidak bisa dipakai (`details.reason`) |
| 409 | `purchase_invalid` | Google tidak mengonfirmasi pembelian untuk akun ini |
| 409 | `pin_locked` | verifikasi PIN dikunci (`details.retryAfterSeconds`) |
| 409 | `idempotency_key_reuse` / `request_in_progress` | bug key / request sama masih jalan — tunggu lalu ulangi dengan key yang sama |
| 413 / 415 | `payload_too_large` / `unsupported_media_type` | bug di app |
| 426 | `upgrade_required` | layar wajib update (`details.minAppVersion`) |
| 429 | `rate_limited` | tunggu header `Retry-After` |
| 429 | `signup_limited` | terlalu banyak akun baru dari jaringan ini hari ini; coba lagi besok |
| 500 | `internal` | ulangi nanti dengan key yang sama |
| 503 | `unavailable` | server/Google sedang gangguan; ulangi dengan backoff, key yang sama |

## 4. Alur buka app

```
Firebase sign-in (anonim kalau belum login)
  → GET /v1/config         harga, katalog, batas, kunci tiket Fokus (cache + If-None-Match → 304)
  → GET /v1/me             akun dibuat otomatis di panggilan pertama (termasuk anonim)
  → kirim outbox           POST /v1/activities/batch (event yang tertunda saat offline)
  → GET /v1/focus/tickets  + ambil tiket free_daily bila online (§7)
```

`GET /v1/me` adalah sumber tunggal state user: profil, `billingAccountId`, Premium, streak + jumlah
pelindung, wallet, asesmen, progres monster, inventori + sesi Fokus prabayar, loadout, dan `today`
(`missionsDone`, `freeFocusLeft`, `paidUnlocksUsed`, `fightsToday`, `premiumDailyClaimed`). Semua yang
sekarang disimpan di `LocalPrefsStore` dan bernilai uang pindah ke sini.

Saldo yang ditampilkan = `wallet.coins` (= `earnedCoins` + `purchasedCoins`). Setiap respons yang mengubah
koin membawa `wallet` terbaru — perbarui `WalletNotifier` dari situ, jangan menghitung sendiri.

## 5. Akun

| Aksi | Endpoint | Catatan |
|---|---|---|
| Profil | `PATCH /v1/me/profile` | `displayName` (≤ 40), `avatarId` (`av1`–`av6`), `locale` (`id`/`en`), `persona` (`pelajar`/`mahasiswa`/`pekerja`/`lainnya`), `onboardingDone`, `tz` (IANA, mis. `Asia/Makassar`); kirim hanya field yang berubah |
| Hasil asesmen ringkas | `PUT /v1/me/assessment` | `dominantSaboteurs`, `scores` (0–100 per saboteur), `completedAt`. Jawaban & hasil detail **tetap di HP** |
| Anonim → email/Google | `POST /v1/me/link` | setelah `linkWithCredential` di Firebase (uid sama, tanpa body); semua data anonim ikut |
| Hapus akun | `DELETE /v1/me` | `204`; akun permanen harus login ≤ 5 menit (`recent_login_required`); server ikut menghapus user Firebase. Peringatkan bila langganan masih aktif — batalkan di Play Store dulu |
| Unduh data server | `GET /v1/me/export` | melengkapi `DataExportBuilder` lokal |
| Backup PIN jurnal | `PUT/GET/DELETE /v1/me/journal-pin-backup`, `POST …/verify` | akun permanen; hash PIN dihitung di HP. `GET` hanya mengembalikan `salt`; verifikasi → `{match, attemptsLeft}`, terkunci 1 jam setelah 10 gagal/hari |

Pembelian dengan uang hanya untuk akun permanen (supaya tidak hilang kalau app dihapus). Akun anonim yang
tidak dibuka 90 hari dihapus otomatis.

## 6. Latihan, koin & outbox

Satu endpoint untuk semua kejadian: `POST /v1/activities` (satu) atau `POST /v1/activities/batch`
(`{"events": [...]}`, ≤ 50, hasil per event). App **tidak pernah mengirim nominal koin**.

| `type` | Field | Server memberi |
|---|---|---|
| `checkin` | `date` | +5; streak; bonus 7 hari +20 / 30 hari +100; pelindung streak dipakai otomatis bila tepat 1 hari bolong |
| `journal_saved` | `entryId` (UUID entri), `promptId?` | +4, +2 progres ke monster prompt; gratis 1 entri/hari |
| `meditation_completed` | `sessionId` | +3, +3 progres ke monster target (dari katalog); sesi Premium perlu Premium |
| `betterme_lesson_completed` | `lessonId` | +10 sekali per lesson; level ≥ 2 perlu Premium, berurutan |
| `mission_completed` | `date`, `index` (0–2) | +3, maks 3 misi/hari |
| `minigame_finished` | `ref` (UUID pertarungan), `saboteurId`, `won` | +8 bila menang; +5/+2 progres; maks 4 pertarungan/hari |
| `focus_completed` | `ticketId`, `saboteurId` | +4 progres; tiket dipakai sekali (§7) |

Semua event wajib `occurredAt` (kapan terjadi di HP, maks 7 hari ke belakang, maks 5 menit ke depan).
`date` = tanggal lokal `occurredAt`. Monster yang mencapai 100 jinak dan memberi +50 sekali.

**Isi tidak pernah dikirim**: teks jurnal, mood/faktor/catatan check-in, refleksi Better Me, hasil Kenali
Dirimu, data tidur, daftar & pemakaian aplikasi yang dibekukan, afirmasi buatan, apa pun dari layar krisis.

**Batas harian bukan error.** Event di atas batas dijawab `200` dengan `coinsGranted: 0`, `capped: true`,
`capReason` (`daily_cap`, `free_daily_limit`, `premium_required`, `locked`). Tetap rayakan latihannya; beri
keterangan ramah, bukan pesan gagal.

**Outbox offline** — wajib karena latihan sering dilakukan tanpa internet:
- Simpan event di DB lokal saat terjadi, dengan `occurredAt` dan `Idempotency-Key` sendiri yang **tetap**
  sampai terkirim.
- Kirim lewat `/batch` saat online (urut sesuai waktu). Per hasil: `ok` → hapus dari outbox; error 4xx
  (`invalid_request`, `ticket_invalid`) → hapus dan catat (mengulang tidak akan berhasil); 5xx/jaringan →
  simpan dan coba lagi nanti dengan key yang sama.
- Mengirim event yang sama dua kali aman: server mengembalikan hasil lama dengan `replayed: true`.
- Saldo di layar = angka terakhir dari server + penanda "menunggu sinkron" bila outbox belum kosong.

## 7. Mode Fokus — tiket offline

Sesi Fokus boleh dimulai tanpa internet memakai **tiket** yang diambil saat online.

| `source` | Dari | Berlaku | Habis |
|---|---|---|---|
| `free_daily` | jatah harian (1, Premium 3) | sampai tengah malam lokal | `409 limit_reached` `reason=free_daily` |
| `prepaid` | sesi yang dibeli di Toko (`focus_1`, `focus_5`) | 30 hari | `409 limit_reached` `reason=no_prepaid_sessions` |
| `coins` | koin: 25 / 40 / 50 untuk 25 / 45 / 60 menit, wajib `expectedPrice` | 30 hari | `409 insufficient_coins` / `price_changed` |

```
POST /v1/focus/tickets  {"source":"free_daily","durationMin":25}
→ { "ticket": { "id", "userId", "source", "durationMin", "issuedAt", "expiresAt", "kid", "sig" },
    "price": 0, "freeFocusLeft": 0, "prepaidFocus": 4, "wallet": {…} }
```

1. Saat layar Fokus dibuka dan online: ambil tiket `free_daily` di muka. Tiket `prepaid`/`coins` diminta
   **saat user benar-benar memulai sesi** — sesinya langsung terpakai dan tidak dikembalikan bila kedaluwarsa.
2. Simpan tiket terenkripsi di HP. Boleh dicek keasliannya: `sig` = Ed25519 (base64url) atas
   `riung-focus-ticket.v1|<kid>|<id>|<userId>|<source>|<durationMin>|<issuedAt>|<expiresAt>` dengan kunci
   publik `focusTicketKeys` dari `/v1/config` (cocokkan `kid`).
3. Sesi selesai → event `focus_completed` `{ticketId, saboteurId}` lewat outbox. Server menolak
   (`ticket_invalid`) bila: tiket bukan milik user (`not_found`), sudah dipakai (`used`), "selesai" sebelum
   durasinya lewat (`too_early`), dimulai setelah tiket kedaluwarsa (`expired`), atau waktunya bertumpuk
   dengan sesi lain yang sudah dilaporkan (`overlap`).
4. `GET /v1/focus/tickets` → tiket yang belum dipakai (untuk HP baru / setelah reinstall).

Kirim `saboteurId` monster yang sedang dijinakkan (sekarang `sesi_selesai_screen.dart` selalu `waswas`).

## 8. Toko, loadout, Aplikasi Beku

**Belanja koin** — `POST /v1/shop/purchase` `{itemType, itemId, expectedPrice}`:

| `itemType` | `itemId` |
|---|---|
| `cosmetic` | id inventori: kosmetik monster (`topi_rajut`), aksesori `acc_<id>`, gaya kartu `cardstyle_<id>` |
| `cosmetic_bundle` | id bundel aksesori (harga = 80% item yang belum dimiliki, dibulatkan ke 5) |
| `streak_shield` | `streak_shield` |
| `focus_pack` | `focus_1`, `focus_5` |

Harga **selalu** dari `/v1/config` → `catalog` (sudah dihitung server); `expectedPrice` hanya deteksi
perubahan. Koin beli dipakai lebih dulu, lalu koin latihan. Kepemilikan kosmetik global.

**Loadout** — `PUT /v1/loadouts/monsters/{saboteurId}` `{items: [...]}`, `PUT /v1/loadouts/characters/{testId}`
`{accessories: [...], cardStyle}`. Item harus dimiliki, satu per slot, item eksklusif hanya untuk karakternya.
Gaya kartu berbayar boleh dipakai tanpa dibeli selama Premium aktif.

**Aplikasi Beku** — `POST /v1/appbeku/unlocks`:

```
satuan : {"appId":"com.instagram.android","minutes":10,"expectedPrice":15}
bundel : {"bundleId":"santai","expectedPrice":35}
         {"bundleId":"sosmed","appIds":["com.instagram.android","com.google.android.youtube"],"expectedPrice":75}
→ {"result":{"target":"unit","grants":[{"appId":"com.instagram.android","minutes":10}],"price":15,
             "paidUnlocksUsed":1,"paidUnlocksLeft":2,"cooldownUntil":"…"},"wallet":{…}}
```

- `appId` = package name dari `core/config/appbeku_catalog.dart` (WhatsApp tidak bisa). Menit dan bundel
  dari `/v1/config` → `catalog.appbeku`.
- `expectedPrice` = harga dasar + 10 × `today.paidUnlocksUsed` (ke-1: dasar, ke-2: +10, ke-3: +20).
- Pengaman etis ditegakkan server: maks 3 buka-berbayar/hari (`limit_reached`), jeda 60 detik antar buka
  berbayar — juga dari Toko, bukan hanya interstisial (`cooldown`), **hanya koin latihan**
  (`insufficient_coins` dengan `earnedOnly: true`). Bundel dipotong sekali dan dihitung satu buka.
- Buka menit secara lokal sesuai `grants`. Jalur napas gratis tetap lokal dan tidak pernah dibatasi.

**Koin harian Premium tahunan** — `POST /v1/premium/daily-coins` (akun permanen, 1×/hari, +2 ke koin beli).

**Akses jurnal** — `GET /v1/journal/access?promptId=` → `canWrite`, `reason` (`daily_limit`,
`premium_required`), status tiap prompt. Saat offline pakai hitungan lokal sebagai cadangan.

## 9. Pembelian Google Play

### 9.1 Membeli
1. Hanya akun permanen. Ambil `billingAccountId` dari `GET /v1/me`.
2. `BillingClient`: isi `obfuscatedAccountId` (`applicationUserName` di `in_app_purchase`) =
   `billingAccountId`. Tanpa ini server menolak pembelian (`purchase_invalid`).
3. Produk: koin `coin_pack_small|medium|large` (80 / 330 / 820 koin), langganan `premium_monthly|premium_yearly`.
4. Setiap update pembelian → `POST /v1/billing/verify` `{productId, purchaseToken}` (Idempotency-Key +
   App Check limited-use).
5. `completePurchase` **hanya** bila `result.status` ∈ `credited`, `already_credited`, `active`, `inactive`.
   Bukan untuk `pending` (pembayaran tertunda — tunggu update berikutnya) dan bukan untuk error.
   `503` → coba lagi nanti; pembelian tetap tersimpan di Play.
6. App **berhenti** mengkredit koin/Premium sendiri. Koin & status Premium dari respons (`wallet`, `premium`).

### 9.2 Restore & status
- `POST /v1/billing/restore` `{purchases: [{productId, purchaseToken}]}` (≤ 20) dari `queryPastPurchases`
  saat app dibuka/login. Hasil per item; token yang sudah dikreditkan tidak dikreditkan ulang.
- `GET /v1/billing/subscription` / `GET /v1/me` → `premium.status`: aktif bila `active` atau `in_grace`.
  Membatalkan perpanjangan (auto-renew mati) tetap Premium sampai `expiresAt`.

### 9.3 Refund
Refund dari Google menarik kembali koinnya. Kalau koinnya sudah terpakai, sisanya jadi `debtCoins`
(`GET /v1/wallet`) yang dilunasi dari koin berikutnya — saldo tidak pernah minus.

### 9.4 Uji lokal tanpa Play
Stack dev memakai Google Play palsu: token `dev-coin:<billingAccountId>:<productId>:<n>` dan
`dev-sub:<billingAccountId>:<productId>:<hari>:<n>`.

## 10. Rate limit yang perlu diperhatikan

Batas per user (sisanya di spec §5): `GET /v1/me` & `/v1/wallet` 60/menit, `POST /v1/activities` 60/menit,
`/batch` 10/menit, belanja & Aplikasi Beku 10/menit, tiket Fokus 20/menit, `billing/verify` 10/menit & 30/jam,
`billing/restore` 5/jam, `/me/link` 5/jam, hapus/ekspor akun 3/jam. Jangan polling — `/v1/me` saat app dibuka
dan setelah aksi penting sudah cukup.

## 11. Mencoba lokal

```sh
cd backend && make dev-up
docker compose -f deploy/docker-compose.yml exec -T api /riung seed-content - < ../docs/dummy-data-seed.json
curl localhost:8080/v1/me -H 'Authorization: Bearer dev:rani:anonymous' -H 'X-Firebase-AppCheck: dev'
curl -X POST localhost:8080/v1/activities -H 'Authorization: Bearer dev:rani:anonymous' \
  -H 'X-Firebase-AppCheck: dev' -H 'Content-Type: application/json' -H "Idempotency-Key: $(uuidgen)" \
  -d "{\"type\":\"checkin\",\"occurredAt\":\"$(date -u +%FT%TZ)\",\"date\":\"$(TZ=Asia/Jakarta date +%F)\"}"
```

## 12. Daftar kerja app (ringkas)

Detail & prioritas: `docs/todo-luar-backend.md` §B–C.

- [ ] `ApiClient` (header §2, refresh token, retry dengan key yang sama, pemetaan `code` → strings, `requestId`)
- [ ] Model Dart typed untuk request/response (aturan model di `CLAUDE.md`), tanpa `Map` mentah di UI
- [ ] Bootstrap dari `GET /v1/me`; harga & katalog dari `/v1/config` (cache + fallback `economy.dart`)
- [ ] Outbox offline + `/v1/activities/batch`; hapus mutasi koin di HP (`HybridWalletFunctionsService`, `firestore.rules`)
- [ ] Toko, loadout, Aplikasi Beku, tiket Fokus lewat server (§7–8)
- [ ] `BillingService` lewat `/v1/billing/*` (§9)
- [ ] App Check (Play Integrity) + `getLimitedUseToken` untuk 3 endpoint sensitif
- [ ] Teks untuk semua `code` di §3 (Bahasa Indonesia & Inggris)
- [ ] Tes parity: `economy.dart` == `docs/economy-props.json`, katalog app == `docs/catalog.json`
