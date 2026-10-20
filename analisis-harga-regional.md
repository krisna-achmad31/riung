# Analisis Harga Regional — Riung (Google Play & App Store)

> Strategi harga per negara untuk Riung di **Google Play** dan **App Store** (kedua akun developer sudah terdaftar).
> Sumber fakta: `riung/lib/core/config/economy.dart`, `riung/lib/core/services/billing_service.dart`, `riung/lib/core/services/api/riung_api.dart`, `CLAUDE.md` aturan #3, #4, #6.
> Diperbarui 17 Okt 2026. Kurs di dokumen ini perkiraan; cek ulang saat input harga di konsol.

---

## 1. Kondisi Saat Ini

| Aspek | Status di kode |
|---|---|
| **Bahasa** | Bahasa Indonesia (`id`) utama; `en` hanya cadangan. |
| **Zona waktu** | Mengikuti perangkat (`core/services/device_time_zone.dart`), tidak lagi hardcode `Asia/Jakarta`. |
| **Mata uang acuan** | IDR. Harga di `economy.dart` (`priceIdr`, `hargaBulananIdr`) = **harga patokan Indonesia**, bukan harga jual global. |
| **Tampilan harga** | ✅ Sudah benar: Toko, Paywall Premium, dan Paywall onboarding menampilkan `ProductDetails.price` dari store (otomatis mata uang lokal); `priceIdr` hanya cadangan saat produk store belum termuat. |
| **Remote Config** | Sudah ada `coinpack_*_price_idr` & harga Premium — dipakai sebagai cadangan tampilan, bukan harga jual. |
| **Billing Android** | Google Play Billing via `in_app_purchase` (+ `in_app_purchase_android`), struk diverifikasi server (`verifyPurchase` / `restore`). |
| **Billing iOS** | ⚠️ **Belum siap.** Lihat §5 — server hanya mengenal token Google Play. |
| **Analytics** | ⚠️ Event purchase mengirim `valueIdr` tetap (`billing_service.dart`) — belum sadar mata uang. |

### SKU (Product ID) — sama di kedua store

| Product ID | Jenis | Isi | Patokan IDR |
|---|---|---|---|
| `coin_pack_small` | Consumable | Kantong Koin — 80 koin | Rp15.000 |
| `coin_pack_medium` | Consumable | Peti Koin — 300 + 30 bonus = 330 koin (Terpopuler) | Rp49.000 |
| `coin_pack_large` | Consumable | Brankas Koin — 700 + 120 bonus = 820 koin | Rp99.000 |
| `premium_monthly` | Langganan | Premium 1 bulan, trial 7 hari | Rp59.000 |
| `premium_yearly` | Langganan | Premium 1 tahun = bayar 10 bulan, trial 7 hari, +2 koin/hari | Rp590.000 |

Pakai **Product ID yang persis sama** di Play Console dan App Store Connect supaya kode tidak perlu cabang per platform. Product ID adalah ID global per aplikasi. Harga per negara diatur di konsol, **jangan** buat SKU per negara (`coin_pack_small_us` dsb.).

> ⚠️ Di App Store, Product ID yang sudah pernah dibuat **tidak bisa dipakai ulang** walau produknya dihapus. Ketik dengan teliti.

---

## 2. Yang TIDAK Boleh Berbeda per Negara (CLAUDE.md #3 & #4)

Hanya **harga uang** (paket koin & Premium) yang berbeda per negara. Semua angka berikut tetap global dari `economy.dart`:

| Item | Nilai | Kode |
|---|---|---|
| Mode Fokus 25 / 45 / 60 menit | 25 / 40 / 50 koin | `EconomySpend.fokus25Menit/45/60` |
| Paket 5 sesi Fokus | 100 koin | `EconomySpend.fokusBundle5Sesi` |
| Buka waktu scroll 10 / 20 / 30 / 60 menit | 15 / 25 / 35 / 60 koin | `EconomyScroll.unlock*` |
| Pengaman buka-waktu | maks 3/hari, +10 koin tiap kali, jeda 60 dtk, hanya koin latihan | `EconomyScroll.*` |
| Aksesori kecil / biasa / langka | 60 / 100 / 300 koin | `aksesorisKecil`, `skinCommon`, `skinEpic` |
| Kosmetik 100 / 300 / 500 | common / epic / legendary | `skinCommon/Epic/Legendary` |
| Paket aksesori | diskon 20%, dibulatkan ke 5 | `aksesorisBundel*` |
| Pelindung streak | 20 koin | `pelindungStreak` |
| Tukar tiket tambahan | 30 koin **hasil latihan** — tiket tidak pernah dijual dengan uang (`EconomyTiket.tiketDijual = false`) | `tiketTambahan` |
| Isi paket koin | 80 / 330 / 820 koin | `EconomyCoinPacks` |
| Trial, sesi Fokus gratis | 7 hari; 1 sesi/hari (Premium 3) | `EconomyPremium`, `EconomyFreeTier` |

