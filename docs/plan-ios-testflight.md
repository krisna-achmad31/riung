# Plan — build iOS otomatis ke TestFlight
*2026-10-20 · app Flutter `riung/` · bundle `id.riung.riung` · team `C75S43V9FY` · App Store Connect app `6824618033`*

**Status 2026-10-20: berjalan.** PR #2 (`ci/ios-testflight` → `dev`) — build `1.0.3 (1013)` VALID di App Store
Connect lewat CI. Berbeda dari rencana awal: tim app sudah meng-commit signing manual untuk Release
(`Riung Production`) di proyek, dan workflow tetap menerapkan pengaturan yang sama saat build (aman bila proyek
berubah). Penolakan pertama (ITMS-90683, `NSPhotoLibraryUsageDescription` untuk plugin `gal`) sudah diperbaiki tim.

## Tujuan

Setiap push ke `main` (dan tombol *Run workflow*) menghasilkan build iOS **bertanda tangan** yang otomatis
masuk TestFlight untuk penguji internal — tanpa Mac siapa pun menyala. Mac pemilik akun hanya dipakai sekali
untuk menyiapkan signing.

Sekarang: job `build-ios` di `.github/workflows/firebase_app_distribution.yml` hanya membuat IPA **tanpa tanda
tangan** (`--no-codesign`) sebagai artifact — tidak bisa dipasang, tidak bisa ke TestFlight.

## Alur akhir

```
push ke main / Run workflow
   │
   ▼
GitHub Actions, runner macOS (gratis — repo publik)
   1. Flutter (versi dipatok) + Xcode (versi dipatok)
   2. GoogleService-Info.plist dari secret
   3. keychain sementara ← sertifikat distribusi (.p12) · profil App Store (.mobileprovision)
   4. flutter build ipa  --build-number=<naik otomatis>  --export-options-plist=ios/ExportOptions.plist
   5. upload ke App Store Connect (App Store Connect API key)
   6. upload dSYM ke Crashlytics · simpan IPA sebagai artifact · hapus keychain
   7. pesan Telegram "build 1.0.0 (1042) terkirim ke TestFlight"
   │
   ▼
App Store Connect memproses (±10–30 menit) → TestFlight grup internal → penguji dapat notifikasi
```

## Fase 1 — persiapan sekali (pemilik akun, di Mac ini)

| # | Langkah | Hasil |
|---|---|---|
| 1 | Xcode → Settings → Accounts: login dengan Apple ID **pemilik** akun developer (bukan Personal Team) | team *Muhammad Nadhif Firdaus* muncul |
| 2 | `riung/ios/Runner.xcworkspace` → target Runner → Signing & Capabilities: *Automatically manage signing*, Team `C75S43V9FY`; **+ Capability**: Push Notifications, Sign in with Apple, App Attest | `DEVELOPMENT_TEAM` terisi, file `Runner.entitlements` baru — **commit keduanya** |
| 3 | developer.apple.com → Profiles: **buat ulang** profil App Store `Riung Production` untuk `id.riung.riung` (sertifikat *iPhone Distribution*). Profil lama dibuat sebelum capability ditambah, jadi tidak valid lagi | file `Riung_Production.mobileprovision` baru |
| 4 | Keychain Access → *My Certificates* → **iPhone Distribution: Muhammad Nadhif Firdaus** (beserta private key) → Export → `.p12` dengan password kuat | `riung-distribution.p12` + password |
| 5 | App Store Connect → Users and Access → Integrations → **App Store Connect API** → Team Keys → buat key role **App Manager** → unduh `.p8` (sekali) | Key ID + file `.p8` (Issuer ID sudah ada) — **berbeda** dari In-App Purchase key backend |
| 6 | Firebase → project `riung-5e979` → tambah app iOS `id.riung.riung` → unduh `GoogleService-Info.plist` | plist untuk bundle baru (yang lama untuk `com.riung.riung`) |
| 7 | App Store Connect → app Riung → TestFlight → buat grup **internal** (mis. "Tim Riung"), tambahkan penguji | penerima build otomatis |

Taruh file 3–6 di `~/Downloads` dan sebutkan namanya; password `.p12` dikirim terpisah (bukan di repo).

## Fase 2 — perubahan di repo (saya kerjakan)

1. **`riung/ios/ExportOptions.plist`**: `method` = `app-store-connect`, `teamID` = `C75S43V9FY`, `signingStyle`
   = `manual`, `provisioningProfiles` = `{ id.riung.riung: "Riung Production" }`, `uploadSymbols` = true.
2. **`Info.plist`**: `ITSAppUsesNonExemptEncryption` = `false` (app hanya memakai HTTPS standar) — tanpa ini
   setiap build tertahan di pertanyaan *export compliance* dan tidak otomatis tersedia di TestFlight.
3. **Signing Release untuk CI**: target Runner konfigurasi Release memakai signing manual (`Apple Distribution`,
   profil `Riung Production`); Debug tetap otomatis untuk developer di Xcode.
