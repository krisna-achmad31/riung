# Setup Firebase & Play Billing (M5 — Spark plan)

Panduan operasional buat nyalain backend Riung sungguhan di Firebase Console
& Google Play Console. Ini BUKAN dokumen arsitektur (itu di
`firebase-architecture.md`, yang menggambarkan versi ideal Blaze-plan
dengan Cloud Functions) — ini langkah konkret yang perlu dijalankan supaya
implementasi M5 (Spark plan, tanpa Cloud Functions) benar-benar hidup.

## 0. Kenapa Spark plan, dan apa konsekuensinya

Proyek ini jalan di Firebase **Spark plan** (gratis) — artinya **tidak ada
Cloud Functions**. `firebase-architecture.md` §5 mengasumsikan semua
mutasi koin & verifikasi pembelian lewat Cloud Functions; itu tidak bisa
dijalankan di sini.

Sebagai gantinya:

- **Wallet** dimutasi langsung dari client lewat `FirestoreWalletFunctionsService`
  (`lib/core/services/firebase/firestore_wallet_functions_service.dart`),
  tapi `firestore.rules` di root proyek memvalidasi setiap perubahan
  `wallet.coins` harus salah satu nilai earn/spend yang sah (delta
  allowlist, lihat `isValidWalletDelta()`).
- **Pembelian Play Billing** tidak diverifikasi ulang ke Google Play
  Developer API di server — `BillingService` percaya status `purchased`
  dari Play Billing Library on-device (lihat catatan keamanan di
  `lib/core/services/billing_service.dart`).

**Ini cukup untuk pengembangan & rilis awal**, tapi client yang dimodifikasi
(rooted device, dsb) secara teori masih bisa memutar ulang permintaan yang
"bentuknya sah". Kalau nanti upgrade ke Blaze plan, ganti pola ini dengan
Cloud Functions callable yang memproses `coinRequests` & memverifikasi
receipt ke Play Developer API, lalu pangkas `allow update` langsung ke
wallet di `firestore.rules`.

## 1. Project Firebase

