# Riung Backend — Spesifikasi API, Keamanan, Rate Limit & Logging
*Pendamping `docs/backend-go-plan.md` · branch `feat/go-backend` · diperbarui 2026-10-13 (B0–B4 selesai, B5 berjalan)*

Dokumen ini menjawab tiga hal: **endpoint apa saja yang dibutuhkan app**, **bagaimana setiap endpoint
diamankan (sampai rate limit)**, dan **bagaimana log disiapkan**. Semua angka ekonomi yang disebut di sini
dibaca server dari `docs/economy-props.json` — bukan hardcode.

---

## 1. Konvensi umum

| Hal | Aturan |
|---|---|
| Base URL | `https://riung.e55techlab.com/v1` |
| Format | JSON UTF-8, field `camelCase` (sama dengan model Dart), `Content-Type: application/json` wajib untuk body |
| Waktu | timestamp RFC 3339 UTC (`2026-10-11T03:04:05Z`); tanggal kalender `YYYY-MM-DD` menurut zona waktu user (`users.tz`) |
| ID | `[A-Za-z0-9_.:-]{1,64}` untuk id katalog (`topi_rajut`, `acc_jungCrown`, `napas_4_7_8`); UUID v4 untuk id buatan server |
| Auth | `Authorization: Bearer <Firebase ID token>` |
| App Check | `X-Firebase-AppCheck: <token>` |
| Idempotensi | `Idempotency-Key: <UUID v4>` **wajib** di semua `POST/PUT/PATCH/DELETE` yang memutasi (kolom **Idem**); pengecualian: `DELETE /v1/me` (aman diulang, selalu 204) dan `POST …/journal-pin-backup/verify` |
| Versi app | `X-App-Version: 1.4.0+27` dan `X-Platform: android` (dipakai untuk paksa update & log) |
| Request ID | server membuat/meneruskan `X-Request-Id`, selalu dikembalikan di header & body error |
| Paging | cursor: `?limit=20&cursor=<opaque>` → `{ "items": [...], "nextCursor": "..." }` |
| Versioning | `/v1` hanya boleh berubah aditif. Breaking change → `/v2`. `minAppVersion` di `/v1/config` untuk paksa update |

### 1.1 Format error

```json
{
  "error": {
    "code": "insufficient_coins",
    "message": "Saldo koin tidak cukup",
    "requestId": "01J9Z6Q4V7K3XG2M8N5R0T1W4Y",
    "details": { "balance": 12, "required": 25, "earnedOnly": false }
  }
}
```

