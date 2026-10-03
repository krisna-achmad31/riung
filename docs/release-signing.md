# Panduan Signing Rilis Riung (Android)

Panduan ini untuk **kamu** (developer) yang menyiapkan build rilis pertama Riung untuk Play Store. Semua langkah di bawah dikerjakan manual di komputermu — tidak ada bagian yang otomatis dijalankan Claude, karena ini menyangkut kunci privat yang harus kamu simpan sendiri dengan aman.

## Kenapa ini penting

Android mewajibkan setiap APK/App Bundle ditandatangani sebelum bisa diinstal atau di-upload ke Play Store. Untuk rilis pertama, kamu generate satu file **keystore** (kunci privat) sekali, lalu pakai kunci yang sama itu untuk **semua update Riung selanjutnya** — kalau kuncinya hilang, kamu tidak akan bisa lagi mengirim update ke aplikasi yang sudah live di Play Store (harus rilis aplikasi baru dengan package name berbeda). Jadi: backup keystore-nya di tempat aman (password manager, hard drive eksternal, cloud storage terenkripsi) — **jangan cuma ada satu salinan**.

## Langkah 1 — Generate keystore

Buka terminal (di luar folder project, supaya file keystore tidak pernah ada resiko ke-commit ke git), lalu jalankan:

```bash
keytool -genkey -v -keystore riung-release.keystore -alias riung -keyalg RSA -keysize 2048 -validity 10000
```

`keytool` sudah tersedia kalau kamu punya JDK terinstal (biasanya ikut ter-install bareng Android Studio). Perintah ini akan menanyakan:
- Password keystore (dan konfirmasi ulang)
- Nama, unit organisasi, organisasi, kota, provinsi, kode negara — boleh diisi seadanya, tidak memengaruhi fungsi aplikasi
- Password khusus untuk alias `riung` (boleh sama dengan password keystore)

**Simpan file `riung-release.keystore` ini di luar folder project** (`D:\bismillah\riung\riung\`), misalnya di folder terpisah seperti `D:\keystores\riung\`. File ini **tidak boleh pernah** masuk ke git — sudah diblok lewat `.gitignore` (`*.jks`, `*.keystore`) sebagai jaring pengaman tambahan.

## Langkah 2 — Buat `android/key.properties`

Buat file baru di `android/key.properties` (sejajar dengan `android/key.properties`, bukan di dalam `android/app/`):

```
storePassword=<password_keystore_kamu>
keyPassword=<password_alias_kamu>
keyAlias=riung
storeFile=/path/lengkap/ke/riung-release.keystore
```

Ganti `<password_keystore_kamu>` dan `<password_alias_kamu>` dengan password yang kamu masukkan di Langkah 1, dan `storeFile` dengan path absolut lengkap ke file keystore-mu (contoh Windows: `D:\\keystores\\riung\\riung-release.keystore` — pakai backslash ganda, atau forward slash `D:/keystores/riung/riung-release.keystore` supaya tidak perlu escaping).

## Langkah 3 — Pastikan `key.properties` tidak ke-commit

Sudah ditambahkan ke `.gitignore` di root project:

```
/android/key.properties
*.jks
*.keystore
```

Kalau kamu pakai `git status` dan `key.properties` tetap muncul sebagai "untracked" tapi tidak pernah `git add`, berarti aman.

## Langkah 4 — Wiring `build.gradle.kts` (sudah dikerjakan)

`android/app/build.gradle.kts` sudah dikonfigurasi untuk otomatis membaca `android/key.properties` kalau file itu ada, dan pakai kuncinya untuk signing config `release`. Kalau file `key.properties` belum ada (misalnya kamu baru clone project ini), build rilis tetap jalan tapi ditandatangani pakai kunci debug bawaan (**tidak bisa dipakai untuk upload ke Play Store**, tapi cukup untuk testing APK release di HP-mu sendiri).

Ringkasnya, yang sudah ada di `build.gradle.kts`:

```kotlin
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}
```

dan di dalam `android { ... }`:

```kotlin
signingConfigs {
    if (keystorePropertiesFile.exists()) {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }
}

