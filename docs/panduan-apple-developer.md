# Panduan Apple Developer & App Store Connect — Riung iOS
*Untuk pemegang akun Apple Developer · 2026-10-20 · pendamping runbook `backend/deploy/README.md` langkah 4d*

Urutan: A (akun) → B (Developer portal) → C (App Store Connect) → D (Firebase) → E (kirim ke backend) →
F (uji) → G (review).

**Status 2026-10-20** — backend App Store **aktif** (key `6M37Z83MZ5` diterima di sandbox; production API Apple
menjawab `401` sampai rilis pertama — normal; notifikasi TEST sandbox sampai ke server).

| Bagian | Status |
|---|---|
| A. Program berbayar | ✅ (App Store Connect & key IAP bisa dibuat) |
| B1 App ID `id.riung.riung` | ✅ dibuat — **capability Push, Sign in with Apple, App Attest belum masuk profil** |
| B2 Key APNs + DeviceCheck | ✅ `S76JA9YKP5` ("FCM") — untuk Firebase (D2, D3), bukan backend |
| B3 Sertifikat & profil | ✅ distribution + development, profil `Riung Production`/`Riung Development` — buat ulang setelah capability B1 |
| C2/C3 App, Apple ID, Server Notifications | ✅ app `6824618033`, URL webhook terpasang |
| C6 In-App Purchase key | ✅ `6M37Z83MZ5`, terpasang di server |
| E Kirim ke backend | ✅ selesai |
| C1 Paid Apps, C4–C5 produk, C7 sandbox tester, D Firebase, F uji, G review | ⏳ belum dicek |

Data app: bundle id iOS **`id.riung.riung`** (terdaftar di Apple Developer), Apple ID app **`6824618033`**, nama **Riung**, Team ID
**`C75S43V9FY`** (dari `ios_development.cer`). Package Android juga `id.riung.riung`.

> Proyek Flutter sudah memakai `id.riung.riung` (tim app, `dev` 2026-10-20) beserta `GoogleService-Info.plist`-nya.

---

## A. Akun

- [ ] **Apple Developer Program berbayar** (USD 99/tahun) aktif. Akun gratis (*Personal Team*) bisa membuat
      sertifikat development, tapi **tidak** bisa memakai App Store Connect, In-App Purchase, atau TestFlight.
      Cek di <https://developer.apple.com/account> → *Membership details*.
- [ ] Jenis akun: **Individual** → nama penjual di App Store = nama pribadi. **Organization** (butuh nomor
      D-U-N-S) → nama perusahaan. Pindah dari individual ke organisasi bisa belakangan, tapi lebih mudah sejak awal.
- [ ] Peran **Account Holder** dibutuhkan untuk menyetujui perjanjian (C1); peran **Admin** cukup untuk sisanya.

## B. Developer portal — <https://developer.apple.com/account/resources>

1. [ ] **Identifiers → App IDs → +** → *App* → Explicit Bundle ID `id.riung.riung` (sudah dibuat). Capability:
   - *In-App Purchase* (bawaan menyala)
   - *Sign in with Apple* — app memakai `google_sign_in`; App Review 4.8 mewajibkan satu login lain yang
     menjaga privasi bila ada login pihak ketiga, dan Sign in with Apple adalah cara termudah memenuhinya
   - *Push Notifications* (FCM)
   - *App Attest* (Firebase App Check)
2. [ ] **Keys → +**:
   - *Apple Push Notifications service (APNs)* → unduh `.p8` (sekali) → untuk Firebase Cloud Messaging (D2).
   - *DeviceCheck* → untuk cadangan App Check di perangkat lama (D3). Boleh satu key berisi keduanya.
3. [ ] **Certificates**: *Apple Distribution* untuk build TestFlight/App Store. `ios_development.cer` yang ada
   hanya untuk build development di Xcode. Paling mudah: Xcode → *Signing & Capabilities* → *Automatically manage
   signing* dengan tim `C75S43V9FY`; Xcode membuat sertifikat & profil sendiri.

