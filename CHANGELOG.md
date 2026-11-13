# Changelog — Riung

Daftar perubahan yang sudah selesai. Pekerjaan yang masih dibutuhkan ada di [`BACKEND_TASKS.md`](BACKEND_TASKS.md), [`MOBILE_TASKS.md`](MOBILE_TASKS.md), dan [`DESIGN_TASKS.md`](DESIGN_TASKS.md).

Format entri baru (paling baru di atas):

```
DD/MM/YYYY (VERSI)
INISIAL
1. ADD: fitur baru.
2. UPDATE: perubahan pada yang sudah ada.
3. FIX: perbaikan bug.
```

Setiap perubahan yang di-merge wajib menaikkan `version` di [`riung/pubspec.yaml`](riung/pubspec.yaml): PATCH untuk perbaikan, MINOR untuk fitur, dan `+BUILD` selalu naik 1.

======

13/11/2026 (1.2.1+12)
AY
1. UPDATE: Update the Riung design source in design/riung.pen.

13/11/2026 (1.2.0+11)
AY
1. ADD: Back up and restore encrypted journal files without signing in. Warn guests with journal entries before signing in to another account.
2. ADD: Open the sleep reminder schedule from Notifications and enter a bedtime directly. Adjust the time in five-minute steps with the plus and minus buttons.
3. UPDATE: Open Sign In from the Email setting and use the official Google logo on authentication buttons.
4. UPDATE: Align the Affirmations header with the other Explore tabs and improve spacing in the journal banner.
5. FIX: Share and save affirmation cards on a 9:16 canvas with margins to reduce cropping in Stories.
6. FIX: Hide back buttons in Explore tabs, synchronize the sleep reminder toggle, and use a consistent progress subtitle across monster tabs.

01/11/2026 (1.1.0+10)
AY
1. ADD: Add App Store purchases for Premium and coin packs, with restore, trial eligibility and recovery of unfinished transactions.
2. ADD: Add the Sign in with Apple button, hidden until Firebase and OAuth setup is done.
3. UPDATE: Show App Store links and store names on iOS.
4. UPDATE: Disable yearly daily coin claims during the trial.
5. FIX: Read the wrapped verify response so purchases no longer stay pending.
6. FIX: Fix the App Check limited-use token error that blocked purchase verification.
7. FIX: Stop showing technical error toasts at launch before sign-in.
8. FIX: Show the other-account message when a subscription belongs to another Riung account.

01/11/2026 (1.0.5+9)
AY
1. ADD: Add six 3D portrait avatars to the profile, replacing monster avatars.
2. UPDATE: Replace the app icon on Android and iOS with Si Hakim inside the glass circle.

01/11/2026 (1.0.4+8)
AY
1. ADD: Add AppData for LIVE and DEV modes. Release builds always use LIVE.
2. ADD: Add BACKEND_TASKS.md, MOBILE_TASKS.md and DESIGN_TASKS.md as shared task lists.
3. ADD: Add App Store billing code from billing_v1.
4. ADD: Require Premium for Know Yourself tests and quizzes, with lock labels before starting.
5. UPDATE: Block screenshots on the data export screen on Android.
6. UPDATE: Remove billing identifiers from data exports.
7. ADD: Show crisis services by country, with search and an emergency fallback.
8. FIX: Add spacing between the title and chips in the monster header.

31/10/2026 (1.0.4+8)
AY
1. ADD: Add Premium affirmation decks for habit monsters, with cards matching the monster colour.
2. ADD: Add three share card styles for affirmations.
3. ADD: Add iOS-style page transitions, swipe back and zoom from the tap point.
4. ADD: Let users choose their own apps in Aplikasi Beku, with essential paths protected.
5. ADD: Add the floating guardian monster pill in Aplikasi Beku.
6. UPDATE: Hide accessories and tidy the sleep, calendar and check-in screens.
7. FIX: Match the native splash background to the light theme.
8. FIX: Add spacing between the Monstermu title and subtitle.

======

Arsip format lama:

## [1.0.3+4] — 2026-10-20

**Committer:** Achmad Yukrisna · **Branch:** `fixing_ios_target_and_version` · **Commit:** commit rilis ini

### Diubah
- **Package/bundle ID `com.riung.riung` → `id.riung.riung`** (Android `applicationId`/`namespace` + paket Kotlin, iOS bundle ID, MethodChannel `id.riung.riung/app_usage`, action `RESTART_LOCK`, link Play & kelola langganan). App Firebase baru di `riung-5e979`: iOS `1:809457116609:ios:ea6a284f9d37cee947fb40`, Android `1:809457116609:android:c80834d6e5664f1247fb40` (SHA rilis + debug sudah didaftarkan). Secret CI `GOOGLE_SERVICES_JSON` / `GOOGLE_SERVICE_INFO_PLIST` / `FIREBASE_APP_ID_ANDROID` perlu diperbarui.
- iOS: `GoogleService-Info.plist` kini masuk target Runner (Copy Bundle Resources) dan `Info.plist` punya URL scheme `REVERSED_CLIENT_ID` untuk Google Sign-In — tanpa keduanya app crash saat start / saat login Google.
- iOS: minimum iOS dinaikkan 13.0 → 15.5, disamakan di Podfile (`platform` + `post_install` untuk semua pod) dan `Runner.xcodeproj` (dibutuhkan `cloud_firestore`, sekaligus persiapan iOS 27).
- iOS: `Debug/Release.xcconfig` meng-include xcconfig CocoaPods; `Podfile` kini ikut di-commit.
- iOS: project & scheme di-upgrade Flutter 3.44 (`objectVersion` 60, `customLLDBInitFile` di scheme). AppDelegate (`FlutterImplicitEngineDelegate`) & scene manifest (`UISceneStoryboardFile = Main`) sudah sesuai lifecycle UIScene.

