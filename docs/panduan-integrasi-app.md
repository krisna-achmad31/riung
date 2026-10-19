# Panduan integrasi app ↔ backend Riung
*Untuk tim Flutter (`riung/`) · backend Go di `backend/` · API `/v1` · diperbarui 2026-10-20*

Backend Go menggantikan peran "Cloud Functions" di `CLAUDE.md`: semua koin, progres monster, pembelian,
tiket Fokus, dan buka-waktu Aplikasi Beku sekarang diputuskan server. App mengirim **apa yang terjadi**,
server yang menentukan **berapa nilainya**. Firebase tetap dipakai untuk login (Auth), App Check,
Analytics, Crashlytics, dan Remote Config (hanya saklar fitur/A-B, bukan harga).

Dokumen ini panduan praktis. Kontrak lengkap (semua field, batas, keamanan): `docs/backend-api-spec.md`.
Untuk mencoba setiap endpoint: Postman collection di `backend/postman/`. Perubahan API per rilis:
`backend/CHANGELOG.md`. Daftar pekerjaan app yang sudah
dipetakan: `docs/todo-luar-backend.md` §B–C.

---

## 1. Lingkungan

| | URL | Login | App Check |
|---|---|---|---|
| Produksi | `https://riung.e55techlab.com/v1` | ID token Firebase (`riung-5e979`) | `monitor` (belum menolak) |
| Lokal | `http://localhost:8080/v1` (`cd backend && make dev-up`) | token dev `dev:<uid>:<provider>` | mati |

Lokal memakai `DEV_AUTH`: token `Bearer dev:rani:anonymous` (atau `:password`, `:google.com`, `:apple.com`) menggantikan ID
token Firebase, App Check cukup `dev`, dan Google Play dipalsukan (§11.5). Di Android emulator, host laptop =
`http://10.0.2.2:8080`. Untuk build debug yang menembak stack lokal, ID token Firebase sungguhan tidak
dikenali — pakai token dev lewat konfigurasi build (`--dart-define`).

Status produksi: API live, database kosong, **billing Google Play belum aktif** (`/v1/billing/verify` &
`/restore` → 503) sampai Play Console & Pub/Sub disiapkan.

## 2. Setiap request

| Header | Isi | Kapan |
|---|---|---|
| `Authorization` | `Bearer <ID token>` dari `FirebaseAuth.instance.currentUser!.getIdToken()` | semua kecuali `/v1/config`, `/v1/content/*`, `/v1/waitlist` |
| `X-Firebase-AppCheck` | `FirebaseAppCheck.instance.getToken()` | semua `/v1/*` kecuali `/v1/waitlist`; **limited-use** (`getLimitedUseToken()`, satu token per request) untuk `POST /v1/billing/verify`, `DELETE /v1/me`, `POST /v1/me/journal-pin-backup/verify` |
| `Idempotency-Key` | UUID v4 (`const Uuid().v4()`, paket `uuid` sudah ada) | semua `POST/PUT/PATCH/DELETE` yang mengubah data, kecuali `DELETE /v1/me` dan verifikasi PIN; tanpa key → `400` |
| `X-App-Version` | versi app (`1.0.0+1` dari `pubspec.yaml`) | semua — app di bawah `minAppVersion` dijawab `426` |
| `X-Platform` | `android` | semua |
| `Content-Type` | `application/json` | request ber-body |

**Idempotency-Key** — satu UUID baru per **aksi pengguna**, dibuat sekali lalu dipakai ulang untuk setiap
percobaan ulang aksi itu:
- Gagal jaringan, `5xx`, `401` (setelah token diperbarui), `426`, `429`, atau `409 request_in_progress`
  → ulangi dengan **key yang sama**. Jawaban ini tidak disimpan server, dan aksi yang sudah sukses tidak
  akan dijalankan dua kali.
- `4xx` lain dari endpoint (mis. `insufficient_coins`, `price_changed`, `limit_reached`) **disimpan**: kirim
  ulang dengan key sama → jawaban yang sama persis. Aksi berikutnya (setelah user latihan/ganti pilihan)
  memakai key baru.
- Body berbeda dengan key yang sama → `409 idempotency_key_reuse` (bug di app).

Waktu dikirim RFC 3339 UTC: `DateTime.now().toUtc().toIso8601String()`. Tanggal kalender (`date`) =
tanggal lokal user dalam zona waktu `users.tz` (default `Asia/Jakarta`). App sekarang memakai WIB
(`tz.getLocation('Asia/Jakarta')` di notifikasi); bila user di WITA/WIT, ambil nama zona IANA HP (mis. paket
`flutter_timezone`) dan kirim sekali lewat `PATCH /v1/me/profile` `{ "tz": "Asia/Makassar" }`.