4. **Nomor build naik otomatis**: `CFBundleVersion` = `1000 + github.run_number` (selalu naik, tidak bentrok
   dengan upload manual). `CFBundleShortVersionString` tetap dari `version:` di `pubspec.yaml` — dinaikkan
   manual per rilis (TestFlight menolak build dengan nomor yang sudah dipakai di versi yang sama).
5. **Workflow** — job iOS baru (mengganti job unsigned):
   - trigger: push ke `main` dengan perubahan di `riung/**`, tag `v*`, dan `workflow_dispatch`; **tidak pernah**
     `pull_request` (secret signing tidak boleh tersedia untuk PR dari fork — repo publik)
   - `runs-on` macOS dan versi Xcode **dipatok** (Apple mensyaratkan SDK minimum; naikkan sengaja, bukan ikut
     `latest`); Flutter dipatok ke versi yang dipakai tim
   - keychain sementara dari secret, `security set-key-partition-list` agar `codesign` tidak meminta izin,
     profil disalin ke `~/Library/MobileDevice/Provisioning Profiles/`
   - `flutter build ipa --release --build-number=… --export-options-plist=ios/ExportOptions.plist`
   - upload: `xcrun altool --upload-app --type ios --apiKey … --apiIssuer …` (atau fastlane `pilot` bila Apple
     menutup jalur `altool`)
   - dSYM → Crashlytics (`upload-symbols`), IPA + dSYM sebagai artifact 14 hari
   - langkah `always()`: hapus keychain & file kunci
   - pesan Telegram (bot `@Riung_bot` yang sama) berisi versi, nomor build, commit
   - `concurrency`: satu build iOS per branch, yang lama dibatalkan
6. **`paths-ignore: backend/**`** di workflow app (TODO lama) supaya push backend tidak memicu build app.

### Secret GitHub (repo `krisna-achmad31/riung`)

| Secret | Isi |
|---|---|
| `IOS_DIST_P12_BASE64` / `IOS_DIST_P12_PASSWORD` | sertifikat distribusi (Fase 1.4) |
| `IOS_PROFILE_APPSTORE_BASE64` | `Riung_Production.mobileprovision` (Fase 1.3) |
| `ASC_API_KEY_ID` / `ASC_API_ISSUER_ID` / `ASC_API_KEY_P8_BASE64` | App Store Connect API key (Fase 1.5) |
| `GOOGLE_SERVICE_INFO_PLIST` | **diganti** dengan plist `id.riung.riung` (Fase 1.6) |
| `TELEGRAM_BOT_TOKEN` / `TELEGRAM_CHAT_ID` | notifikasi (opsional) |

## Fase 3 — uji & serah terima

1. Jalankan workflow manual dari branch kerja → build muncul di App Store Connect → TestFlight dalam ±30 menit.
2. Pasang lewat app TestFlight di iPhone; cek: login (termasuk Sign in with Apple), push FCM, App Check, dan
   pembelian sandbox sampai ke backend (`/v1/billing/appstore/verify`, log `purchase_verified` `test=true`).
3. Crash uji → muncul di Crashlytics dengan simbol (dSYM terkirim).
4. Push ke `main` → build otomatis tanpa intervensi; nomor build naik.
5. Catat di runbook app: cara ganti sertifikat/profil, cara naik versi, cara menambah penguji.

## Konfigurasi build TestFlight

Build TestFlight menembak **API produksi** (`https://riung.e55techlab.com`): login Firebase asli, App Store
**sandbox** (TestFlight tidak pernah menagih), pembelian tercatat `test=true` — sama seperti yang akan dilihat
App Review. Staging (token dev + kunci header) tetap untuk build debug/lokal tim, tidak lewat TestFlight.

## Risiko & perawatan

| Risiko | Penanganan |
|---|---|
| Apple menaikkan SDK minimum → upload ditolak | versi Xcode di workflow dipatok dan dinaikkan sengaja; pesan error upload jelas di log |
| Deployment target iOS 13 terlalu rendah untuk pod Firebase terbaru | naikkan ke 15.0 bila `pod install` menolak (cek di run pertama) |
| Sertifikat distribusi habis (Okt 2027) / capability baru | buat ulang sertifikat atau profil → ganti secret; build gagal di langkah signing, bukan diam-diam |
| Penguji eksternal | butuh *beta review* sekali per versi — fase berikutnya, setelah internal stabil |
| Pembelian sandbox di akun produksi | penguji TestFlight internal = orang tim; penguji eksternal bisa dapat koin/Premium gratis (TODO §D) |
| Secret bocor | hanya dipakai di job `push`/`workflow_dispatch`; API key role App Manager (bukan Admin); keychain dihapus tiap run |

## Estimasi

Fase 1: ±30–60 menit oleh pemilik akun (Firebase plist & profil paling lama). Fase 2–3: ±½ hari termasuk 2–3
run percobaan. Android menyusul dengan pola sama (AAB ke Play *internal testing*) setelah Play Console siap.