Garis etis yang berlaku di semua negara:
- Progres monster tidak pernah bisa naik karena pembelian.
- Layar koin-kurang selalu menawarkan latihan sebelum beli.
- Harga regional **statis per negara**, tidak pernah dinamis per pengguna (tidak ada "deteksi orang kaya").
- Negara yang lebih murah tidak mendapat koin/tiket/trial lebih banyak. Yang berbeda hanya harga uang.

---

## 3. Prinsip Penentuan Harga

1. **Indonesia = jangkar.** Harga IDR di `economy.dart` tidak diubah.
2. **Rasio antarproduk dijaga sama di semua negara**, mengikuti Indonesia:
   Peti ≈ 3,3× Kantong · Brankas ≈ 6,6× Kantong · Premium bulanan ≈ 4× Kantong. Dengan begitu harga per koin selalu makin murah di paket besar, dan Premium tidak terasa "aneh" dibanding koin di negara mana pun.
3. **Tahunan = 10 × bulanan** (gratis 2 bulan) di semua negara, sesuai CLAUDE.md — dibulatkan ke akhiran harga lokal (.99, .90, 9.000, dst.).
4. **Tiga kelompok daya beli:**
   - **Jangkar**: Indonesia.
   - **Berkembang** (Asia Tenggara lain, India): ±setara Indonesia dalam USD (Premium ≈ US$3–4,3/bln).
   - **Berpendapatan tinggi** (AS, Kanada, Eropa, Inggris, Jepang, Australia, Selandia Baru, Singapura): ≈1,6× Indonesia (Premium ≈ US$6/bln). Masih jauh di bawah aplikasi sejenis (Calm/Headspace US$13–15/bln), wajar untuk aplikasi baru.
5. **Harga sudah termasuk pajak** (PPN/VAT/GST) di hampir semua negara, kecuali AS & Kanada (pajak ditambahkan saat checkout). Tabel di bawah = harga yang dilihat pengguna.

---

## 4. Tabel Harga per Negara

Kurs perkiraan: 1 USD ≈ Rp16.300 · RM4,20 · ฿33 · ₱57 · ₫25.500 · ₹88 · CA$1,37 · A$1,52 · NZ$1,68 · S$1,30 · ¥150 · €0,91 · £0,79.

### 4.1. Jangkar & pasar berkembang

| Negara | Kantong (80) | Peti (330) | Brankas (820) | Premium /bln | Premium /thn | ≈ USD /bln |
|---|---|---|---|---|---|---|
| 🇮🇩 Indonesia (IDR) | Rp15.000 | Rp49.000 | Rp99.000 | Rp59.000 | Rp590.000 | $3,62 |
| 🇲🇾 Malaysia (MYR) | RM4,90 | RM14,90 | RM29,90 | RM17,90 | RM179,00 | $4,26 |
| 🇹🇭 Thailand (THB) | ฿35 | ฿119 | ฿239 | ฿139 | ฿1.390 | $4,21 |
| 🇵🇭 Filipina (PHP) | ₱59 | ₱199 | ₱399 | ₱229 | ₱2.290 | $4,02 |
| 🇻🇳 Vietnam (VND) | ₫25.000 | ₫79.000 | ₫159.000 | ₫99.000 | ₫990.000 | $3,88 |
| 🇮🇳 India (INR) | ₹59 | ₹199 | ₹399 | ₹249 | ₹2.490 | $2,83 |

### 4.2. Pasar berpendapatan tinggi