## 3. Klien HTTP di Flutter

App belum punya paket HTTP dan App Check. Tambahkan `http` dan `firebase_app_check` (aktifkan provider
Play Integrity; debug provider untuk emulator). Semua contoh Dart di panduan ini lolos `flutter analyze`
(Flutter 3.44.0; `firebase_auth` 6.7.0, `firebase_app_check` 0.4.8, `http` 1.6.0, `uuid` 4.6.0,
`in_app_purchase` 3.3.1, `in_app_purchase_android` 0.5.3 — versi yang sama dengan `pubspec.lock` app). Satu `ApiClient` membungkus semua aturan §2; UI tidak
pernah menyentuh JSON mentah — service typed mengubahnya jadi model (`CLAUDE.md` aturan model).

```dart
class ApiException implements Exception {
  ApiException(this.status, this.code, this.message, this.requestId, this.details);
  final int status;
  final String code;          // dipetakan ke file strings app (aturan #2)
  final String message;       // hanya untuk log
  final String? requestId;    // tampilkan "Kode: …" + kirim ke Crashlytics
  final Map<String, dynamic> details;
}

class ApiClient {
  ApiClient({required this.baseUrl, required this.appVersion, http.Client? client})
      : _http = client ?? http.Client();
  final Uri baseUrl;
  final String appVersion;
  final http.Client _http;

  /// [idempotencyKey]: buat sekali per aksi (Uuid().v4()) dan pakai lagi saat mengulang aksi yang sama.
  Future<Map<String, dynamic>> send(String method, String path,
      {Object? body, String? idempotencyKey, bool limitedUseAppCheck = false, bool auth = true}) async {
    for (var attempt = 0; ; attempt++) {
      final headers = <String, String>{
        'X-App-Version': appVersion,
        'X-Platform': 'android',
        if (body != null) 'Content-Type': 'application/json',
        if (idempotencyKey != null) 'Idempotency-Key': idempotencyKey,
      };
      final appCheck = limitedUseAppCheck
          ? await FirebaseAppCheck.instance.getLimitedUseToken()
          : await FirebaseAppCheck.instance.getToken(attempt > 0);
      if (appCheck != null) headers['X-Firebase-AppCheck'] = appCheck;
      if (auth) {
        final token = await FirebaseAuth.instance.currentUser?.getIdToken(attempt > 0);
        if (token == null) throw StateError('belum login Firebase');
        headers['Authorization'] = 'Bearer $token';
      }
      final request = http.Request(method, baseUrl.resolve(path))..headers.addAll(headers);
      if (body != null) request.body = jsonEncode(body);
      final response = await http.Response.fromStream(await _http.send(request));

      final json = response.body.isEmpty ? <String, dynamic>{} : jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode < 400) return json;
      final error = (json['error'] as Map?)?.cast<String, dynamic>() ?? const {};
      final code = error['code'] as String? ?? 'unknown';
      // Token login / App Check kedaluwarsa: ambil yang baru, ulangi sekali dengan key yang sama.
      if (response.statusCode == 401 && attempt == 0 && code != 'recent_login_required') continue;
      throw ApiException(response.statusCode, code, error['message'] as String? ?? '',
          error['requestId'] as String?, (error['details'] as Map?)?.cast<String, dynamic>() ?? const {});
    }
  }
}
```

Gagal jaringan (`SocketException`, `TimeoutException`) dan `5xx`/`503`: ulangi dengan backoff dan key yang
sama (§2). Pasang timeout (mis. 15 detik) di pemanggil.

## 4. Error

```json
{ "error": { "code": "insufficient_coins", "message": "not enough coins",
             "requestId": "01M4R9F7Q3EBQ8B8YW7MZ5HG8Q",
             "details": { "balance": 12, "required": 25, "shortfall": 13, "earnedOnly": false } } }
```