`message` hanya untuk debugging — **teks UI tetap dari file strings app** (CLAUDE.md aturan #2), dipetakan
dari `code`.

| HTTP | `code` | Arti |
|---|---|---|
| 400 | `invalid_request` | body/param tidak valid (detail field di `details.fields`) |
| 401 | `unauthenticated` | token tidak ada/kedaluwarsa/dicabut |
| 401 | `app_check_failed` | token App Check tidak valid (mode enforce) |
| 401 | `recent_login_required` | aksi sensitif (hapus akun permanen) butuh login ulang ≤ 5 menit |
| 403 | `permanent_account_required` | endpoint butuh akun non-anonim |
| 403 | `premium_required` | konten/aksi khusus Premium |
| 403 | `forbidden` | bukan admin / sumber koneksi Admin API tidak diizinkan |
| 404 | `not_found` | item katalog / resource tidak ada |
| 409 | `insufficient_coins` | saldo kurang (`details.earnedOnly` = true untuk koin latihan) |
| 409 | `price_changed` | harga di katalog server ≠ `expectedPrice` dari client |
| 409 | `already_owned` | item sudah dimiliki |
| 409 | `not_owned` | memasang item yang belum dimiliki |
| 409 | `idempotency_key_reuse` | key sama dipakai untuk body berbeda |
| 409 | `request_in_progress` | request dengan key yang sama masih diproses |
| 409 | `limit_reached` | batas harian/etis tercapai (`details.reason`, `details.limit`, `details.resetsAt`) |
| 409 | `cooldown` | jeda belum lewat (`details.retryAfterSeconds`) |
| 409 | `ticket_invalid` | tiket Fokus tidak bisa dipakai (`details.reason`: `not_found`, `used`, `too_early`, `expired`, `overlap`) |
| 409 | `purchase_invalid` | token pembelian ditolak Google / milik akun lain |
| 409 | `pin_locked` | verifikasi PIN dikunci sementara (`details.retryAfterSeconds`) |
| 413 | `payload_too_large` | body melebihi batas |
| 415 | `unsupported_media_type` | bukan JSON |
| 426 | `upgrade_required` | versi app di bawah `minAppVersion` |
| 429 | `rate_limited` | terlalu banyak request (`Retry-After` di header) |
| 429 | `signup_limited` | batas akun baru per IP hari ini tercapai (§4.2) |
| 500 | `internal` | error server (detail hanya di log, dicari lewat `requestId`) |
| 503 | `unavailable` | DB/dependency mati, aman di-retry |

### 1.2 Idempotensi

- Setiap mutasi menyimpan `(user_id, idempotency_key, endpoint, request_hash, status, response)` di tabel
  `idempotency_keys` selama 7 hari. Request ulang dengan key + body sama → **respons lama dikembalikan
  persis** (aman untuk retry jaringan & outbox offline). Key sama + body beda → `409 idempotency_key_reuse`.
- Untuk koin ada lapis kedua: `coin_ledger UNIQUE (user_id, idempotency_key)` dengan key bisnis
  (`checkin:2026-10-11`, `journal:<entryId>`, …) — jadi walau client membuat `Idempotency-Key` baru,
  reward yang sama tidak bisa diklaim dua kali.
- Respons **4xx juga disimpan** (mis. `insufficient_coins`, `price_changed`): setelah memperbaiki keadaan,
  client mengirim ulang dengan `Idempotency-Key` **baru**. Respons 5xx tidak disimpan (aman di-retry dengan
  key yang sama).
- Klaim yang belum selesai (proses mati/crash di tengah request) dianggap terbengkalai setelah 60 detik dan
  boleh diambil alih oleh retry dengan key yang sama; sebelum itu dijawab `409 request_in_progress`.

### 1.3 Batas harian bukan error

Batas reward harian (misi 3/hari, pertarungan minigame 4/hari, jurnal/meditasi sesuai pengaturan admin) dan
aktivitas konten Premium oleh user non-Premium dijawab **200** dengan `coinsGranted: 0`, progres monster
tidak bertambah, `capped: true`, dan `capReason` (`daily_cap`, `free_daily_limit`, `premium_required`) — bukan 4xx — supaya outbox offline tidak me-retry selamanya dan UI tetap bisa merayakan
latihannya tanpa rasa bersalah. Hanya batas yang memblokir aksi (buka-waktu Aplikasi Beku, tiket fokus)
yang memakai `409 limit_reached`.

### 1.4 Perilaku app yang berbeda

Selisih antara app sekarang dan aturan ekonomi (bonus streak, pelindung streak, progres Fokus, bundel
Aplikasi Beku, tiket tambahan, durasi sesi Fokus) dicatat sebagai TODO di `docs/todo-luar-backend.md`
§C–D. Backend mengikuti aturan `CLAUDE.md` §3 dan default di §D dokumen itu.

---

## 2. Tingkat akses

| Level | Syarat |
|---|---|
| `public` | tanpa token (hanya `waitlist`, `healthz`, webhook dengan verifikasi sendiri) |
| `app` | App Check valid, tanpa login (konfigurasi & konten publik) |
| `user` | App Check + ID token Firebase valid (anonim **boleh**) |
| `permanent` | `user` + akun bukan anonim |
| `user+fresh` | `user` + token dicek pencabutan (`VerifyIDTokenAndCheckRevoked`); untuk akun **permanen** juga `auth_time` ≤ 5 menit (akun anonim tidak bisa login ulang, jadi cukup cek pencabutan) |
| `google` | JWT OIDC dari Google Pub/Sub (audience + service account dicek) |
| `admin` | port internal `8081` + sumber dari VPN + token Firebase dengan claim `riungAdmin` + terdaftar di `admins` (§3.11) |

User **selalu** diambil dari token — tidak ada `userId` di path/body, jadi tidak ada celah IDOR (akses data
user lain dengan mengganti id).

---

## 3. Daftar endpoint

Kolom **RL** = rate limit aplikasi per user (detail §5). Kolom **Idem** = wajib `Idempotency-Key`.

### 3.1 Sistem & publik

| # | Method & path | Akses | RL | Idem | Fungsi |
|---|---|---|---|---|---|
| 1 | `GET /healthz` | public | — | — | liveness (proses hidup) |
| 2 | `GET /readyz` | internal | — | — | DB siap; **diblokir nginx dari luar** |
| 3 | `GET /v1/config` | app | 600/mnt/IP | — | ekonomi + katalog + `minAppVersion` + `serverTime` + kunci tiket Fokus, ETag/304 |
| 4 | `GET /v1/content/{kind}?locale=id` | app | 600/mnt/IP | — | konten publik: `saboteurs`, `affirmations`, `research_facts`, `meditations`, `sleep_stories`, `betterme_lessons` (diisi `riung seed-content`); ETag/304. Opsional — app tetap membawa konten bawaan sebagai fallback |
| 5 | `POST /v1/waitlist` | public | 20/jam/IP | — | daftar email dari landing (CORS hanya origin landing); respons **selalu sama** (202) baik email baru maupun sudah terdaftar — tidak bisa dipakai menebak email; field honeypot tersembunyi untuk menahan bot |

`/v1/config` menggantikan harga dari Remote Config (keputusan plan §6). Isinya `economy` (seluruh
`economy-props.json` tanpa komentar, `caps` setelah override admin), `catalog` (`docs/catalog.json` dengan
harga sudah dihitung), dan `focusTicketKeys` (§3.7). Ringkas:

```json
{
  "version": "2026-10-11.1",
  "minAppVersion": "1.0.0",
  "serverTime": "2026-10-11T03:04:05Z",
  "economy": { "earn": { "checkin": 5, "journal": 4, "...": "..." }, "monsterProgress": {}, "spend": {},
               "appbeku": { "maxPaidUnlocksPerDay": 3, "escalationPerUnlock": 10, "unlockCooldownSeconds": 60, "...": "..." },
               "tickets": {}, "freeTier": {}, "premium": {}, "coinPacks": [],
               "caps": { "missionsPerDay": 3, "journalRewardsPerDay": 3, "meditationRewardsPerDay": 3 } },
  "catalog": { "version": "2026-10-12.2", "monsters": [], "monsterCosmetics": [ { "id": "topi_rajut", "monsterId": "…",
               "slot": "head", "exclusive": false, "price": 100 } ], "personalityTests": [], "accessories": [],
               "accessoryBundles": [], "cardStyles": [], "focusPacks": [], "appbeku": { "apps": [], "units": [], "bundles": [] },
               "streakShield": { "itemId": "streak_shield", "price": 20 }, "journalPrompts": [], "meditations": [],
               "betterme": {} },
  "focusTicketKeys": [ { "kid": "k1", "alg": "Ed25519", "publicKey": "…" } ]
}
```

### 3.2 Akun & profil

| # | Method & path | Akses | RL | Idem | Fungsi |
|---|---|---|---|---|---|
| 6 | `GET /v1/me` | user | 60/mnt | — | **bootstrap**: profil, premium, streak, asesmen, wallet, monster, inventori, loadout, consumables, jatah fokus & misi hari ini. Akun baru (termasuk anonim) otomatis dibuat di sini |
| 7 | `PATCH /v1/me/profile` | user | 20/mnt | ✓ | `displayName`, `avatarId`, `locale`, `persona`, `onboardingDone`, `tz` |
| 8 | `PUT /v1/me/assessment` | user | 10/mnt | ✓ | hasil asesmen onboarding: `dominantSaboteurs`, `scores` (0–100 per saboteur), `completedAt` |
| 9 | `POST /v1/me/link` | user (+ cek pencabutan) | 5/jam | ✓ | dipanggil setelah anonim → email/Google; token **harus** sudah ber-provider `password`/`google.com` (bukan `anonymous`), server set `isAnonymous=false`. Tidak memakai syarat `auth_time` karena link tidak memperbarui waktu login |
| 10 | `DELETE /v1/me` | user+fresh | 3/jam | — | hapus akun: semua data server + user Firebase Auth (§4.9) |
| 11 | `GET /v1/me/export` | user | 3/jam | — | salinan data yang disimpan **server** (melengkapi `DataExportBuilder` lokal) |
| 12 | `GET /v1/me/journal-pin-backup` | permanent | 10/mnt | — | hanya `salt` + `updatedAt` (hash **tidak** pernah dikirim balik) |
| 13 | `PUT /v1/me/journal-pin-backup` | permanent | 5/jam | ✓ | simpan `hash` + `salt` PIN (dihitung di HP) |
| 14 | `POST /v1/me/journal-pin-backup/verify` | permanent | 5/15 mnt | — | cocokkan PIN di perangkat baru; terkunci 1 jam setelah 10 gagal/hari |
| 15 | `DELETE /v1/me/journal-pin-backup` | permanent | 5/jam | ✓ | hapus backup PIN |

`GET /v1/me` (dipotong):

```json
{
  "user": { "id": "7b1e…", "billingAccountId": "ba_3f9c…", "isAnonymous": true, "displayName": "", "avatarId": "av1", "locale": "id",
            "tz": "Asia/Jakarta", "onboardingDone": false, "createdAt": "2026-10-11T03:00:00Z" },
  "premium": { "status": "none", "plan": null, "expiresAt": null, "autoRenewing": false },
  "streak": { "current": 0, "longest": 0, "lastCheckinDate": null, "shields": 0 },
  "assessment": null,
  "wallet": { "coins": 0, "earnedCoins": 0, "purchasedCoins": 0 },
  "monsters": [ { "saboteurId": "waswas", "state": "wild", "progress": 0, "tamedAt": null } ],
  "inventory": { "items": ["topi_rajut"], "prepaidFocus": 0 },
  "loadouts": { "monsters": { "waswas": ["topi_rajut"] }, "characters": { "jung": { "accessories": [], "cardStyle": null } } },
  "today": { "date": "2026-10-11", "missionsDone": [0], "freeFocusLeft": 1, "paidUnlocksUsed": 0,
             "fightsToday": 0, "premiumDailyClaimed": false }
}
```

`billingAccountId` = HMAC(server secret, `users.id`) — app memasukkannya ke `applicationUserName` saat membeli
(§3.9). App tidak bisa menghitungnya sendiri karena kuncinya hanya di server.

### 3.3 Aktivitas latihan (sumber koin & progres monster)

Satu endpoint untuk semua "hal yang terjadi". Server yang menentukan koin, progres monster, streak — client
**tidak pernah** mengirim nominal.

| # | Method & path | Akses | RL | Idem | Fungsi |
|---|---|---|---|---|---|
| 16 | `POST /v1/activities` | user | 60/mnt | ✓ | satu event |
| 17 | `POST /v1/activities/batch` | user | 10/mnt | ✓ | ≤ 50 event dari outbox offline, diproses berurutan, hasil per event |

Body: `{ "type": "...", "ref": "...", "occurredAt": "...", ...field per tipe }`.
`occurredAt` boleh maks **7 hari ke belakang** dan maks 5 menit ke depan (toleransi jam HP). `date`
(untuk `checkin`/`mission_completed`) wajib sama dengan tanggal lokal `occurredAt` di zona waktu user.

| `type` | Field tambahan | Koin (bucket earned) | Progres monster | Batas & kunci idempotensi bisnis |
|---|---|---|---|---|
| `checkin` | `date` | +5; streak +1; milestone 7 hari +20, 30 hari +100; pelindung streak dipakai otomatis bila 1 hari bolong | — | 1×/hari · `checkin:<date>` · **isi mood/faktor/catatan TIDAK dikirim** |
| `journal_saved` | `entryId`, `promptId?` (atau `promptMonsterId?`) | +4 | +2 ke `promptMonsterId` | `journal:<entryId>`; dapat koin maks `journalRewardsPerDay` entri/hari (diatur admin, §3.11); batas gratis & prompt premium lihat §3.4 · **teks jurnal TIDAK dikirim** |
| `meditation_completed` | `sessionId` (`targetMonsterId` diabaikan — target dari katalog) | +3 | +3 ke target | `meditation:<sessionId>:<date>`; dapat koin maks `meditationRewardsPerDay` sesi/hari (diatur admin, §3.11); sesi premium oleh user non-Premium → tanpa koin & progres, `capReason: "premium_required"` |
| `betterme_lesson_completed` | `lessonId` | +10 | — | sekali seumur akun per lesson · `betterme:<lessonId>`; level terkunci untuk non-Premium → tanpa koin, `capReason: "premium_required"` · **refleksi TIDAK dikirim** |
| `mission_completed` | `date`, `index` (0–2) | +3 | — | 3/hari · `mission:<date>:<index>` |
| `minigame_finished` | `saboteurId`, `won`, `ref` | +8 bila menang | +5 menang / +2 kalah | maks 4 pertarungan/hari · `minigame:<ref>` |
| `focus_completed` | `ticketId`, `saboteurId` | — | +4 | wajib tiket Fokus milik user & belum dipakai (§3.7) · `focus:<ticketId>`; `occurredAt` **dan jam server** ≥ `issuedAt` + durasi − 1 menit (sesi tidak bisa "selesai" instan), sesi harus dimulai (`occurredAt` − durasi) sebelum `expiresAt`, dan rentang sesi tidak boleh tumpang tindih (> 1 menit) dengan sesi lain yang sudah ditukar — beberapa tiket tidak bisa dibayar untuk menit yang sama; gagal → `409 ticket_invalid` (di batch: error per event) |

Monster yang mencapai 100 → `state=tamed`, +50 koin **sekali** (`tamed:<saboteurId>`). Tidak ada tipe
event yang berasal dari pembelian — progres monster tidak bisa dibeli (CLAUDE.md aturan #4).

Detail implementasi (B2):
- `capReason`: `daily_cap` (batas harian/admin), `free_daily_limit` (jurnal gratis 1/hari), `premium_required`
  (konten Premium oleh user gratis), `locked` (Better Me level berikutnya sebelum level sebelumnya selesai).
- Monster target meditasi diambil dari katalog, bukan dari client. Monster jurnal diambil dari `promptId`.
- Monster yang dikenal: 7 saboteur + 6 monster kebiasaan (`nanti`, `gulir`, `begadang`, `bunglon`, `bimbang`, `bara`).
- Check-in: hari berurutan menambah streak; tepat satu hari bolong dijembatani 1 pelindung streak (otomatis
  terpakai); bonus streak dibayar saat streak mencapai tepat 7 dan 30. Hanya check-in untuk **hari ini atau
  kemarin** (waktu diproses) yang bisa menggerakkan streak; laporan yang lebih lama tetap dibayar koinnya
  tetapi tidak bisa "menambal" hari yang terlewat (kalau bisa, pelindung streak jadi tidak berguna).
- Setiap event diproses sekali per kunci bisnis (`activity_events`, append-only); replay mengembalikan hasil
  tersimpan dengan `replayed: true`.

Respons:

```json
{
  "result": { "type": "minigame_finished", "key": "minigame:5d1c…", "coinsGranted": 8, "capped": false,
              "monster": { "saboteurId": "waswas", "state": "taming", "progress": 47, "justTamed": false, "tamedBonus": 0 },
              "streak": null, "replayed": false },
  "wallet": { "coins": 63, "earnedCoins": 51, "purchasedCoins": 12 }
}
```

### 3.4 Jurnal — cek akses premium

App sekarang membatasi jurnal di HP: pengguna gratis **1 entri/hari** (`EconomyFreeTier.jurnalPerHari`),
Premium tanpa batas; `CLAUDE.md` juga menyebut "jurnal CBT" sebagai perk Premium. Endpoint ini menjadikan
server sumber jawaban "boleh menulis jurnal / prompt ini premium atau tidak".

| # | Method & path | Akses | RL | Idem | Fungsi |
|---|---|---|---|---|---|
| 35 | `GET /v1/journal/access?promptId=` | user | 60/mnt | — | status premium jurnal hari ini + status tiap prompt (atau satu prompt bila `promptId` diisi) |

```json
{
  "date": "2026-10-11",
  "premium": false,
  "entriesToday": 1,
  "freeEntriesPerDay": 1,
  "canWrite": false,
  "reason": "daily_limit",
  "rewardedToday": 1,
  "rewardsPerDay": 3,
  "prompts": [
    { "id": "p_hakim", "monsterId": "hakim", "premium": false, "locked": false },
    { "id": "p_kabut", "monsterId": "kabut", "premium": false, "locked": false }
  ]
}
```

- `premium` = status langganan user saat ini (sama dengan `GET /v1/me`). `prompts[].premium` = prompt itu
  konten Premium atau bukan, dari katalog `journalPrompts` di `docs/catalog.json`. Saat ini kelima prompt
  (`p_hakim`, `p_kabut`, `p_cermin`, `p_waswas`, `p_mengelak`) **tidak** premium, sama dengan app; menandai
  prompt jadi premium cukup ubah katalog.
- `locked` = `true` bila prompt premium dan user bukan Premium.
- `canWrite` = `false` dengan `reason`:
  - `daily_limit` — user gratis sudah menulis `freeEntriesPerDay` entri hari ini;
  - `premium_required` — hanya bila `promptId` diisi dan prompt itu premium.
- `entriesToday` dihitung dari event `journal_saved` yang **sudah sampai** ke server (isi jurnal tidak
  pernah dikirim). Entri yang ditulis offline baru terhitung setelah outbox terkirim, jadi app tetap
  memakai hitungan lokal sebagai cadangan saat offline.
- `promptId` tidak dikenal → `404 not_found`.
- Penegakan di `POST /v1/activities` (`journal_saved`): user gratis yang melewati batas harian, atau
  menulis dengan prompt premium, tetap dijawab **200** tapi `coinsGranted: 0`, tanpa progres monster,
  `capped: true`, `capReason: "free_daily_limit"` / `"premium_required"` (aturan §1.3 — tidak menghukum,
  tidak membuat outbox me-retry).

### 3.5 Wallet & premium harian

| # | Method & path | Akses | RL | Idem | Fungsi |
|---|---|---|---|---|---|
| 18 | `GET /v1/wallet` | user | 60/mnt | — | saldo (`coins`, `earnedCoins`, `purchasedCoins`, `debtCoins`) |
| 19 | `GET /v1/wallet/transactions` | user | 30/mnt | — | riwayat ledger (paging cursor) untuk `KoinHistoriScreen` |
| 20 | `POST /v1/premium/daily-coins` | permanent | 10/mnt | ✓ | +2 koin pelanggan **tahunan** aktif, 1×/hari, masuk bucket purchased · `premium_daily:<date>` |

### 3.6 Toko & loadout

| # | Method & path | Akses | RL | Idem | Fungsi |
|---|---|---|---|---|---|
| 21 | `POST /v1/shop/purchase` | user | 10/mnt | ✓ | beli dengan koin: `{ itemType, itemId, expectedPrice }` |
| 22 | `PUT /v1/loadouts/monsters/{saboteurId}` | user | 30/mnt | ✓ | kosmetik terpasang di monster (harus dimiliki, slot sesuai) |
| 23 | `PUT /v1/loadouts/characters/{testId}` | user | 30/mnt | ✓ | aksesori + gaya kartu karakter kepribadian |

`itemType`:

| `itemType` | Harga (dari katalog server) | Efek |
|---|---|---|
| `cosmetic` | 100/300/500 (skin), 60/100/300 (aksesori kecil/biasa/langka), gaya kartu 100/300. `itemId` = id inventori: kosmetik monster (`topi_rajut`), aksesori `acc_<id>`, gaya kartu `cardstyle_<id>` (`klasik` gratis, tidak dijual) | masuk `inventory` (kepemilikan global) |
| `cosmetic_bundle` | 80% dari total item yang **belum** dimiliki, dibulatkan ke 5 | semua item bundel masuk inventory |
| `streak_shield` | 20 | `consumables.streak_shield +1` |
| `focus_pack` | `focus_1` = 25 (1 sesi), `focus_5` = 100 (5 sesi, layar "Beli sesi fokus") | `consumables.prepaid_focus +1 / +5` |

Aturan: belanja memotong bucket **purchased dulu**, lalu earned. `expectedPrice` ≠ harga server →
`409 price_changed` (client memuat ulang `/v1/config`). Saldo kurang → `409 insufficient_coins` dengan
`details.shortfall`; layar koin-kurang **wajib** menawarkan latihan dulu sebelum tombol beli (aturan #4).
Item eksklusif (`exclusiveTo: "jung"`) boleh dibeli, tapi `PUT /v1/loadouts/characters/{testId}` menolak
memasangnya di karakter lain. Gaya kartu berbayar boleh dipasang tanpa dibeli bila Premium aktif. Katalog lengkap (harga sudah dihitung) ada di
`GET /v1/config` bagian `catalog`, bersumber dari `docs/catalog.json`.

### 3.7 Mode Fokus (tiket bertanda tangan, jalan offline)

| # | Method & path | Akses | RL | Idem | Fungsi |
|---|---|---|---|---|---|
| 24 | `POST /v1/focus/tickets` | user | 20/mnt | ✓ | terbitkan tiket: `{ source: "free_daily" \| "prepaid" \| "coins", durationMin: 25\|45\|60, expectedPrice? }` |
| 25 | `GET /v1/focus/tickets` | user | 30/mnt | — | tiket aktif yang belum dipakai |

- `free_daily`: 1/hari (Premium 3/hari, hari = zona waktu user), tiket berlaku sampai tengah malam lokal.
  Habis → `409 limit_reached` (`reason: "free_daily"`, `resetsAt`).
- `prepaid`: memotong satu `consumables.prepaid_focus`, berlaku 30 hari. Tidak ada sesi →
  `409 limit_reached` (`reason: "no_prepaid_sessions"`). Gratis & prabayar berlaku untuk durasi apa pun
  (default — lihat `docs/todo-luar-backend.md` §D).
- `coins`: memotong 25/40/50 koin (durasi 25/45/60, purchased dulu lalu earned), berlaku 30 hari.
  `expectedPrice` wajib → `409 price_changed` / `409 insufficient_coins` seperti toko.
- Sesi prabayar/koin sudah terpakai saat tiket terbit: app meminta tiket jenis ini **saat user memulai sesi**,
  bukan di muka. Tiket yang kedaluwarsa tidak dikembalikan.
- Respons `POST`: `{ ticket, price, freeFocusLeft, prepaidFocus, wallet }`. `GET`: `{ tickets: [...], keys }`
  (tiket aktif yang belum dipakai, ditandatangani ulang dengan kunci saat ini).
- Tiket = `{ id, userId, source, durationMin, issuedAt, expiresAt, kid, sig }` (waktu RFC 3339 UTC, detik
  bulat). `sig` = Ed25519, base64url tanpa padding, atas byte string
  `riung-focus-ticket.v1|<kid>|<id>|<userId>|<source>|<durationMin>|<issuedAt>|<expiresAt>`. Kunci publik
  (`{kid, alg: "Ed25519", publicKey}` base64url) ada di `GET /v1/config` → `focusTicketKeys` dan di
  `GET /v1/focus/tickets` → `keys`. HP menyimpan tiket dan bisa memulai sesi **tanpa internet**; saat
  online, sesi selesai dilaporkan lewat `focus_completed` (§3.3) → tiket ditandai terpakai, sekali saja.
  Server tidak mempercayai tanda tangan saat penukaran — baris DB yang menentukan.
- App membuka layar Fokus → bila online, minta tiket `free_daily` di muka supaya tetap jalan saat offline.

### 3.8 Aplikasi Beku (buka-waktu berbayar)

| # | Method & path | Akses | RL | Idem | Fungsi |
|---|---|---|---|---|---|
| 26 | `POST /v1/appbeku/unlocks` | user | 10/mnt | ✓ | satuan `{ appId, minutes, expectedPrice }` atau bundel `{ bundleId, appIds?, expectedPrice }` |

- Katalog di `docs/catalog.json` → `appbeku` dan `GET /v1/config` → `catalog.appbeku`: `apps` (`id` = package
  name dari `core/config/appbeku_catalog.dart`, `group` `sosmed`/`game`; WhatsApp tidak bisa dibekukan),
  `units` (10/20/30/60 menit = 15/25/35/60 koin), `bundles` (`santai` = Instagram 15 + TikTok 15 menit,
  35 koin, `appIds` boleh dikosongkan; `sosmed` = 30 menit tiap aplikasi sosmed yang dibekukan — `appIds`
  wajib, 1–4 aplikasi grup `sosmed` berbeda — 75 koin).
- `appId` di luar katalog ditolak. Server **tidak menyimpan dan tidak mencatat aplikasi mana yang dibuka**:
  baris `appbeku_unlocks`, ledger (`ref` = `unit` atau id bundel), dan log hanya berisi jenis, menit, harga.
- Harga = harga dasar + `escalationPerUnlock` × jumlah buka-berbayar hari ini (ke-1: dasar, ke-2: +10,
  ke-3: +20). `expectedPrice` harus sama → selain itu `409 price_changed` dengan `details.price`.
- Respons: `{ result: { target, grants: [{appId, minutes}], price, paidUnlocksUsed, paidUnlocksLeft,
  cooldownUntil }, wallet }` — app membuka menit di `grants` secara lokal.
- Pengaman etis ditegakkan server (urutan cek: batas → jeda → harga → saldo): maks **3**
  buka-berbayar/hari → `409 limit_reached` (`reason: "daily_paid_unlocks"`, `resetsAt`); harga naik **+10**
  tiap buka ke-n hari itu; jeda **60 detik** antar buka berbayar (juga lintas hari) → `409 cooldown`;
  **hanya bucket earned** (koin beli & koin harian tahunan tidak bisa) → `409 insufficient_coins`
  (`earnedOnly: true`). Request yang ditolak tidak dihitung dan tidak memulai jeda.
- Bundel (`santai` = Instagram 15 mnt + TikTok 15 mnt; `sosmed` = 30 mnt tiap aplikasi sosmed yang
  dibekukan) diproses **atomik**: satu potongan koin, dihitung **satu** buka-berbayar, semua menit dibuka
  bersamaan — atau tidak sama sekali.
- Jalur napas gratis tidak lewat server dan tidak pernah dibatasi.

### 3.9 Pembelian Google Play

| # | Method & path | Akses | RL | Idem | Fungsi |
|---|---|---|---|---|---|
| 27 | `POST /v1/billing/verify` | permanent | 10/mnt, 30/jam | ✓ | `{ productId, purchaseToken }` → verifikasi ke Google → kredit koin / aktifkan Premium |
| 28 | `POST /v1/billing/restore` | permanent | 5/jam | ✓ | `{ purchases: [{productId, purchaseToken}] }` (≤ 20) — dari `restorePurchases()` |
| 29 | `GET /v1/billing/subscription` | user | 30/mnt | — | status Premium terbaru |
| 30 | `POST /v1/webhooks/google-play` | google | 120/mnt per IP + 300/mnt global | — | Real-time Developer Notifications (Pub/Sub push): renew, cancel, expire, revoke, refund |

Alur `verify`:
1. `productId` harus ada di daftar SKU server (`coin_pack_small|medium|large`, `premium_monthly|yearly`).
2. Panggil Android Publisher API (`purchases.products.get` / `purchases.subscriptionsv2.get`).
3. Wajib: `purchaseState = PURCHASED`, `obfuscatedExternalAccountId` = `billingAccountId` user ini (§3.2),
   token belum pernah dikreditkan ke akun **mana pun** (`purchases.purchase_token` PRIMARY KEY).
4. Koin paket → bucket **purchased** (80 / 330 / 820). Premium → `subscriptions.expires_at` dari Google.
5. Server **tidak** meng-consume. Setelah server menjawab sukses, app memanggil `completePurchase`
   (acknowledge/consume di sisi Play). Kalau app gagal menyelesaikan, job `riung billing-sync` (cron tiap jam)
   meng-**acknowledge** (bukan consume) pembelian yang sudah dikreditkan/diaktifkan tapi masih belum di-ack
   setelah 1 jam — koin paket maupun langganan — supaya Google tidak me-refund otomatis di hari ke-3.
   App tetap wajib meng-consume paket koin agar paket yang sama bisa dibeli lagi.
6. `riung billing-sync` juga membaca `voidedpurchases.list` (30 hari terakhir, idempoten); notifikasi RTDN
   `voidedPurchaseNotification` menjalankan hal yang sama seketika. Paket koin: ditarik **persis sebanyak yang
   dulu dikreditkan** (dari ledger), bucket purchased dulu lalu earned; sisa yang tidak tertutup dicatat di
   `wallets.debt_coins` dan dilunasi dari kredit berikutnya (saldo tidak pernah negatif); ledger `type=refund`;
   token ditandai `voided` dan tidak bisa diverifikasi lagi. Langganan: status dibaca ulang dari Play — kalau
   Google mencabut akses (atau token sudah tidak dikenal) Premium berakhir saat itu juga; refund satu periode
   tanpa pencabutan membiarkan Premium tetap jalan sesuai keputusan Google.
7. Langganan diperpanjang/di-upgrade: token baru membawa `linkedPurchaseToken` → token lama ditandai
   `superseded_by`, hak Premium pindah ke token baru (tidak dobel). Token lama/yang berakhir lebih cepat tidak
   pernah menimpa langganan yang sedang berlaku (mis. lewat restore).
8. RTDN: pesan Pub/Sub diproses idempoten (`rtdn_messages.message_id`), lalu status selalu dibaca ulang
   dari Android Publisher API — isi notifikasi tidak dipercaya mentah. Notifikasi untuk token yang belum
   pernah diverifikasi (dan bukan penerus token milik user) diabaikan sampai app memanggil `verify`.
9. Status Premium: `canceled` (auto-renew dimatikan) tetap aktif sampai `expiresAt`; `in_grace` aktif;
   `on_hold`, `paused`, `expired`, `revoked` tidak aktif.

Respons `verify` (200):
```json
{ "result": { "productId": "coin_pack_medium", "kind": "consumable", "status": "credited", "coinsGranted": 330,
              "test": false },
  "wallet": { "coins": 330, "earnedCoins": 0, "purchasedCoins": 330 },
  "premium": { "status": "none", "plan": null, "expiresAt": null, "autoRenewing": false } }
```
`result.premiumUntil` hanya ada untuk langganan. `result.status`: `credited` (koin baru masuk) · `already_credited` (token ini sudah pernah dikreditkan ke akun
yang sama — aman untuk retry/restore) · `pending` (pembayaran tertunda; **jangan** `completePurchase`, tunggu
update pembelian lalu panggil `verify` lagi) · `active` / `inactive` (langganan). App memanggil
`completePurchase` untuk `credited`, `already_credited`, `active`, `inactive`.
Error: `409 purchase_invalid` (Google tidak mengonfirmasi pembelian untuk akun ini: token palsu/milik akun lain/
dibatalkan/sudah di-refund) · `400 invalid_request` (productId tidak dikenal) · `503 unavailable` (Google Play
tidak bisa dihubungi atau billing belum dikonfigurasi — app me-retry nanti, pembelian tetap tersimpan di Play).

`restore` menjawab `{ "results": [{ "productId", "ok", "result" | "error": {code, message} }], "wallet", "premium" }`
— satu item gagal tidak menggagalkan yang lain; gangguan Google/DB atau melewati anggaran 12 detik menggagalkan
seluruh request (503/500) dan app mengulang (token yang sudah diverifikasi dijawab dari DB). Setiap panggilan ke
Google dibatasi 5 detik.

Langganan hasil berlangganan ulang dari Play Store bisa datang tanpa `obfuscatedExternalAccountId`: token seperti
itu hanya diterima `verify`/`restore` setelah server mengikatnya ke user lewat `linkedPurchaseToken` (RTDN).

Webhook: autentikasi token OIDC Google dari push subscription — tanda tangan, `exp`, `aud` = `RTDN_AUDIENCE`,
`iss` = `accounts.google.com`, `email` = `RTDN_SERVICE_ACCOUNT` dan `email_verified`. Jawaban: `204` (diproses,
duplikat, atau isi tidak bisa dibaca — retry tidak akan pernah berhasil, jadi di-ack dan dicatat), `401` token
salah, `429`/`5xx` gangguan sementara (Pub/Sub mengulang; id pesan dilepas lagi bila pemrosesan gagal, terputus,
atau panic, sehingga ulangan tidak dianggap duplikat). `packageName` selain `PLAY_PACKAGE_NAME` diabaikan.

Dev (`DEV_BILLING=true`, hanya `RIUNG_ENV=dev`): Google Play dipalsukan — token
`dev-coin:<billingAccountId>:<productId>:<n>` dan `dev-sub:<billingAccountId>:<productId>:<hari>:<n>`,
bearer webhook `dev-pubsub`.

### 3.10 Daftar yang sengaja TIDAK ada di server (privasi)

Tidak ada endpoint, tabel, atau log untuk: **isi jurnal**, isi check-in (mood, faktor, catatan),
**hasil Kenali Dirimu** (tes kesehatan mental — tetap terenkripsi di HP), refleksi Better Me, data tidur
Health Connect, daftar aplikasi dibekukan & statistik pemakaian aplikasi, afirmasi buatan/favorit, laporan
mingguan/bulanan (dihitung di HP), dan **layar krisis** (tidak pernah dipanggil ke server maupun dilog).

### 3.11 Admin API — pengaturan yang bisa diubah tanpa deploy

Admin bisa mengubah sebagian angka secara langsung. Supaya aman, Admin API **tidak dibuka ke internet**:

- Dilayani `riung-api` di **port internal terpisah `8081`** (`ADMIN_LISTEN_ADDR`) yang **tidak** dipasang
  di nginx — tidak bisa diakses lewat `riung.e55techlab.com`.
- Hanya menerima koneksi dari VPN kantor: klien OpenVPN (`192.168.255.0/24`) di-MASQUERADE oleh
  `shared-openvpn`, jadi sumber yang diizinkan = `172.19.0.7`. Diatur lewat env `ADMIN_ALLOWED_CIDRS`;
  koneksi lain (termasuk container lain di `vps-shared-net`) ditolak sebelum autentikasi. Trafik tetap
  terenkripsi di dalam tunnel OpenVPN. App Check tidak dipakai di port ini (dipanggil dari laptop, bukan app).
- Autentikasi: ID token Firebase akun **non-anonim, email terverifikasi**, punya custom claim
  `riungAdmin: true` **dan** terdaftar di tabel `admins`; token dicek pencabutan + `auth_time` ≤ 15 menit.
  Admin ditambah/dicabut hanya lewat CLI di server: `riung admin grant <email> <alasan>` / `riung admin revoke <email> <alasan>`.
- Setiap perubahan wajib `reason`, dicatat di `admin_audit_log` (append-only) + log `admin_setting_changed`
  (alert ke tim disiapkan di B6, §6.6).
- Contoh pemakaian (dari laptop yang tersambung VPN):
  Lokal (`DEV_AUTH`): token `dev:<uid>:google.com:admin`.
  `curl -X PUT http://172.19.0.16:8081/admin/v1/settings/journalRewardsPerDay -H "Authorization: Bearer $TOKEN" -H "Idempotency-Key: $(uuidgen)" -d '{"value":5,"reason":"uji batas baru"}'`

| # | Method & path | RL | Idem | Fungsi |
|---|---|---|---|---|
| 31 | `GET /admin/v1/settings` | 30/mnt | — | semua pengaturan: nilai aktif, default, min, max, `updatedAt`, `updatedBy` |
| 32 | `PUT /admin/v1/settings/{key}` | 10/mnt | ✓ | `{ value, reason }` — divalidasi rentang, berlaku **langsung** |
| 33 | `DELETE /admin/v1/settings/{key}` | 10/mnt | ✓ | kembalikan ke default (`economy-props.json`) |
| 34 | `GET /admin/v1/audit?limit=&cursor=` | 30/mnt | — | riwayat perubahan pengaturan |

Pengaturan yang bisa diubah (allowlist — key lain ditolak):

| `key` | Arti dalam bahasa sehari-hari | Default | Rentang |
|---|---|---|---|
| `journalRewardsPerDay` | berapa entri jurnal per hari yang masih dapat koin (+4 per entri). Entri berikutnya tetap tersimpan, hanya tanpa koin | 3 | 0–20 |
| `meditationRewardsPerDay` | berapa sesi meditasi per hari yang masih dapat koin (+3 per sesi) | 3 | 0–20 |
| `maxNewAccountsPerIpPerDay` | batas akun baru dari satu alamat IP per hari | 10 | 1–1000 |

- Nilai disimpan di tabel `app_settings` (menimpa default dari `economy-props.json`), di-cache di memori
  dan diperbarui seketika saat diubah.
- Batas jurnal/meditasi ikut tampil di `GET /v1/config` (`caps.journalRewardsPerDay`,
  `caps.meditationRewardsPerDay`) — ETag berubah, jadi app langsung mendapat angka baru.
- Perubahan berlaku untuk klaim **berikutnya**; koin yang sudah diberikan tidak ditarik.
- Default 3 adalah usulan awal — admin bisa langsung mengubahnya setelah rilis.

### 3.12 Operasional lewat CLI

Operasi yang jarang dan berisiko tinggi tetap lewat CLI di container (`docker exec riung-api /riung …`),
bukan HTTP:

| Perintah | Isi |
|---|---|
| `migrate up\|status\|down` | migrasi (container `riung-migrate`, kredensial DDL; `down` ditolak di prod) |
| `seed-content <file\|->` | ganti konten publik dari seed JSON |
| `settings list` · `settings set <key> <value> <alasan>` · `settings reset <key> <alasan>` | jalur darurat tanpa VPN, tercatat dengan aktor `cli` |
| `admin grant\|revoke <email> <alasan>` | akses Admin API |
| `cleanup` (cron harian) | idempotensi > 7 hari, jti, penghitung lama, id RTDN > 30 hari, tiket Fokus & buka-berbayar > 90 hari |
| `billing-sync` (cron tiap jam) · `reconcile` (cron harian) | §3.9, §4.5 |
| `cleanup-anon [--dry-run]` (cron harian) | hapus akun anonim yang tidak dibuka > `ANON_RETENTION_DAYS` (default 90): data server lalu user Firebase; maks 1000 per jalan |
| `reapply-deletions` | setelah restore backup: hapus lagi akun yang tercatat di `deleted_users` (butuh `LOG_PEPPER` yang sama) |

Belum dibuat (menyusul bila dibutuhkan): `wallet-adjust` (koreksi saldo manual, wajib alasan, ledger
`type=adjust` + `admin_audit_log`). Rotasi kunci tiket Fokus lewat env (§4.6).

---

## 4. Keamanan

### 4.1 Jaringan & TLS
- Hanya `shared-nginx` yang membuka 80/443; `riung-api` **tanpa `ports:`**, hanya bisa dicapai lewat
  `vps-shared-net`. Postgres hanya di `vps-shared-net` + `127.0.0.1`.
- TLS 1.2/1.3, HSTS, redirect HTTP→HTTPS, cert Let's Encrypt (cron certbot yang sudah ada).
- `GET /readyz` dan path selain `/healthz` & `/v1/*` diblokir di nginx (`return 404`).
- Go **hanya** mempercayai `X-Real-IP` (diisi nginx dari `$remote_addr`) dan hanya bila koneksi berasal dari
  `172.19.0.2` (`shared-nginx`). `X-Forwarded-For` **diabaikan** — template nginx menambahkan nilai kiriman
  client ke header itu, jadi bisa dipalsukan untuk mengakali rate limit & batas akun per IP.

### 4.2 Autentikasi
- ID token Firebase diverifikasi lokal (tanda tangan, `aud` = project id, `iss`, `exp`, `iat`) via Admin
  SDK dengan cache kunci publik Google. Aksi `user+fresh` juga cek pencabutan token + `auth_time` ≤ 5 menit.
- Provider dibaca dari klaim `firebase.sign_in_provider` (`anonymous` / `password` / `google.com`).
- Identitas dipetakan lewat `auth_identities (provider, subject) → users.id` — siap untuk auth sendiri.
- Akun baru (anonim maupun permanen): maks **10 akun baru/IP/hari** (cegah farming koin dengan ratusan
  akun anonim). Angkanya pengaturan admin `maxNewAccountsPerIpPerDay` (§3.11). Catatan: operator seluler
  Indonesia memakai CGNAT (banyak pengguna berbagi satu IP) — pantau event `signup_limited`; bila
  pengguna sah ikut tertahan, admin menaikkan angkanya tanpa deploy. Saat batas tercapai, `GET /v1/me`
  untuk identitas baru menjawab `429 signup_limited` (akun lama di IP yang sama tidak terpengaruh).
- Kunci publik Google gagal diambil → `503 unavailable` (bukan 401), supaya app me-retry, bukan logout.

### 4.3 App Check
- Semua endpoint `app`/`user` mewajibkan `X-Firebase-AppCheck` (Play Integrity di Android).
- Rollout dua tahap lewat env `APP_CHECK_MODE`: `monitor` (hanya dicatat di log) → `enforce` (tolak).
- Endpoint sensitif (`billing/verify`, `DELETE /me`, `pin/verify`) memakai token **limited-use** dan
  mencatat `jti` supaya token yang sama tidak bisa diputar ulang.

### 4.4 Validasi input
- Decoder JSON ketat: field tak dikenal ditolak, body ganda ditolak, angka di luar rentang ditolak.
- Batas body: 16 KB umum, 64 KB `activities/batch`, 2 KB `waitlist`, 256 KB webhook.
- Enum & id dicocokkan ke katalog server (saboteur, kosmetik, lesson, sesi, appId, productId, testId).
- Panjang string dibatasi (`displayName` ≤ 40 karakter, tanpa karakter kontrol); email waitlist ≤ 254.
- Tanggal dalam jendela waktu yang masuk akal (§3.3).

### 4.5 Integritas ekonomi
- Harga & reward hanya dari server; client mengirim `expectedPrice` sekadar untuk deteksi perubahan.
- Setiap mutasi wallet: transaksi DB + `SELECT … FOR UPDATE` + insert ledger idempoten + CHECK `>= 0`.
- Hak role DB `riung_app` (pemilik tabel = `riung_migrator`):
  - `coin_ledger`, `admin_audit_log`: **hanya `INSERT`/`SELECT`** — tidak bisa diubah/dihapus aplikasi.
  - `purchases`: `INSERT`/`SELECT` + `UPDATE` hanya kolom status (`state`, `credited_at`,
    `acknowledged_at`, `voided_at`, `superseded_by`, `raw`) — tidak bisa `DELETE`.
  - tabel lain: `SELECT/INSERT/UPDATE/DELETE`.
  - Penghapusan akun memakai `ON DELETE CASCADE` / `SET NULL` yang dijalankan Postgres dengan hak pemilik
    tabel, jadi tetap jalan tanpa memberi `DELETE` langsung pada tabel jejak.
- Rekonsiliasi harian: `wallets` harus = jumlah `coin_ledger` per user; selisih → log `error` + alert.

### 4.6 Tiket Fokus
- Ditandatangani Ed25519 (seed 32 byte di env `FOCUS_TICKET_KEY`, hanya di server; `FOCUS_TICKET_KID` untuk
  rotasi); terikat ke `userId`, durasi, dan `expiresAt`; dipakai sekali (`consumed_at`, dikunci per baris).
- Rotasi: ganti `FOCUS_TICKET_KEY` + `FOCUS_TICKET_KID`, deploy. Tiket lama tetap sah di server (DB yang
  menentukan); app mengambil ulang tiket (`GET /v1/focus/tickets`) dan kunci baru dari `/v1/config` saat online.

### 4.7 PIN jurnal
- Server menyimpan `HMAC-SHA256(pepper_server, hashDariHP)` — bukan hash mentah — sehingga dump DB
  saja tidak cukup untuk brute-force PIN 4–6 digit.
- Verifikasi hanya lewat `POST …/verify` (perbandingan constant-time) dengan rate limit + lockout.

### 4.8 Server HTTP & container
- Go `http.Server`: `ReadHeaderTimeout 5s`, `ReadTimeout 10s`, `WriteTimeout 15s`, `IdleTimeout 60s`,
  `MaxHeaderBytes 16KB`; middleware recover (panic → 500 tanpa stack trace ke client).
- DB: `statement_timeout 5s`, pool maks 10, query ditulis tangan di `internal/store` dan selalu memakai parameter pgx (`$1`) — tidak ada SQL dari string gabungan.
- Container: distroless `nonroot`, `read_only: true` (+ `tmpfs: /tmp`), `cap_drop: [ALL]`, `security_opt:
  [no-new-privileges:true]`, `mem_limit: 256m`, `cpus: 1`, `pids_limit: 200`. Container `riung-api` hanya
  memegang kredensial `riung_app`; kredensial `riung_migrator` hanya ada di `riung-migrate`.
- CORS: tidak ada sama sekali, **kecuali** `POST /v1/waitlist` untuk origin landing.
- Header respons API: `Cache-Control: no-store` (kecuali config/content), `X-Content-Type-Options: nosniff`.

### 4.9 Data pribadi & penghapusan
- Data yang disimpan minimal (§3.10). Logs tanpa PII (§6.3).
- `DELETE /v1/me`: hapus semua baris user (cascade) + user Firebase Auth. Catatan `purchases` dianonimkan
  (FK `ON DELETE SET NULL`, tersisa `user_hash`) untuk sengketa/refund — retensi mengikuti kebutuhan pajak.
- Backup harian (retensi 14 hari) masih memuat data user yang sudah dihapus sampai backup itu kedaluwarsa —
  dicantumkan di kebijakan privasi; restore dari backup wajib menjalankan `riung reapply-deletions`
  (`deleted_users`, hanya berisi hash id) sebelum API melayani trafik.
- Akun **anonim** yang tidak dibuka lebih dari 90 hari (`ANON_RETENTION_DAYS`) dihapus otomatis
  (`riung cleanup-anon`), termasuk user Firebase-nya.
- Selaras UU 27/2022 tentang Pelindungan Data Pribadi: tujuan jelas, minimal, bisa diekspor (`/me/export`)
  dan dihapus.

### 4.10 Risiko yang diterima (diketahui, dibatasi)

- **Event mundur oleh client yang dimodifikasi**: event boleh dilaporkan sampai 7 hari ke belakang (outbox
  offline). Client yang dimodifikasi bisa mengklaim reward hari-hari yang terlewat dalam jendela itu — tetap
  dibatasi cap harian per hari, streak hanya bisa digerakkan hari ini/kemarin, dan App Check `enforce`
  mempersulit klien palsu. Memperpendek jendela ke 72 jam adalah keputusan produk
  (`docs/todo-luar-backend.md` §D).
- **Ganti zona waktu**: user bisa "memajukan" hari esok dengan mengganti zona waktu, tetapi tiap tanggal
  hanya bisa dipakai sekali per batas, jadi tidak ada keuntungan bersih dalam jangka panjang. Ini juga
  berlaku untuk tiket Fokus gratis dan batas 3 buka-berbayar Aplikasi Beku: pengaman etis melindungi dari
  keputusan impulsif, bukan dari user yang sengaja mengakalinya; jeda 60 detik tetap berlaku lintas hari.
- **Sesi Fokus tidak bisa dibuktikan**: server tidak tahu apakah user benar-benar fokus. Dibatasi oleh
  jumlah tiket, durasi minimum menurut jam server, dan larangan sesi tumpang tindih — progres paling cepat
  sama dengan user jujur yang benar-benar menjalankan sesinya.
- **Event yang ter-cap dicatat permanen** per kunci bisnis (mis. sesi meditasi premium sebelum berlangganan
  hari itu tidak dibayar ulang setelah berlangganan; sesi lain tetap bisa).
- **Admin API memakai HTTP biasa** di dalam tunnel VPN dan bridge Docker; token admin wajib login ≤ 15 menit.
  `riung admin grant/revoke` mencabut sesi orang itu di semua perangkat agar klaim langsung berlaku.
- **Rate limit di memori** (satu instance): restart mengosongkan hitungan. Batas harian bisnis tetap di DB.
- Perubahan pengaturan lewat **CLI** berlaku ≤ 30 detik; lewat Admin API langsung.

### 4.11 Secrets & supply chain
- Secrets di `/var/www/riung/.env` (`chmod 600`): DB URL, path service account, kunci tiket Ed25519,
  pepper PIN & log, audience RTDN. Tidak pernah masuk log/image/repo.
- Service account khusus berperan minimum (Firebase Auth + Android Publisher), bukan `firebase-adminsdk`.
- CI: `go mod verify`, `govulncheck`, `golangci-lint` (gosec), scan image (Trivy), base image & action
  pihak ketiga di-pin digest/SHA, Dependabot (`.github/dependabot.yml`: modul Go & image Docker backend).
- Rotasi: kunci tiket Fokus punya `kid` (§4.6). `LOG_PEPPER`, `IP_HASH_KEY`, `PIN_PEPPER`,
  `BILLING_ACCOUNT_KEY` **tidak** bisa dirotasi begitu saja: mengganti `BILLING_ACCOUNT_KEY` membuat pembelian
  lama tidak cocok lagi dengan akunnya, `PIN_PEPPER` membatalkan semua backup PIN, `LOG_PEPPER` memutus
  `deleted_users`. Password DB dirotasi saat ada akses yang tidak lagi perlu.

---

## 5. Rate limit

Dua lapis — nginx menahan banjir per IP sebelum menyentuh Go; Go membatasi per **user** (tepat untuk
pengguna di belakang NAT/operator seluler yang berbagi IP).

### 5.1 Nginx (per IP)

Di `core-shared/nginx/conf.d/riung.e55techlab.com.conf` (konteks `http`, nama zone ber-prefix `riung_`):

```nginx
limit_req_zone  $binary_remote_addr zone=riung_api:10m      rate=50r/s;   # CGNAT: hanya penahan banjir
limit_req_zone  $binary_remote_addr zone=riung_waitlist:1m  rate=10r/m;
limit_conn_zone $binary_remote_addr zone=riung_conn:10m;

# di dalam server { listen 443 … }
limit_req_status 429;
limit_conn_status 429;
location /v1/                { limit_req zone=riung_api burst=100 nodelay;   limit_conn riung_conn 100; … }
location = /v1/waitlist      { limit_req zone=riung_waitlist burst=5 nodelay; … }
location = /v1/webhooks/google-play { … }   # tanpa limit per IP (IP Google bergantian), dijaga JWT
location = /healthz          { … }                 # liveness boleh dari luar
location /                   { return 404; }       # termasuk /readyz dan path lain
```

### 5.2 Aplikasi (per user, token bucket)

| Grup | Batas | Kunci |
|---|---|---|
| `GET /v1/me`, `GET /v1/wallet` | 60/mnt | user |
| `GET /v1/config`, `GET /v1/content/*` | 600/mnt (masing-masing) | IP — longgar karena CGNAT |
| `POST /v1/activities` | 60/mnt | user |
| `GET /v1/journal/access` | 60/mnt | user |
| `POST /v1/activities/batch` | 10/mnt (≤ 50 event) | user |
| `PATCH /me/profile` | 20/mnt | user |
| `PUT /me/assessment` | 10/mnt | user |
| `POST /shop/purchase`, `POST /appbeku/unlocks` | 10/mnt | user |
| `PUT /loadouts/*` | 30/mnt | user |
| `POST /focus/tickets` | 20/mnt | user |
| `GET /focus/tickets` | 30/mnt | user |
| `POST /billing/verify` | 10/mnt dan 30/jam | user |
| `POST /billing/restore` | 5/jam | user |
| `POST /me/link`, `PUT/DELETE /me/journal-pin-backup` | 5/jam | user |
| `POST /me/journal-pin-backup/verify` | 5/15 mnt; lockout 1 jam setelah 10 gagal/hari | user |
| `DELETE /v1/me`, `GET /v1/me/export` | 3/jam | user |
| Akun baru (anonim/permanen) | 10/hari (`maxNewAccountsPerIpPerDay`, diatur admin) | IP |
| Admin API `GET` / `PUT`·`DELETE` | 30/mnt / 10/mnt | admin |
| `POST /v1/waitlist` | 20/jam | IP |
| `GET /billing/subscription` | 30/mnt | user |
| `POST /v1/webhooks/google-play` | 120/mnt per IP sebelum autentikasi, 300/mnt global sesudahnya | IP / global |

- Setiap endpoint punya **bucket sendiri** walau angkanya sama (mis. ekspor data tidak pernah memblokir hapus
  akun, `GET /v1/me` tidak berbagi kuota dengan `/v1/wallet`).
- Respons 429 berisi header `Retry-After` dan `RateLimit-Policy` / `RateLimit` (format IETF draft),
  body `{"error":{"code":"rate_limited",…}}`.
- v1: limiter in-memory (satu instance `riung-api`). Kalau nanti >1 instance, pindah ke `shared-redis`
  (nomor DB khusus riung) supaya hitungan dibagi bersama.
- Batas bisnis harian (§1.3, §3) terpisah dari rate limit dan disimpan di DB (`daily_counters`), jadi
  tetap benar walau container restart.

---

## 6. Logging

### 6.1 Alur
`riung-api` → `slog` JSON ke **stdout** → Promtail (sudah ada) → Loki → Grafana
(`grafana.e55techlab.com`). Tidak ada file log di container (root filesystem read-only).

Pipeline Promtail untuk `container="riung-api"`: stage `json` → label **hanya** `level` dan `event`
(kardinalitas rendah, sesuai panduan core-shared); field lain dicari lewat filter LogQL.

### 6.2 Field standar

```json
{"time":"2026-10-11T03:04:05.123Z","level":"INFO","event":"http_request","msg":"request",
 "requestId":"01J9Z6…","method":"POST","route":"/v1/activities","status":200,"durationMs":23,
 "bytesOut":412,"user":"u_5f2c9a1e0b7d4c3a","anon":true,"ip":"ip_9e1d…","appVersion":"1.4.0+27",
 "platform":"android"}
```

- `route` = pola route (`/v1/loadouts/monsters/{saboteurId}`), bukan path mentah.
- `user` = `HMAC-SHA256(pepper_log, users.id)` 16 hex — bisa mengkorelasikan log satu user tanpa
  menyimpan id asli. `ip` = HMAC dengan kunci harian `HMAC(master_ip_key, tanggal)` — sama sepanjang hari (juga
  setelah restart, dan dipakai `signup_counters`), berganti besoknya: bisa melacak serangan di hari yang sama,
  tidak bisa melacak orang jangka panjang.
- `requestId` dikirim balik ke app; app menampilkannya di pesan error ("Kode: 01J9Z6…") dan mengirimnya ke
  Crashlytics sebagai custom key → satu error bisa dilacak dari HP sampai server.

### 6.3 Tidak pernah dicatat
Header `Authorization` & `X-Firebase-AppCheck`, body request/response, `purchaseToken` (hanya 6 karakter
terakhir), email waitlist (hanya hash), hash/salt PIN, tanda tangan tiket, connection string & secret,
uid Firebase mentah, nama tampilan. Isi jurnal/check-in/Kenali tidak pernah diterima server sehingga
tidak mungkin tercatat. Layar krisis tidak menghasilkan request apa pun.

### 6.4 Level & event

| Level | Kapan |
|---|---|
| `DEBUG` | hanya di dev (`LOG_LEVEL=debug`) |
| `INFO` | request selesai, event bisnis normal |
| `WARN` | kegagalan yang berasal dari client & relevan keamanan |
| `ERROR` | 5xx, error dependency (DB, Google API), selisih rekonsiliasi |

| `event` | Level | Field tambahan |
|---|---|---|
| `http_request` | INFO / WARN (4xx) / ERROR (5xx) | lihat §6.2 |
| `auth_failed` | WARN | `reason` (`expired`, `bad_signature`, `revoked`, `wrong_audience`) |
| `appcheck_failed` | WARN | `reason`, `mode` (`monitor`/`enforce`) |
| `rate_limited` | WARN | `limit`, `scope` (`user`/`ip`) |
| `account_created` / `account_linked` / `account_deleted` | INFO | `provider` |
| `wallet_mutation` | INFO | `type` (`earn`/`spend`/`purchase`), `kind` (mis. `checkin`, `cosmetic`, `appbeku_unlock`), `amount`, `bucket` (koin harian tahunan) |
| `shop_purchase` | INFO | `itemType`, `itemId`, `price` |
| `appbeku_unlock` / `appbeku_blocked` | INFO / WARN | `target` (`unit`/id bundel — bukan aplikasi), `n`, `price` / `reason` (`limit`, `cooldown`, `earned_only`) |
| `focus_ticket_issued` / `focus_ticket_redeemed` / `focus_ticket_invalid` | INFO / INFO / WARN | `source`, `durationMin` / — / `reason` (`not_found`, `used`, `too_early`, `expired`, `overlap`) |
| `purchase_verified` / `purchase_rejected` | INFO / WARN | `productId`, `tokenTail` (6 karakter terakhir), `status`, `coins`, `test` / `reason` (`not_valid_for_account`, `unknown_product`) |
| `rtdn_received` / `rtdn_rejected` | INFO / WARN | `kind`, `notificationType`, `productId`, `action` / `reason` (`auth`, `envelope`, `notification`) |
| `refund_applied` | WARN | `productId`, `coinsClawedBack`, `debt`, `premiumRevoked`, `orphan` |
| `pin_verify_failed` / `pin_locked` | WARN | `attemptsToday` |
| `idempotency_conflict` | WARN | `route` |
| `ledger_mismatch` | ERROR | `earned`/`ledgerEarned`, `purchased`/`ledgerPurchased`, `debt`/`ledgerDebt` (job `reconcile`) |
| `dependency_error` | ERROR | `dependency` (`postgres`, `google_play`, `firebase`), `op`, `durationMs` |
| `panic` | ERROR | `stack` (hanya di log, tidak ke client) |
| `job_run` | INFO / ERROR | `job` (`cleanup`, `cleanup_anon`, `billing_sync`, `reconcile`, `reapply_deletions`), `ok`, jumlah baris |
| `activity` | INFO | `type`, `coins`, `capReason` (bila ter-cap) |
| `waitlist_signup` / `content_seeded` | INFO (WARN bila honeypot) | `email` (hash), `new`, `honeypot` / `kind`, `locale`, `items` |
| `startup` / `shutdown` / `migration` / `command_error` | INFO / INFO / INFO / ERROR | `version`, `env`, `billing` / — / `version`, `file` / `command`, `error` |
| `signup_limited` | WARN | `limit` |
| `admin_setting_changed` | WARN | `key`, `old`, `new`, `admin` (hash), `reason` |
| `admin_access_denied` | WARN | `reason` (`source_ip`, `no_claim`, `not_listed`, `stale_token`) |

Jejak keuangan resmi tetap di DB (`coin_ledger`, `purchases`) — log hanya untuk observasi.

### 6.5 Retensi & akses
- Log riung di Loki disimpan **30 hari**. Saat ini Loki di VPS menyimpan semua log **7 hari**
  (`retention_period: 7d`, compactor retention aktif). Riung dibuat 30 hari tanpa mengubah app lain lewat
  retensi per-stream di `core-shared/monitoring/loki/config.yml` (commit ke branch `grafana`):

  ```yaml
  limits_config:
    retention_period: 7d            # tetap untuk app lain
    retention_stream:
      - selector: '{container="riung-api"}'
        priority: 1
        period: 720h                # 30 hari
  ```
- Jejak perubahan admin (`admin_audit_log`) dan keuangan (`coin_ledger`, `purchases`) ada di DB, tidak
  ikut terhapus bersama log.
- Akses Grafana hanya akun admin tim; Grafana tidak dibuka tanpa login (`GF_USERS_ALLOW_SIGN_UP=false`
  sudah aktif).
- Nginx `shared-nginx` mencatat IP asli di access log-nya sendiri (infrastruktur bersama) — ikut
  retensi yang sama.

### 6.6 Alert (Grafana Alerting, dari LogQL)

| Alert | Kondisi |
|---|---|
| Error server | `level="ERROR"` > 5 dalam 5 menit, atau 5xx > 1% request |
| Latensi | p95 `durationMs` > 500 ms selama 10 menit |
| Serangan auth | `auth_failed` + `appcheck_failed` > 100 dalam 5 menit |
| Rate limit melonjak | `rate_limited` > 200 dalam 5 menit |
| Pembelian | ada `purchase_rejected`, `refund_applied`, atau `rtdn` gagal diproses |
| Keuangan | ada `ledger_mismatch` |
| Job | `job_run` dengan `ok=false`; backup Postgres dipantau dari umur file dump terbaru (skrip cron, bukan log app) |
| Admin | setiap `admin_setting_changed` (info ke tim) dan `admin_access_denied` (curiga) |
| Pendaftaran | `signup_limited` > 20 dalam 1 jam (tanda CGNAT atau serangan) |
| Container | `riung-api` restart / healthcheck gagal |

Kanal notifikasi: email tim (kontak Grafana); bisa diteruskan ke n8n yang sudah ada.

---

## 7. Tabel tambahan (melengkapi plan §3)

```sql
idempotency_keys (user_id uuid, key uuid, route text, request_hash bytea, status int, response jsonb,
                  created_at timestamptz, PRIMARY KEY (user_id, key))          -- dibersihkan > 7 hari
monster_loadouts (user_id, saboteur_id text, item_ids text[], updated_at, PRIMARY KEY (user_id, saboteur_id))
character_loadouts (user_id, test_id text, accessory_ids text[], card_style text, updated_at,
                    PRIMARY KEY (user_id, test_id))
betterme_completions (user_id, lesson_id text, completed_at, PRIMARY KEY (user_id, lesson_id))
appbeku_unlocks (id uuid PK, user_id, target text, minutes int, price int, created_at)  -- target = 'unit' / id bundel, bukan aplikasi; jeda; dihapus > 90 hari
focus_tickets   + session_ended_at timestamptz (migrasi 00003)                  -- tolak sesi Fokus yang tumpang tindih
activity_events (user_id, key text, type text, result jsonb, created_at, PRIMARY KEY (user_id, key))  -- append-only
pin_attempts (user_id, day date, failures int, locked_until timestamptz, PRIMARY KEY (user_id, day))
appcheck_jti (jti text PRIMARY KEY, expires_at timestamptz)                    -- token limited-use
signup_counters (ip_hash text, day date, count int, PRIMARY KEY (ip_hash, day))
rtdn_messages (message_id text PRIMARY KEY, received_at timestamptz)         -- dedupe Pub/Sub
deleted_users (user_hash text PRIMARY KEY, deleted_at timestamptz)            -- untuk restore backup
-- perubahan pada tabel plan §3.2:
--   wallets      + debt_coins int NOT NULL DEFAULT 0 CHECK (debt_coins >= 0)
--   purchases    user_id NULL REFERENCES users ON DELETE SET NULL, + user_hash text, + superseded_by text
app_settings (key text PRIMARY KEY, value jsonb NOT NULL, updated_at timestamptz, updated_by uuid)
admins (user_id uuid PRIMARY KEY REFERENCES users, granted_at timestamptz, granted_by text)
admin_audit_log (id uuid PK, admin_user_id uuid NULL, actor text NOT NULL,      -- 'admin:<hash>' / 'cli'
                 action text, key text, old_value jsonb, new_value jsonb,
                 reason text NOT NULL, request_id text, created_at timestamptz)   -- append-only
```

`journal_pin_backups.hash` menyimpan nilai HMAC berpepper (§4.7).

---

## 8. Urutan implementasi (mengikuti fase plan)

| Fase | Endpoint |
|---|---|
| B0 | #1–2, logging §6, middleware request id / recover / limit body / rate limit dasar |
| B1 | #3–15, auth + App Check (`monitor`), pemetaan identitas |
| B2 | #16–23, #35 (akses jurnal), #31–34 (Admin API + `app_settings`), ledger, idempotensi, batas harian |
| B3 ✅ | #27–30, `billing-sync` (refund & acknowledge), `reconcile` |
| B4 ✅ | #24–26, `focus_completed` |
| B5 | deploy ke VPS, `cleanup-anon`, `reapply-deletions`, Dependabot, rate limit nginx (§5.1) |
| B6 | App Check `enforce`, alert Grafana (§6.6), uji beban & review keamanan |