| Negara | Kantong (80) | Peti (330) | Brankas (820) | Premium /bln | Premium /thn | ≈ USD /bln |
|---|---|---|---|---|---|---|
| 🇺🇸 Amerika Serikat (USD) | $1,49 | $4,99 | $9,99 | $5,99 | $59,99 | $5,99 (+pajak) |
| 🇨🇦 Kanada (CAD) | CA$1,99 | CA$6,99 | CA$13,99 | CA$7,99 | CA$79,99 | $5,83 (+pajak) |
| 🇸🇬 Singapura (SGD) | S$1,99 | S$6,49 | S$12,99 | S$7,99 | S$79,99 | $6,15 |
| 🇯🇵 Jepang (JPY) | ¥250 | ¥800 | ¥1.600 | ¥900 | ¥9.000 | $6,00 |
| 🇦🇺 Australia (AUD) | A$2,49 | A$7,99 | A$14,99 | A$8,99 | A$89,99 | $5,91 |
| 🇳🇿 Selandia Baru (NZD) | NZ$2,49 | NZ$8,49 | NZ$16,99 | NZ$9,99 | NZ$99,99 | $5,95 |
| 🇬🇧 Inggris (GBP) | £1,49 | £4,49 | £8,99 | £4,99 | £49,99 | $6,32 |
| 🇪🇺 Zona Euro (EUR) | €1,49 | €4,99 | €9,99 | €5,99 | €59,99 | $6,58 |

**Negara lain** (yang tidak ada di tabel): biarkan store mengonversi otomatis dari harga dasar USD (§6), lalu tinjau sesekali.

> Catatan App Store: Apple memakai daftar *price point* tetap per mata uang. Kalau angka di tabel tidak tersedia persis, pilih price point terdekat. Di Google Play harga bebas diketik.

### 4.3. Perkiraan pendapatan bersih (Indonesia)

| Produk | Harga | Setelah PPN (±11%) | Bersih setelah komisi 15%* |
|---|---|---|---|
| Kantong Koin | Rp15.000 | ≈Rp13.500 | ≈Rp11.500 |
| Premium bulanan | Rp59.000 | ≈Rp53.200 | ≈Rp45.200 |
| Premium tahunan | Rp590.000 | ≈Rp531.500 | ≈Rp451.800 |

\*Komisi 15% berlaku jika: **Google Play** — langganan selalu 15%, consumable 15% untuk US$1 juta pertama/tahun. **Apple** — wajib daftar **App Store Small Business Program** dulu (kalau tidak, 30% untuk consumable & langganan tahun pertama). Daftarkan sekarang, sebelum produk dirilis.

---

## 5. Celah Teknis yang Harus Ditutup Sebelum Rilis

### 5.1. App Store — wajib sebelum rilis iOS ⚠️
Saat ini alur pembelian hanya untuk Android:
- `billing_service.dart` hanya meng-import `in_app_purchase_android`.
- `RiungApi.verifyPurchase` / `restore` hanya mengirim `{productId, purchaseToken}` — server menganggap semuanya token Google Play.