1. Buka [Firebase Console](https://console.firebase.google.com) → buat/pakai project (proyek ini pakai `riung-5e979`).
2. **Tambah Android app** dengan package name **persis** `com.riung.riung`
   (harus sama dengan `applicationId` di `android/app/build.gradle.kts` —
   jangan pernah diubah, lihat catatan di file itu).
3. Download `google-services.json`, taruh di `android/app/google-services.json`.
   File ini **tidak boleh di-commit** kalau repo publik (sudah di
   `.gitignore` kalau ada) — tiap developer/CI perlu salinannya sendiri.
4. Kalau project Firebase-nya juga dipakai app lain dengan package name
   beda (mis. `com.riung.app` dari percobaan awal), boleh biarkan kedua
   Android app terdaftar — Google Services Gradle plugin otomatis
   mencocokkan `client` yang benar berdasarkan `applicationId` saat build.

## 2. Authentication

Firebase Console → **Authentication → Sign-in method**, aktifkan:

- **Anonymous** — wajib, ini yang dipakai `AuthNotifier` untuk sesi
  pra-signup (onboarding jalan sebelum user daftar). Kalau lupa langkah
  ini, app akan tampak macet di Splash tanpa pesan apa pun — sekarang
  sudah ada UI error + tombol "Coba lagi" di Splash, tapi cek `adb logcat`
  buat pesan pastinya kalau masih macet:
  `[firebase_auth/admin-restricted-operation] This operation is restricted
  to administrators only.` = provider Anonymous belum diaktifkan.
- **Email/Password** — dipakai `daftar_screen.dart` / `masuk_screen.dart`.
- **Google** — dipakai tombol "Lanjutkan dengan Google". Perlu SHA-1 (dan
  SHA-256 buat App Bundle) dari keystore debug & release ditambahkan di
  **Project settings → Your apps → Android app**, supaya
  `google_sign_in` bisa dapat token yang valid:
  ```bash
  keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
  ```
  Setelah SHA-1/SHA-256 ditambahkan DAN provider Google diaktifkan,
  download ulang `google-services.json` — array `oauth_client` di
  dalamnya akan terisi (sebelumnya `[]`). `google_sign_in` v7+ butuh
  `serverClientId` eksplisit di Android (tidak lagi otomatis dari
  `google-services.json`): buka file itu, cari entri `oauth_client`
  dengan `"client_type": 3` ("Web client", bukan yang `client_type: 1`),
  salin `client_id`-nya ke `googleServerClientId` di
  `lib/core/config/firebase_config.dart`. Sampai diisi, tombol "Lanjutkan
  dengan Google" akan menampilkan pesan error yang jelas alih-alih diam-diam
  gagal.

  **Fingerprint di atas dari keystore debug** — build rilis nanti pakai
  keystore lain (beda SHA), butuh langkah tambahan supaya Google
  Sign-In tidak patah khusus di rilis. Lihat `docs/release-signing.md`
  § Langkah 7.

## 3. Firestore

1. Firebase Console → **Firestore Database → Create database**.
2. Region: **asia-southeast2 (Jakarta)** — latensi terbaik buat pengguna
   Indonesia, dan tidak bisa diganti setelah dibuat.
3. Mode awal: **test mode** boleh buat coba-coba lokal, tapi **sebelum
   rilis** rules sungguhan (§4 di bawah) HARUS di-deploy — test mode
   default-nya `allow read, write: if true` yang membuka saldo koin siapa
   pun buat ditulis siapa pun.
4. Client sudah pakai persistence offline (`Settings(persistenceEnabled: true)`
   di `main.dart`) — data tetap kebaca saat offline, sinkron lagi saat
   online.

## 4. Deploy Security Rules

Rules-nya sudah ditulis di `firestore.rules` (root proyek). Deploy dengan
[Firebase CLI](https://firebase.google.com/docs/cli):

```bash
npm install -g firebase-tools
firebase login
firebase init firestore   # pilih project yang sudah ada, pakai firestore.rules yang sudah ada
firebase deploy --only firestore:rules
```

Baca komentar di `firestore.rules` sebelum ubah apa pun — daftar
`isValidWalletDelta()` (angka earn/spend yang sah) HARUS tetap sinkron
manual dengan `lib/core/config/economy.dart`. Kalau nambah reward/harga
baru di `economy.dart`, tambahkan juga nilainya di sini lalu deploy ulang.

## 5. Isi konten (`/content`)

`FirestoreContentRepository` baca `/content/saboteurs` dan
`/content/affirmations` (satu dokumen per jenis, field `items` berupa
array). Isi manual lewat Firestore Console kalau mau konten live beda dari
`assets/data/dummy-data-seed.json` (fallback bawaan kalau dokumennya kosong
atau lagi offline) — tidak wajib buat build jalan, cuma buat konten yang
bisa diubah tanpa rilis ulang app.

## 6. Remote Config

1. Firebase Console → **Remote Config → Create configuration**.
2. Tambahkan key yang SAMA PERSIS dengan `assets/remote_config_defaults.json`
   (nama key & tipe `number`) — file itu jadi default lokal kalau fetch
   gagal/offline, jadi app tidak akan pernah tampil kosong meski Console
   belum diisi.
3. Publish. Client fetch ulang maks tiap 1 jam
   (`RemoteConfigService`, `minimumFetchInterval`).

## 7. Google Play Billing — 5 SKU

Buka [Play Console](https://play.google.com/console) → app Riung → **Monetize → Products**.

| Jenis | Product ID | Isi |
|---|---|---|
| In-app product (consumable) | `coin_pack_small` | 80 koin — Rp15.000 |
| In-app product (consumable) | `coin_pack_medium` | 330 koin (300+30 bonus) — Rp49.000 |
| In-app product (consumable) | `coin_pack_large` | 820 koin (700+120 bonus) — Rp99.000 |
| Subscription | `premium_monthly` | Riung Premium bulanan — Rp59.000/bln |
| Subscription | `premium_yearly` | Riung Premium tahunan — Rp590.000/thn (bayar 10 bulan), trial 7 hari |

Product ID ini HARUS sama persis dengan `CoinPackSku`/`PremiumSku` di
`lib/core/services/billing_service.dart`. Untuk kedua subscription,
tambahkan **base plan + offer trial 7 hari** di Play Console (trial
dikonfigurasi di Play Console, bukan di kode — app cuma memicu pembelian,
Play yang menentukan kapan tagihan pertama jalan).

Aplikasi harus sudah punya **release ber-signing** yang di-upload minimal
ke **internal testing track** sebelum SKU bisa dites — Play Billing tidak
jalan untuk APK debug yang di-*sideload* langsung tanpa track apa pun.

## 8. License tester

Play Console → **Setup → License testing** → tambahkan email Google
akun tester (termasuk akun development sendiri). Akun ini bisa "beli" SKU
tanpa kena tagihan sungguhan — dipakai buat uji alur `BillingService` dari
Toko end-to-end (tap beli → sheet Play → `purchaseStream` → koin/Premium
masuk).

## 9. Verifikasi akhir (definition of done M5)

```bash
flutter analyze
flutter test
flutter build apk --debug
```

Semua harus bersih/sukses (info `prefer_initializing_formals` yang sudah
ada sejak awal proyek boleh diabaikan — bukan error). Untuk uji Play
Billing sungguhan, build **release** (perlu signing config) dan upload ke
internal testing track, bukan `--debug`.