`message` hanya untuk debugging. Teks di layar selalu dari file strings app, dipetakan dari `code`
(CLAUDE.md aturan #2), Bahasa Indonesia & Inggris. Tampilkan `requestId` di pesan error ("Kode: …") dan
kirim ke Crashlytics sebagai custom key — dengan itu satu kejadian bisa dilacak sampai log server.

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
| 409 | `limit_reached` | batas harian/etis (`details.reason`, `details.limit`, `details.resetsAt`) |
| 409 | `cooldown` | tunggu `details.retryAfterSeconds` |
| 409 | `ticket_invalid` | tiket Fokus tidak bisa dipakai (`details.reason`) |
| 409 | `purchase_invalid` | Google tidak mengonfirmasi pembelian untuk akun ini (§11) |
| 409 | `pin_locked` | verifikasi PIN dikunci (`details.retryAfterSeconds`) |
| 409 | `idempotency_key_reuse` | key yang sama dipakai untuk body lain — bug di app |
| 409 | `request_in_progress` | request dengan key yang sama masih diproses — tunggu sebentar, ulangi dengan key yang sama |
| 413 / 415 | `payload_too_large` / `unsupported_media_type` | bug di app |
| 426 | `upgrade_required` | layar wajib update (`details.minAppVersion`) |
| 429 | `rate_limited` | tunggu header `Retry-After` (detik) |
| 429 | `signup_limited` | terlalu banyak akun baru dari jaringan ini hari ini; coba lagi besok |
| 500 | `internal` | ulangi nanti dengan key yang sama |
| 503 | `unavailable` | server/Google sedang gangguan; ulangi dengan backoff, key yang sama |

## 5. Alur buka app

```
Firebase sign-in (anonim kalau belum login)
  → GET /v1/config         harga, katalog, batas, kunci tiket Fokus (cache + If-None-Match → 304)
  → GET /v1/me             akun dibuat otomatis di panggilan pertama (termasuk anonim)
  → kirim outbox           POST /v1/activities/batch (event yang tertunda saat offline)
  → billing                InAppPurchase.instance.restorePurchases() → POST /v1/billing/restore (§11)
  → GET /v1/focus/tickets  + ambil tiket free_daily bila online (§9)
```

`GET /v1/me` adalah sumber tunggal state user: profil, `billingAccountId` (Android) / `appAccountToken` (iOS), Premium, streak + jumlah
pelindung, wallet, asesmen, progres monster, inventori + sesi Fokus prabayar, loadout, dan `today`
(`missionsDone`, `freeFocusLeft`, `paidUnlocksUsed`, `fightsToday`, `premiumDailyClaimed`). Semua yang
sekarang disimpan di `LocalPrefsStore` dan bernilai uang pindah ke sini.

Saldo yang ditampilkan = `wallet.coins` (= `earnedCoins` + `purchasedCoins`). Setiap respons yang mengubah
koin membawa `wallet` terbaru — perbarui `WalletNotifier` dari situ, jangan menghitung sendiri.

## 6. Bagian app yang berubah

| Sekarang (`riung/lib/`) | Nanti |
|---|---|
| `WalletFunctionsService` + `HybridWalletFunctionsService` / `LocalWalletFunctionsService` / `FirestoreWalletFunctionsService` (`earnCoins`, `spendCoins`, `dailyCheckin`, `tameProgress`) | service API typed: `postActivity`, `purchase(itemType, itemId, expectedPrice)`, `unlockApp`, `issueFocusTicket` — app tidak pernah mengirim nominal |
| `WalletNotifier`, `StreakNotifier`, `MonsterProgressNotifier` | diisi dari `GET /v1/me` dan dari `wallet` / `result` di setiap respons |
| `LocalPrefsStore` (kosmetik, sesi prabayar, pelindung streak, cadangan koin-beli, klaim harian tahunan, misi) | `GET /v1/me`; prefs hanya untuk hal tampilan |
| `UserRepository` (`LocalUserRepository` / `FirestoreUserRepository`) | `GET /v1/me`, `PATCH /v1/me/profile`, `PUT /v1/me/assessment` |
| `AuthNotifier._linkAndMigrate` | `linkWithCredential` lalu `POST /v1/me/link` — tidak ada lagi salin snapshot |
| `ContentRepository` (`FirestoreContentRepository`) | `GET /v1/content/{kind}` (konten bawaan tetap jadi cadangan) |
| `RemoteConfigService` (harga & batas) | `GET /v1/config`; Remote Config hanya saklar fitur |
| `BillingService._deliver` (mengkredit di HP) | dihapus; verifikasi server (§11) |
| `AppBekuNotifier.unlockMinutes` / `_paidUnlocksToday` | `POST /v1/appbeku/unlocks`; hitungan dari `today.paidUnlocksUsed` |
| `SessionNotifier` (Mode Fokus) | tiket Fokus (§9) |
| `JurnalPinService` (cocokkan hash di HP) | `POST /v1/me/journal-pin-backup/verify` |
| `DataExportBuilder` | ditambah `GET /v1/me/export` |
| `features/home/screens/sesi_selesai_screen.dart` (progres selalu `waswas`) | kirim monster yang sedang dijinakkan sebagai `saboteurId` |

## 7. Akun

| Aksi | Endpoint | Catatan |
|---|---|---|
| Profil | `PATCH /v1/me/profile` | `displayName` (≤ 40 karakter), `avatarId` (`av1`–`av6`), `locale` (`id`/`en`), `persona` (`pelajar`/`mahasiswa`/`pekerja`/`lainnya`), `onboardingDone`, `tz` (IANA); kirim hanya field yang berubah |
| Hasil asesmen ringkas | `PUT /v1/me/assessment` | `dominantSaboteurs` (1–7 id saboteur), `scores` (id saboteur → 0–100), `completedAt`. Jawaban & hasil detail **tetap di HP** |
| Anonim → email/Google | `POST /v1/me/link` | setelah `linkWithCredential` di Firebase (uid sama, tanpa body); semua data anonim ikut |
| Hapus akun | `DELETE /v1/me` | `204`; akun permanen harus login ≤ 5 menit (`recent_login_required`); server ikut menghapus user Firebase. Aman diulang; kalau jawaban pertama hilang dan ulangan dijawab `401`, akun sudah terhapus — lanjutkan logout. Bila `premium.autoRenewing` = true (masih ditagih), tampilkan peringatan dengan tombol ke `https://play.google.com/store/account/subscriptions?sku=<plan>&package=com.riung.riung` (iOS: `https://apps.apple.com/account/subscriptions`) sebelum tombol hapus — langganan tidak ikut terhapus dan tidak bisa dipindah ke akun baru |
| Unduh data server | `GET /v1/me/export` | melengkapi `DataExportBuilder` lokal |
| Backup PIN jurnal | `PUT/GET/DELETE /v1/me/journal-pin-backup`, `POST …/verify` | akun permanen; hash PIN dihitung di HP (`hash` 16–256, `salt` 8–256 karakter base64/hex). `GET` hanya mengembalikan `salt`; verifikasi → `{match, attemptsLeft}`, terkunci 1 jam setelah 10 gagal/hari |

Pembelian dengan uang hanya untuk akun permanen (supaya tidak hilang kalau app dihapus). Akun anonim yang
tidak dibuka 90 hari dihapus otomatis.

**Logout / ganti akun di HP yang sama**: data lokal (jurnal, check-in, kunci enkripsi jurnal, PIN, prefs,
tiket Fokus, outbox) milik akun yang keluar. Sebelum akun lain masuk, kirim sisa outbox bila online, lalu
hapus data lokal — atau simpan semuanya per `uid` (kolom `user_id` / kunci secure storage ber-prefix uid).
Data di server aman: semua endpoint memakai akun dari token.

## 8. Latihan, koin & outbox

Satu endpoint untuk semua kejadian: `POST /v1/activities` (satu) atau `POST /v1/activities/batch`
(`{"events": [...]}`, ≤ 50, hasil per event). App **tidak pernah mengirim nominal koin**.

| `type` | Field | Server memberi | Kunci (dihitung sekali) |
|---|---|---|---|
| `checkin` | `date` | +5; streak; bonus 7 hari +20 / 30 hari +100; pelindung streak dipakai otomatis bila tepat 1 hari bolong | `date` |
| `journal_saved` | `entryId`, `promptId?` (atau `promptMonsterId?`) | +4, +2 progres ke monster prompt; gratis 1 entri/hari | `entryId` |
| `meditation_completed` | `sessionId` (id katalog, mis. `napas_4_7_8`) | +3, +3 progres ke monster target (dari katalog); sesi Premium perlu Premium | `sessionId` + tanggal |
| `betterme_lesson_completed` | `lessonId` (mis. `l1_s1`) | +10 sekali per lesson; level ≥ 2 perlu Premium, berurutan | `lessonId` |
| `mission_completed` | `date`, `index` (0–2) | +3, maks 3 misi/hari | `date` + `index` |
| `minigame_finished` | `ref` (UUID), `saboteurId`, `won` | +8 bila menang; +5/+2 progres; maks 4 pertarungan/hari | `ref` |
| `focus_completed` | `ticketId`, `saboteurId` | +4 progres; tiket dipakai sekali (§9) | `ticketId` |

Semua event wajib `occurredAt` (kapan terjadi di HP, maks 7 hari ke belakang, maks 5 menit ke depan).
`date` = tanggal lokal `occurredAt`. Monster yang mencapai 100 jinak dan memberi +50 sekali.

**Kunci di kolom kanan menentukan "event yang sama".** Event dengan kunci yang sudah pernah diproses
dijawab dengan hasil lamanya (`replayed: true`) dan tidak memberi koin lagi. Karena itu `entryId` (id entri
jurnal), `ref` (UUID per pertarungan minigame), dan `ticketId` dibuat **sekali saat kejadian** dan ikut
disimpan bersama event — jangan dibuat ulang saat mengirim.

**Isi tidak pernah dikirim**: teks jurnal, mood/faktor/catatan check-in, refleksi Better Me, hasil Kenali
Dirimu, data tidur, daftar & pemakaian aplikasi yang dibekukan, afirmasi buatan, apa pun dari layar krisis.

**Batas harian bukan error.** Event di atas batas dijawab `200` dengan `coinsGranted: 0`, `capped: true`,
`capReason` (`daily_cap`, `free_daily_limit`, `premium_required`, `locked`). Tetap rayakan latihannya; beri
keterangan ramah, bukan pesan gagal.

**Outbox offline** — wajib karena latihan sering dilakukan tanpa internet:
- Tabel baru di database `sqflite` app (naikkan versi DB dari 1 ke 2): `outbox(id, body_json, created_at,
  attempts)`, `body_json` = event lengkap dengan `occurredAt` dan kuncinya.
- Kirim saat online (app dibuka, `connectivity_plus` tersambung) lewat `/batch`, urut waktu, ≤ 50 per
  kiriman. **Setiap kiriman batch memakai `Idempotency-Key` baru** — isi outbox bisa berubah di antara
  percobaan, dan pengulangan event sudah dicegah oleh kunci per event di atas.
- Per hasil: `ok` → hapus dari outbox; `error` (`invalid_request`, `ticket_invalid`) → hapus dan catat
  (mengulang tidak akan berhasil). Seluruh batch dijawab `5xx` atau gagal jaringan → simpan, coba lagi nanti.
- Saldo di layar = angka terakhir dari server + penanda "menunggu sinkron" bila outbox belum kosong.

## 9. Mode Fokus — tiket offline

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
2. Simpan tiket di `flutter_secure_storage` (sudah ada). Boleh dicek keasliannya: `sig` = Ed25519
   (base64url) atas `riung-focus-ticket.v1|<kid>|<id>|<userId>|<source>|<durationMin>|<issuedAt>|<expiresAt>`
   dengan kunci publik `focusTicketKeys` dari `/v1/config` (cocokkan `kid`).
3. Sesi selesai → event `focus_completed` `{ticketId, saboteurId, occurredAt}` lewat outbox. Server menolak
   (`ticket_invalid`) bila: tiket bukan milik user (`not_found`), sudah dipakai (`used`), "selesai" sebelum
   durasinya lewat (`too_early`), dimulai setelah tiket kedaluwarsa (`expired`), atau waktunya bertumpuk
   dengan sesi lain yang sudah dilaporkan (`overlap`).
4. `GET /v1/focus/tickets` → tiket yang belum dipakai (untuk HP baru / setelah reinstall).

## 10. Toko, loadout, Aplikasi Beku

**Belanja koin** — `POST /v1/shop/purchase` `{itemType, itemId, expectedPrice}`:

| `itemType` | `itemId` |
|---|---|
| `cosmetic` | id inventori: kosmetik monster (`topi_rajut`), aksesori `acc_<id>`, gaya kartu `cardstyle_<id>` |
| `cosmetic_bundle` | id bundel aksesori (harga = 80% item yang belum dimiliki, dibulatkan ke 5) |
| `streak_shield` | `streak_shield` |
| `focus_pack` | `focus_1`, `focus_5` |

Harga **selalu** dari `/v1/config` → `catalog` (sudah dihitung server); `expectedPrice` hanya deteksi
perubahan. Koin beli dipakai lebih dulu, lalu koin latihan. Kepemilikan kosmetik global.

**Loadout** — `PUT /v1/loadouts/monsters/{saboteurId}` `{items: [...]}` (≤ 5), `PUT /v1/loadouts/characters/{testId}`
`{accessories: [...], cardStyle}` (≤ 4 aksesori). Item harus dimiliki, satu per slot, item eksklusif hanya untuk
karakternya. Gaya kartu berbayar boleh dipakai tanpa dibeli selama Premium aktif.

**Aplikasi Beku** — `POST /v1/appbeku/unlocks`:

```
satuan : {"appId":"com.instagram.android","minutes":10,"expectedPrice":15}
bundel : {"bundleId":"santai","expectedPrice":35}
         {"bundleId":"sosmed","appIds":["com.instagram.android","com.google.android.youtube"],"expectedPrice":75}
→ {"result":{"target":"unit","grants":[{"appId":"com.instagram.android","minutes":10}],"price":15,
             "paidUnlocksUsed":1,"paidUnlocksLeft":2,"cooldownUntil":"…"},"wallet":{…}}
```

- `appId` = `packageName` dari `AppBekuCatalog` (`core/config/appbeku_catalog.dart`; WhatsApp tidak bisa).
  Menit dan bundel dari `/v1/config` → `catalog.appbeku`.
- `expectedPrice` = harga dasar + 10 × `today.paidUnlocksUsed` (ke-1: dasar, ke-2: +10, ke-3: +20) — sama dengan
  `effectiveUnlockPrice` yang ada sekarang.
- Pengaman etis ditegakkan server: maks 3 buka-berbayar/hari (`limit_reached`), jeda 60 detik antar buka
  berbayar — juga dari Toko, bukan hanya interstisial (`cooldown`), **hanya koin latihan**
  (`insufficient_coins` dengan `earnedOnly: true`). Bundel dipotong sekali dan dihitung satu buka (ganti
  dua langkah `unlockMinutes` di `appbeku_toko_section.dart` dengan satu request bundel).
- Buka menit secara lokal sesuai `grants`. Jalur napas gratis tetap lokal dan tidak pernah dibatasi.

**Koin harian Premium tahunan** — `POST /v1/premium/daily-coins` (akun permanen, 1×/hari, +2 ke koin beli).

**Akses jurnal** — `GET /v1/journal/access?promptId=` → `canWrite`, `reason` (`daily_limit`,
`premium_required`), status tiap prompt. Saat offline pakai hitungan lokal sebagai cadangan.

## 11. Pembelian Google Play (`in_app_purchase`)

### 11.1 Membeli
- Hanya akun permanen (anonim → `403 permanent_account_required`). Ambil `billingAccountId` dari `GET /v1/me`.
- Produk (sama dengan `BillingService` sekarang): koin `coin_pack_small|medium|large` (80 / 330 / 820 koin),
  langganan `premium_monthly|premium_yearly`.
- **Paket koin wajib `autoConsume: false`.** Default `in_app_purchase` di Android langsung meng-*consume*
  pembelian sebelum app sempat memverifikasinya ke server; kalau app mati sebelum `verify`, pembelian itu
  tidak muncul lagi di `restorePurchases()` dan koinnya hilang.

```dart
final param = PurchaseParam(productDetails: product, applicationUserName: me.billingAccountId);
await InAppPurchase.instance.buyConsumable(purchaseParam: param, autoConsume: false); // paket koin
await InAppPurchase.instance.buyNonConsumable(purchaseParam: param);                  // Premium
```

`applicationUserName` dikirim ke Play sebagai `obfuscatedAccountId`; server menolak pembelian yang tidak
membawanya (`purchase_invalid`).

### 11.2 Memproses `purchaseStream`

```dart
Future<void> _onPurchase(PurchaseDetails p) async {
  if (p.status == PurchaseStatus.pending) return;                  // bayar tunai dsb. — tunggu update berikutnya
  if (p.status != PurchaseStatus.purchased && p.status != PurchaseStatus.restored) return;
  final r = await billingApi.verify(                               // POST /v1/billing/verify, App Check limited-use
    productId: p.productID,
    purchaseToken: p.verificationData.serverVerificationData,
    idempotencyKey: const Uuid().v4(),                             // aman baru tiap panggilan (lihat di bawah)
  );
  switch (r.status) {
    case 'credited' || 'already_credited':                         // paket koin: consume = acknowledge
      await InAppPurchase.instance
          .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>()
          .consumePurchase(p);
    case 'active' || 'inactive':                                   // langganan
      if (p.pendingCompletePurchase) await InAppPurchase.instance.completePurchase(p);
    case 'pending':
      break;                                                       // jangan consume/complete
  }
  wallet.update(r.wallet); premium.update(r.premium);              // jangan mengkredit sendiri
}
```

- `verify`/`restore` boleh memakai `Idempotency-Key` baru setiap panggilan: satu `purchaseToken` hanya pernah
  dikreditkan sekali oleh server (jawaban berikutnya `already_credited`), berapa kali pun dikirim.
- `409 purchase_invalid` → jangan consume/complete; tampilkan pesan. Google me-refund otomatis setelah 3 hari.
- `503`/gagal jaringan → jangan apa-apa; pembelian tetap ada di Play dan muncul lagi lewat `restorePurchases()`.
- Impor `package:in_app_purchase_android/in_app_purchase_android.dart` (tambahkan ke `pubspec.yaml`) untuk
  `InAppPurchaseAndroidPlatformAddition`.
- **Satu langganan = beberapa `ProductDetails`.** `queryProductDetails` mengembalikan satu
  `GooglePlayProductDetails` per *offer* (trial, base plan) dengan `id` sama; `price` = fase harga pertama
  offer itu (trial → "Gratis"). Jangan simpan di map berkunci `id`. Pilih offer dengan sengaja lewat
  `productDetails.subscriptionOfferDetails[subscriptionIndex]` (`offerId`/`basePlanId`, `pricingPhases`):
  tampilkan harga dari fase berbayar dan lama trial dari fase gratis (bukan Remote Config), lalu beli
  `ProductDetails` offer yang dipilih.
- **Upgrade/downgrade** bulanan ↔ tahunan: `GooglePlayPurchaseParam(productDetails: …, applicationUserName: …,
  changeSubscriptionParam: ChangeSubscriptionParam(oldPurchaseDetails: langgananAktif, replacementMode: …))`.
  Tanpa ini Play membuat langganan kedua dan user tertagih dua kali. Server memindahkan Premium ke token baru.
- **Harga** selalu `ProductDetails.price` (sudah dalam mata uang negara user dari Play); angka IDR di
  `economy.dart`/Remote Config hanya cadangan saat Play tidak bisa dihubungi. Analytics pembelian memakai
  `rawPrice` + `currencyCode`, bukan konstanta IDR.

### 11.3 Restore & status
- Saat app dibuka/login: `InAppPurchase.instance.restorePurchases()` → pembelian yang belum di-*consume*
  dan langganan aktif datang lewat `purchaseStream` dengan status `restored`. Kirim sekaligus ke
  `POST /v1/billing/restore` `{purchases: [{productId, purchaseToken}]}` (≤ 20, hasil per item), lalu
  consume/complete per item dengan aturan §11.2. Setiap baris hasil membawa `purchaseToken` — cocokkan
  `PurchaseDetails` dengan token itu, jangan dengan urutan baris. Token yang sudah dikreditkan tidak
  dikreditkan ulang.
- `GET /v1/billing/subscription` / `GET /v1/me` → `premium.status`: aktif bila `active` atau `in_grace`.
  Membatalkan perpanjangan (auto-renew mati) tetap Premium sampai `expiresAt`.

### 11.4 Refund
Refund dari Google menarik kembali koinnya. Kalau koinnya sudah terpakai, sisanya jadi `debtCoins`
(`GET /v1/wallet`) yang dilunasi dari koin berikutnya — saldo tidak pernah minus.

### 11.5 Uji lokal tanpa Play
Stack dev memakai Google Play palsu: token `dev-coin:<billingAccountId>:<productId>:<n>` dan
`dev-sub:<billingAccountId>:<productId>:<hari>:<n>` (Postman folder *6. Google Play billing*).

### 11.6 App Store (iOS) — server siap, aktif setelah App Store Connect disiapkan
Server sudah punya jalur iOS (spec §3.9b) tapi **mati** sampai kredensial App Store diisi (runbook 4d);
sebelum itu `POST /v1/billing/appstore/*` menjawab `503`. Bedanya dengan Android:

| | Android | iOS |
|---|---|---|
| `applicationUserName` | `me.billingAccountId` | `me.appAccountToken` (UUID → StoreKit `appAccountToken`) |
| Verifikasi | `POST /v1/billing/verify` `{productId, purchaseToken}` | `POST /v1/billing/appstore/verify` `{productId, transactionId}` |
| Nilai yang dikirim | `verificationData.serverVerificationData` | `PurchaseDetails.purchaseID` (id transaksi StoreKit) |
| Restore | `/v1/billing/restore`, cocokkan `purchaseToken` | `/v1/billing/appstore/restore`, cocokkan `transactionId` |
| Paket koin | `buyConsumable(autoConsume: false)` + `consumePurchase` | `buyConsumable(...)` **tanpa** `autoConsume: false` (plugin iOS menolaknya); koin baru "terpakai" saat `completePurchase` |
| Selesaikan | consume / `completePurchase` | `completePurchase` (= `finish()`) untuk `credited`, `already_credited`, `active`, `inactive` |
| Upgrade bulanan ↔ tahunan | `ChangeSubscriptionParam` | beli plan lain biasa — App Store mengganti dalam satu *subscription group* tanpa tagihan ganda |
| Kelola langganan (hapus akun) | `play.google.com/store/account/subscriptions?…` | `https://apps.apple.com/account/subscriptions` |

```dart
final param = PurchaseParam(
  productDetails: product,
  applicationUserName: Platform.isIOS ? me.appAccountToken : me.billingAccountId,
);
// iOS
final r = await billingApi.verifyAppStore(productId: p.productID, transactionId: p.purchaseID!);
if (const {'credited', 'already_credited', 'active', 'inactive'}.contains(r.status) && p.pendingCompletePurchase) {
  await InAppPurchase.instance.completePurchase(p);
}
```

- `409 purchase_invalid` → **jangan** `completePurchase`: transaksi milik akun Riung lain di Apple ID yang sama
  tetap tertunda dan terkredit saat akun pemiliknya login lagi. StoreKit mengirim ulang transaksi yang belum
  selesai setiap app dibuka — cukup verifikasi lagi.
- Produk di App Store Connect memakai id yang sama (`coin_pack_*` consumable, `premium_monthly|yearly`
  auto-renewable dalam **satu** subscription group, trial 7 hari sebagai *introductory offer*). Harga dan lama
  trial dibaca dari `ProductDetails`, seperti Android.
- Login **Sign in with Apple** (`apple.com`) diterima server seperti Google; App Check iOS memakai App Attest
  (fallback DeviceCheck), tetap dengan `getLimitedUseToken` untuk endpoint sensitif.
- Uji lokal: `transactionId` palsu `dev-coin:<appAccountToken>:<productId>:<n>` dan
  `dev-sub:<appAccountToken>:<productId>:<hari>:<n>` (Postman folder *6b. App Store billing*). Uji sungguhan:
  akun sandbox App Store Connect / TestFlight (server menandai `result.test = true`).

## 12. Rate limit yang perlu diperhatikan

Batas per user (sisanya di spec §5): `GET /v1/me` & `/v1/wallet` 60/menit, `POST /v1/activities` 60/menit,
`/batch` 10/menit, belanja & Aplikasi Beku 10/menit, tiket Fokus 20/menit, `billing/verify` 10/menit & 30/jam,
`billing/restore` 5/jam (Play dan App Store berbagi batas), `/me/link` 5/jam, hapus/ekspor akun 3/jam. Jangan polling — `/v1/me` saat app dibuka
dan setelah aksi penting sudah cukup.

## 13. Mencoba lokal

Cara tercepat: **Postman collection** di `backend/postman/` (55 request, environment lokal & produksi,
header dan Idempotency-Key otomatis) — lihat `backend/postman/README.md`. Atau dengan curl:

```sh
cd backend && make dev-up
docker compose -f deploy/docker-compose.yml exec -T api /riung seed-content - < ../docs/dummy-data-seed.json
curl localhost:8080/v1/me -H 'Authorization: Bearer dev:rani:anonymous' -H 'X-Firebase-AppCheck: dev'
curl -X POST localhost:8080/v1/activities -H 'Authorization: Bearer dev:rani:anonymous' \
  -H 'X-Firebase-AppCheck: dev' -H 'Content-Type: application/json' -H "Idempotency-Key: $(uuidgen)" \
  -d "{\"type\":\"checkin\",\"occurredAt\":\"$(date -u +%FT%TZ)\",\"date\":\"$(TZ=Asia/Jakarta date +%F)\"}"
```

## 14. Daftar kerja app (ringkas)

Detail & prioritas: `docs/todo-luar-backend.md` §B–C.

- [ ] Paket baru: `http` (^1.6.0), `firebase_app_check` (^0.4.8), `in_app_purchase_android` (0.5.3, impor langsung); opsional `flutter_timezone`
- [ ] `ApiClient` (§3): header §2, refresh token, retry dengan key yang sama, pemetaan `code` → strings, `requestId`
- [ ] Model Dart typed untuk request/response (aturan model di `CLAUDE.md`), tanpa `Map` mentah di UI
- [ ] Bootstrap dari `GET /v1/me`; harga & katalog dari `/v1/config` (cache + fallback `economy.dart`)
- [ ] Outbox `sqflite` + `/v1/activities/batch` (§8); hapus mutasi koin di HP (§6, `firestore.rules`)
- [ ] Toko, loadout, Aplikasi Beku, tiket Fokus lewat server (§9–10)
- [ ] `BillingService`: `autoConsume: false`, verifikasi server, consume/complete setelah sukses, restore (§11)
- [ ] iOS (saat rilis iOS dijadwalkan): `appAccountToken`, `/v1/billing/appstore/*`, `completePurchase` setelah server (§11.6)
- [ ] App Check (Play Integrity) + `getLimitedUseToken` untuk 3 endpoint sensitif
- [ ] Teks untuk semua `code` di §4 (Bahasa Indonesia & Inggris)
- [ ] Tes parity: `economy.dart` == `docs/economy-props.json`, katalog app == `docs/catalog.json`