Yang perlu dibangun:
1. **Klien**: tambahkan `in_app_purchase_storekit`; kirim `platform: 'android' | 'ios'` ke `verifyPurchase` & `restore` (request model typed, sesuai aturan model di CLAUDE.md).
2. **Server**: cabang verifikasi iOS lewat **App Store Server API** (validasi JWS transaksi) — koin/Premium tetap hanya aktif setelah server memverifikasi (CLAUDE.md #6).
3. **Langganan**: terima **App Store Server Notifications v2** (perpanjang, batal, refund) — padanan Real-time Developer Notifications di Play.
4. **Restore**: tombol "Pulihkan pembelian" wajib ada di iOS (aturan review Apple).
5. **Paywall iOS** (aturan review Apple 3.1.2): tampilkan harga, durasi, syarat trial 7 hari, dan tautan Syarat Penggunaan (EULA) + Kebijakan Privasi.

> Catatan: CLAUDE.md aturan #6 masih menyebut "Google Play Billing saja". Begitu iOS dirilis, aturan itu perlu diperbarui menjadi "Google Play Billing + StoreKit, keduanya lewat `in_app_purchase`".

### 5.2. Analytics sadar mata uang
`billing_service.dart` → `_analytics.purchase(valueIdr: …)` mengirim harga IDR tetap untuk semua negara. Ganti jadi `value: product.rawPrice, currency: product.currencyCode` dari `ProductDetails` supaya laporan pendapatan per negara akurat.

### 5.3. Server tidak perlu tahu harga
Verifikasi cukup memastikan `productId` sah + struk/token asli. Jumlah koin yang dikreditkan diambil dari tabel produk di server (80/330/820), **bukan** dari harga — jadi harga regional tidak memengaruhi ekonomi koin. Negara pembeli bisa dicatat dari struk (`countryCode` di Play, `storefront` di Apple) untuk analitik/anti-fraud, opsional.

### 5.4. Tes kontrak
`test/api_contract_parity_test.dart` tetap memeriksa `priceIdr` — perannya sekarang "harga patokan Indonesia & cadangan tampilan". Tidak perlu dihapus.

---

## 6. Langkah Setup di Konsol

### Google Play Console
1. **Monetize → Products → In-app products**: buat `coin_pack_small/medium/large` (consumable).
2. Isi **harga default dalam IDR** (Rp15.000 / Rp49.000 / Rp99.000) → klik **Update exchange rates** agar negara lain terisi otomatis → **timpa** negara di tabel §4 secara manual.
3. **Monetize → Subscriptions**: buat `premium_monthly` dan `premium_yearly`, masing-masing dengan satu **base plan** auto-renew (1 bulan / 1 tahun).
4. Di tiap base plan: atur harga per negara seperti §4, lalu tambahkan **offer free trial 7 hari** (eligibility: pengguna baru).
5. Isi **Payments profile** & info pajak (sudah wajib untuk akun yang memonetisasi).

### App Store Connect
1. **Agreements, Tax, and Banking**: tandatangani **Paid Applications Agreement**, isi bank & pajak — tanpa ini IAP tidak bisa dijual.
2. Daftar **App Store Small Business Program** (komisi 15%).
3. **In-App Purchases**: buat 3 *Consumable* dengan Product ID yang sama seperti Play.
4. **Subscriptions**: buat satu *Subscription Group* (mis. "Riung Premium") berisi `premium_monthly` & `premium_yearly` di grup yang sama — supaya pengguna bisa naik/turun paket tanpa dobel tagihan.
5. **Pricing**: pilih **Indonesia sebagai negara dasar** (base storefront) dengan harga IDR → Apple menyesuaikan otomatis ke negara lain → timpa negara di tabel §4.
6. Tambahkan **Introductory Offer → Free Trial 1 minggu** di kedua langganan.
7. Isi lokalisasi nama/deskripsi produk (Bahasa Indonesia + English) dan screenshot review untuk tiap IAP.

---

## 7. Urutan Pasar yang Disarankan

Hal penting di luar harga: Riung adalah **aplikasi kesehatan mental**.

1. **Tahap 1 — Indonesia saja.** Seluruh copy, konten audio, dan **nomor layanan krisis** saat ini untuk Indonesia. Di kedua konsol, batasi ketersediaan negara hanya ke Indonesia.
2. **Tahap 2 — Malaysia, Singapura, Brunei.** Bahasa Melayu cukup dekat dengan Bahasa Indonesia, tapi **layar krisis harus menampilkan nomor bantuan lokal** tiap negara sebelum dibuka (CLAUDE.md #4: layar krisis selalu bisa diakses).
3. **Tahap 3 — negara lain** (Asia Tenggara lainnya, AS, Eropa, dst.) hanya setelah ada terjemahan penuh (bukan cadangan `en`) + nomor krisis per negara + tinjauan regulasi data kesehatan setempat (mis. GDPR untuk Eropa).

Tabel harga §4 sudah disiapkan sekarang supaya tidak perlu menghitung ulang saat ekspansi, tapi **cukup aktifkan negara yang sudah siap**.

---

## 8. Rangkuman

| Keputusan | Rekomendasi |
|---|---|
| Harga beda per negara? | **Ya**, statis per negara lewat konsol store (tabel §4). |
| SKU per negara? | **Tidak.** 5 Product ID yang sama di Play & App Store. |
| Ubah `economy.dart`? | **Tidak.** Harga IDR = jangkar Indonesia & cadangan tampilan. Harga koin in-game tetap global. |
| Tampilan harga di app? | Sudah benar (`ProductDetails.price`). |
| iOS siap jual? | **Belum** — perlu StoreKit + verifikasi server App Store + restore + paywall sesuai aturan Apple (§5.1). |
| Analytics? | Ganti ke `value` + `currency` dari `ProductDetails` (§5.2). |
| Komisi | Daftar Apple Small Business Program; Play otomatis 15% untuk langganan. |
| Negara rilis awal | **Indonesia dulu**; ekspansi menunggu nomor krisis lokal & terjemahan. |

## 9. Langkah Berikutnya

1. Buat 5 produk di Play Console & App Store Connect dengan harga Indonesia + trial 7 hari (§6).
2. Daftar Apple Small Business Program & selesaikan Paid Applications Agreement.
3. Bangun jalur pembelian iOS (§5.1) sebelum mengirim build iOS ke review.
4. Perbaiki analytics purchase agar sadar mata uang (§5.2).
5. Saat siap ekspansi: isi harga negara tujuan dari tabel §4, tambahkan nomor krisis lokal, aktifkan negaranya.
6. Opsional: uji harga via Remote Config + Firebase A/B Testing hanya untuk **tampilan paywall/urutan paket** — harga jual tetap diatur di konsol store.