## C. App Store Connect — <https://appstoreconnect.apple.com>

1. [ ] **Business** (dulu *Agreements, Tax, and Banking*): setujui **Paid Apps Agreement**, isi rekening bank
   dan formulir pajak (individu non-AS: W-8BEN). Status harus **Active** — tanpa ini produk tidak bisa dibeli,
   **juga di sandbox**. Verifikasi bank bisa makan beberapa hari, jadi mulai dari sini.
2. [ ] **Apps → + → New App**: iOS, nama *Riung*, bahasa utama Indonesian, bundle id `id.riung.riung`, SKU
   bebas (mis. `riung-ios`).
3. [ ] **App Information**:
   - catat **Apple ID** (angka, mis. `6741234567`) → `APPSTORE_APP_APPLE_ID`
   - *App Store Server Notifications* → **Version 2**; *Production Server URL* **dan** *Sandbox Server URL*:
     `https://riung.e55techlab.com/v1/webhooks/app-store`
4. [ ] **Monetization → In-App Purchases → +** → tipe **Consumable**, tiga produk. *Product ID* harus persis,
   tidak bisa diubah atau dipakai ulang setelah dibuat:

   | Product ID | Isi | Harga (Indonesia) |
   |---|---|---|
   | `coin_pack_small` | 80 koin | Rp15.000 |
   | `coin_pack_medium` | 330 koin | Rp49.000 |
   | `coin_pack_large` | 820 koin | Rp99.000 |

   Tiap produk: nama & deskripsi (Bahasa Indonesia, sama dengan copy toko di app), screenshot untuk review.
   Jumlah koin ditentukan server dari `productId`, bukan dari App Store.
5. [ ] **Monetization → Subscriptions**: buat **satu** *Subscription Group* (mis. "Riung Premium"), isi dua:

   | Product ID | Durasi | Harga | Level di grup |
   |---|---|---|---|
   | `premium_yearly` | 1 tahun | Rp590.000 | 1 (paling atas) |
   | `premium_monthly` | 1 bulan | Rp59.000 | 2 |

   - Satu grup = user hanya punya satu langganan; pindah bulanan → tahunan dihitung *upgrade* (langsung, sisa
     bulan dikembalikan prorata), tanpa tagihan ganda. Server mengikutinya otomatis.
   - **Introductory Offer** → *Free* 1 minggu untuk pelanggan baru, di kedua produk.
   - **Family Sharing: mati** (transaksi anggota keluarga tidak membawa akun Riung pembeli, jadi server
     menolaknya).
   - Lokalisasi grup & produk, screenshot paywall untuk review.
6. [ ] **Users and Access → Integrations → In-App Purchase → Generate In-App Purchase Key** (nama mis.
   `riung-backend`) → unduh `.p8` (**hanya bisa sekali**), catat **Key ID**. **Issuer ID** tertera di halaman
   *Integrations* (bagian *App Store Connect API*; bila belum terlihat, klik *Request Access* sekali).
   Ini yang dipakai backend — bukan sertifikat `.cer`.
7. [ ] **Users and Access → Sandbox → Test Accounts → +**: 1–2 akun sandbox (email yang belum pernah jadi Apple
   ID; region Indonesia agar harga Rupiah). Di iPhone: *Settings → App Store → Sandbox Account* (iOS terbaru:
   *Settings → Developer*), atau login saat pertama membeli dari build Xcode. Build TestFlight memakai Apple ID
   biasa dan tetap tidak ditagih.

## D. Firebase (project `riung-5e979`)

1. [ ] *Project settings → Add app → iOS* dengan bundle id `id.riung.riung` → unduh `GoogleService-Info.plist`, ganti
   file di `riung/ios/Runner/` dan secret CI `GOOGLE_SERVICE_INFO_PLIST`. App lama `com.riung.riung` (iOS/Android), bila
   ada, bisa dihapus setelah build baru jalan.