buildTypes {
    release {
        signingConfig = if (keystorePropertiesFile.exists()) {
            signingConfigs.getByName("release")
        } else {
            signingConfigs.getByName("debug")
        }
    }
}
```

Kamu tidak perlu mengubah apa pun di sini — cukup pastikan `android/key.properties` ada & isinya benar sebelum build rilis sungguhan.

## Langkah 5 — Build App Bundle (untuk upload ke Play Store)

Play Store mewajibkan format **App Bundle** (`.aab`), bukan APK biasa:

```bash
flutter build appbundle --release
```

Hasilnya ada di `build/app/outputs/bundle/release/app-release.aab`.

## Langkah 6 — Build APK (untuk testing manual di HP, bukan buat Play Store)

Kalau cuma mau install & coba langsung di HP tanpa lewat Play Store, split per-ABI supaya ukurannya lebih kecil per device:

```bash
flutter build apk --release --split-per-abi
```

Hasilnya beberapa APK terpisah per arsitektur CPU di `build/app/outputs/flutter-apk/` (`app-armeabi-v7a-release.apk`, `app-arm64-v8a-release.apk`, `app-x86_64-release.apk`) — pilih yang cocok dengan HP-mu (kebanyakan HP modern pakai `arm64-v8a`).

## Langkah 7 — Google Sign-In: tambahkan SHA fingerprint rilis ke Firebase

Fingerprint SHA-1/SHA-256 yang sekarang terdaftar di Firebase Console
(**Project settings → Your apps → `com.riung.riung`**) itu punya
keystore **debug**, dipakai supaya tombol "Lanjutkan dengan Google" jalan
pas development. Untuk rilis sungguhan, keystore-nya beda
(`riung-release.keystore` dari Langkah 1) — SHA-nya juga beda, jadi
kalau tidak ditambahkan, Google Sign-In akan gagal khusus di build rilis
walau debug tetap normal. Firebase mendukung banyak fingerprint per app
sekaligus — **tambahkan**, jangan ganti yang lama.

1. Ambil SHA-1 & SHA-256 dari `riung-release.keystore`:
   ```bash
   keytool -list -v -keystore riung-release.keystore -alias riung
   ```
   (masukkan password keystore-nya saat diminta)
2. Firebase Console → Project settings → app `com.riung.riung` →
   **Add fingerprint**, tempel SHA-1 & SHA-256 di atas.
3. Kalau kamu mengaktifkan **Play App Signing** (default/disarankan untuk
   app baru di Play Console) — Google menandatangani ulang app dengan
   kuncinya sendiri sebelum sampai ke user, jadi sertifikat yang
   sebenarnya beredar itu **beda lagi** dari `riung-release.keystore`-mu.
   Ambil SHA-1/SHA-256 dari **Play Console → Setup → App integrity → App
   signing key certificate**, dan tambahkan juga ke Firebase seperti
   langkah 2. Ini yang paling sering kelupaan — gejalanya Google Sign-In
   normal saat kamu test APK release manual, tapi gagal begitu user
   install dari Play Store.
4. `googleServerClientId` di `lib/core/config/firebase_config.dart`
   **tidak perlu diubah** untuk ini — nilai itu level project (Web
   client), bukan level sertifikat, jadi sama untuk debug maupun rilis.

## Checklist sebelum build rilis sungguhan

- [ ] Keystore sudah di-generate & disimpan di **luar** folder project
- [ ] Keystore sudah di-backup ke minimal satu tempat lain (password manager / cloud terenkripsi)
- [ ] `android/key.properties` sudah dibuat & terisi benar
- [ ] `git status` tidak menampilkan `key.properties` maupun file `.keystore`/`.jks` sebagai staged
- [ ] `flutter build appbundle --release` sukses tanpa fallback ke kunci debug (cek log build — kalau `key.properties` kebaca, tidak ada warning soal signing)
- [ ] SHA-1/SHA-256 dari `riung-release.keystore` sudah ditambahkan ke Firebase (Langkah 7)
- [ ] Kalau pakai Play App Signing: SHA-1/SHA-256 dari App signing key certificate Play Console juga sudah ditambahkan (Langkah 7.3)
