# Integrasi API aplikasi

Branch: `implement_and_integrations_api`, berasal dari `main` lokal.

Kontrak masukan: [panduan integrasi](panduan-integrasi-app.md),
[koleksi Postman](postman/riung-api.postman_collection.json), dan kedua
environment di `docs/postman/`. Konfigurasi publik yang diperiksa tersimpan di
`api-config-snapshot.json`; `catalog.json` dan `economy-props.json` adalah
snapshot server untuk tes parity, bukan konfigurasi kredensial.

## Menjalankan

Produksi adalah default:

```powershell
cd riung
flutter pub get
flutter run
```

Backend lokal dari Android emulator:

```powershell
flutter run --dart-define=RIUNG_API_BASE_URL=http://10.0.2.2:8080 --dart-define=RIUNG_DEV_TOKEN=dev:postman:google.com
```

Token dev hanya dibaca pada build debug. Build release selalu menggunakan ID
token Firebase. `RIUNG_API_BASE_URL` adalah origin, tanpa suffix `/v1`.
App Check menggunakan debug provider saat debug dan Play Integrity saat release.
Daftarkan token debug App Check dan konfigurasi Play Integrity di Firebase.

Untuk HP fisik, gunakan `adb reverse tcp:8080 tcp:8080` lalu base URL
`http://localhost:8080`. HTTP lokal diizinkan hanya di manifest debug;
konfigurasi release tetap HTTPS.

### Build Android dan Google Sign-In

`google_sign_in_android` dipatok ke 7.2.11 karena versi 7.2.12+ memakai built-in
Kotlin sementara proyek memakai `android.builtInKotlin=false`. Setelah mengganti
versi plugin, jalankan `flutter clean`, `flutter pub get`, lalu build ulang;
cache Kotlin lama dapat kehilangan `ResultUtilsKt` atau kelas plugin Firebase.
Build APK debug dari kondisi bersih sudah berhasil pada lingkungan ini.

## Titik integrasi

| Domain | Implementasi |
| --- | --- |
| HTTP, token refresh, limited-use App Check, retry/idempotency, request ID | `api_client.dart` |
| Semua endpoint publik dan aplikasi dari Postman | `riung_api.dart` |
| Bootstrap dan state pengguna, cache per uid, tiket secure storage | `api_state.dart` |
| Harga dan katalog, ETag / 304, minimum versi | `api_config_store.dart` |
| Profil, asesmen, link, PIN, konten, transaksi, operasi ekonomi | `api_repositories.dart` |
| Latihan offline | sqflite v2 `outbox`, dipisahkan per uid, batch maksimum 50 |
| Google Play | `billing_service.dart`, verify/restore sebelum consume/complete |
| Admin | `RiungAdminApi`, gunakan klien/token terpisah melalui akses admin yang sah |
| Google Play RTDN | `tool/google_play_webhook_client.dart`, hanya backend/dev tooling |
| Waitlist REST | `RiungApi.waitlist`, endpoint publik tanpa Auth/App Check |

Firebase Auth, Analytics, Crashlytics, dan feature flags tetap digunakan.
Layanan Firestore/lokal lama dipertahankan untuk kompatibilitas tes dan injeksi
dependency, tetapi default aplikasi memakai REST, termasuk akun anonim.
Koin dan progres tidak dikreditkan dari nominal yang dikirim client.
Snapshot wallet server tetap ditampilkan ketika offline; pita menandai outbox
yang belum tersinkron. Isi jurnal, mood, refleksi, serta pemakaian aplikasi
tidak masuk outbox.

Operasi uang harus online. Pembelian Google Play memakai billingAccountId,
`autoConsume: false`, dan token receipt; 503, purchase_invalid, atau pending
tidak membuat pembelian di-consume/acknowledge. Restore maksimal 20 item per
request. Tidak ada receipt produksi atau kredensial admin yang dibundel.

## Batas verifikasi dan data backend

- Endpoint config dan konten publik sudah diperiksa secara read-only.
- Endpoint berautentikasi diuji dengan HTTP mock; pengujian end-to-end pada
  perangkat membutuhkan login Firebase/App Check dan backend yang tersedia.
- Menurut panduan backend, billing produksi masih mengembalikan 503 sampai
  Play Console dan Pub/Sub dikonfigurasi.
- Konten publik `meditations`, `sleep_stories`, dan `betterme_lessons` memakai
  ID `med_01`, `slp_01`, `bm_01`, sementara katalog ekonomi memakai ID aplikasi
  seperti `napas_4_7_8` dan `l1_s1`. Endpoint konten ini tersedia dan di-cache,
  tetapi audio serta pelajaran tetap menggunakan konten bawaan yang memiliki
  aset dan ID katalog valid. Backend perlu menyamakan ID dan menyediakan
  metadata/media sebelum katalog konten baru dapat dirender sepenuhnya.
- Admin dan RTDN bukan fitur aplikasi pengguna. Klien terpisah disediakan;
  tidak ada pengujian mutasi pada server produksi.
- Preflight waitlist dari origin Firebase Hosting menghasilkan 204 tanpa
  `Access-Control-Allow-Origin`. Form landing tetap memakai implementasi
  Firestore yang ada sampai backend mengaktifkan CORS untuk origin website.
- Kalender aktivitas mengikuti `profile.tz` server, dengan default
  `Asia/Jakarta`; endpoint patch profil mendukung zona IANA.

## Pengujian

```powershell
flutter test
flutter analyze --no-fatal-infos
flutter build apk --debug
```

Tes tambahan mencakup retry dengan key tetap, refresh token, limited-use
App Check, rute/body endpoint, outbox lintas akun dan replay, tiket sekali pakai
offline, status billing gagal/pending/sukses, serta parity katalog dan ekonomi.