2. [ ] *Project settings → Cloud Messaging → Apple app configuration*: unggah **APNs key** (B2), Key ID, Team ID
   `C75S43V9FY`.
3. [ ] *App Check → Apps → iOS*: daftarkan **App Attest** (dan **DeviceCheck** dengan key B2). App tetap
   mengirim token limited-use untuk `billing/*/verify`, `DELETE /me`, verifikasi PIN.
4. [ ] *Authentication → Sign-in method*: aktifkan **Apple**. Untuk login dari iPhone tidak perlu Services ID;
   Services ID + key hanya bila Sign in with Apple juga dipakai di Android/web. Backend sudah menerima
   provider `apple.com`.

## E. Kirim ke backend

Kirim **lima nilai** ini. File `.p8` adalah rahasia: **jangan** tempel isinya di chat atau commit ke git.
Taruh di `~/Downloads`, sebutkan nama filenya, nanti saya salin ke VPS (`/var/www/riung/secrets/`, `chmod 400`).

| Nilai | Dari | Env |
|---|---|---|
| Bundle ID | `id.riung.riung` | `APPSTORE_BUNDLE_ID` |
| Issuer ID (UUID) | C6 | `APPSTORE_ISSUER_ID` |
| Key ID (10 karakter) | C6 | `APPSTORE_KEY_ID` |
| File `SubscriptionKey_XXXXXXXXXX.p8` / `AuthKey_….p8` | C6 | `APPSTORE_PRIVATE_KEY_FILE` |
| Apple ID app (angka) | C3 | `APPSTORE_APP_APPLE_ID` |

Simpan salinan `.p8` di password manager — Apple tidak menyimpannya; kalau hilang, buat key baru dan cabut yang lama.

Setelah diisi: deploy ulang, log start harus berisi `"appStore":true`.

## F. Uji sebelum review (sandbox / TestFlight)

- [ ] Build TestFlight dengan `applicationUserName = appAccountToken` (panduan app §11.6).
- [ ] Beli tiap paket koin → koin masuk sekali; di log `purchase_verified` dengan `test=true`. Kalau ditolak
      `purchase_invalid`, cek `appAccountToken` benar-benar terkirim (TODO P1 iOS).
- [ ] Langganan bulanan → aktif; upgrade ke tahunan → plan berganti, tidak ganda; matikan auto-renew → tetap
      Premium sampai habis periode (sandbox: 1 bulan ≈ 5 menit).
- [ ] *Restore Purchases* di HP lain / setelah reinstall → Premium kembali.
- [ ] (Opsional) Refund sandbox lewat StoreKit `Transaction.beginRefundRequest` dari build uji → koin ditarik,
      log `refund_applied store=app_store`. Alur refund server sudah diuji di tes Go.
- [ ] Notifikasi sampai: log `rtdn_received` dengan `store=app_store`.

## G. App Review — yang sering membuat ditolak

- [ ] **4.8 Login**: ada login Google → sediakan Sign in with Apple (B1, D4).
- [ ] **3.1.1**: koin & Premium hanya lewat In-App Purchase di iOS — tidak ada tautan/teks pembayaran di luar app.
- [ ] **3.1.2 Langganan**: paywall menampilkan harga, durasi, trial, bahwa langganan diperpanjang otomatis, cara
      membatalkan, serta tautan *Terms of Use* (EULA) dan *Privacy Policy*; tautan yang sama di metadata App Store.
- [ ] **Restore Purchases**: tombol yang terlihat di paywall/pengaturan.
- [ ] **5.1.1(v) Hapus akun**: ada di app (sudah) + peringatan langganan aktif dengan tautan
      `https://apps.apple.com/account/subscriptions`.
- [ ] Produk IAP & langganan pertama dikirim **bersama** versi app pertama (*Add for Review*).
- [ ] *App Review Information*: akun demo Riung (akun permanen — pembelian butuh login) dan catatan singkat cara
      membeli koin/Premium.
- [ ] Konten kesehatan mental: hindari klaim medis/diagnosis di metadata; layar krisis tetap bisa diakses.