---

## [1.0.2+3] — 2026-10-17

**Committer:** Achmad Yukrisna · **Branch:** `fix/audit-hardening` · **Commit:** commit rilis ini (tindak lanjut re-audit)

### Ditambahkan
- Standar state layar: `RiungStateView` (loading/error/empty/ready), `RiungAsyncView` (pengganti `FutureBuilder`), `RiungEmptyState`, `RiungSkeletonList` di `core/widgets/`. Loading = skeleton, error = `RiungErrorWidget` + "Coba lagi", offline = `RiungOfflineBanner` global.
- `test/screen_state_contract_test.dart` memaksa standar ini: tidak ada `FutureBuilder`/`StreamBuilder` di layar fitur, tidak ada spinner polos sebagai loading layar, dan setiap layar yang memuat data wajib lewat `RiungStateView`/`RiungAsyncView` (pengecualian tercatat beserta alasannya).

### Diperbaiki
- Diterapkan ke Beranda, Tiket serangan, Riwayat koin, Riwayat check-in, Laporan, Brankas monster, Detail Si Hakim, Kategori afirmasi, Jurnal, Onboarding, Sesi Fokus, Profil, Langganan, Unduh data, Kalender latihan.
- Layar yang dulu berputar selamanya bila belum ada akun atau pemuatan gagal (Riwayat check-in, Laporan, Unduh data, Kalender, Jurnal, Kategori afirmasi) kini menampilkan error + "Coba lagi".
- Sesi Fokus: gangguan jaringan tidak lagi ditampilkan sebagai "koin kurang".

### Keamanan
- `firestore.rules`: wallet sepenuhnya server-only (client tidak bisa mengubah `wallet`, dokumen baru wajib wallet nol) dan `premium.active` tidak bisa dinyalakan dari client. `isValidWalletDelta` (bisa di-replay) dihapus.
- Build rilis menolak jalur wallet Firestore/lokal (`main.dart`), sehingga semua mutasi koin lewat server.

---

## [1.0.1+2] — 2026-10-17

**Committer:** Achmad Yukrisna · **Branch:** `fix/audit-hardening` · **Commit:** `26a7a0f`, `f27871d`, + commit rilis ini

### Keamanan
- Backup Android dimatikan (`allowBackup=false`, `data_extraction_rules.xml`) supaya jurnal, check-in, dan hasil tes tidak ikut ke cloud backup/transfer perangkat.
- Build rilis menolak berjalan dengan `StubAuthService` (penjaga di `main.dart`).
- Input teks (nama, jurnal, cerita onboarding, catatan check-in, afirmasi, refleksi Better Me, edit profil) dibatasi panjangnya dan dibersihkan dari karakter kontrol/bidi (`core/config/input_limits.dart`).

### Diperbaiki
- Pengguna baru tidak lagi diisi data dummy; profil, dompet, dan monster mulai kosong.
- Zona waktu notifikasi & tanggal check-in mengikuti perangkat (`DeviceTimeZone`: WIB/WITA/WIT, IANA, lalu `Etc/GMT`), tidak lagi dipaku WIB; zona dikirim ke server saat berbeda.
- Billing: kegagalan inisialisasi/kueri/stream tidak lagi diam — dilaporkan ke Crashlytics dan dikembalikan sebagai error ke UI; pulihkan pembelian dijalankan per 20 item dengan satu kali coba ulang, pembelian yang belum terverifikasi tidak dikonsumsi.
- Toko: langganan stream billing dilepas saat layar ditutup.
- Outbox: event yang sudah gagal 10 kali dibuang agar antrean tidak macet; retry API dibatasi maksimal 5.
- Gambar monster & karakter yang hilang tidak lagi membuat layar crash (`errorBuilder`).

### Ditambahkan
- Tes render `RiungMonster` (bossScale, slot `none`, `anchorsLiar`, rotasi, zIndex, semua kombinasi), tes terjemahan Kenali Dirimu, tes zona waktu, tes outbox/retry.
- Skrip bantu di root repo untuk eksplorasi `riung.pen` & pembersihan aset 3D (`26a7a0f`).

### Desain
- Frame baru **Glass — Monster · Latihan Si Nanti (node)** di `design/riung.pen` untuk `HabitPracticeScreen` (sebelumnya satu-satunya layar tanpa frame Glass).

---

## [1.0.0+1] — 2026-10-17

**Committer:** Achmad Yukrisna · **Branch:** `implement_and_integrations_api` → `dev` · **Commit:** `c95887a`, merge `a30df4b`

### Ditambahkan
- Integrasi REST API Riung: `ApiClient`, `ApiState`, repositori pengguna/konten, dan layanan dompet lewat server.
- Outbox SQLite untuk aktivitas offline yang disinkronkan per batch.
- Draf asesmen yang bisa dilanjutkan.

Riwayat sebelum 1.0.0 (aplikasi awal, desain Riung Glass, aset 3D, ikon, CI) ada di `git log`.
