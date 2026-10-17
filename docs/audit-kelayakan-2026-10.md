# Audit Kelayakan Riung — 17 Okt 2026

Cakupan: hanya fitur yang **sudah ada** di `riung/` (branch `fix/audit-hardening`, versi 1.0.2+3). Backend (`https://riung.e55techlab.com`) tidak ada di repo ini, jadi API diuji dari sisi klien terhadap kontrak `docs/panduan-integrasi-app.md` memakai mock HTTP.

## Ringkasan

| | |
|---|---|
| Test lama | 276 lulus |
| Test baru | 44 (35 unit/API di `test/audit_billing_api_test.dart`, 9 widget di `test/audit_paywall_widget_test.dart`) — semua lulus |
| Temuan | **1 Critical · 5 High · 7 Medium · 6 Low** |
| Siap rilis? | **Belum.** C-01 (data jurnal bocor antar akun) dan H-01/H-03 (paywall macet saat pending/restore) perlu beres dulu sebelum production. |

Test bernama `REPRO <ID>` memastikan bug-nya memang ada: test itu lulus selama bug masih ada. Setelah bug diperbaiki test-nya akan gagal, dan saat itu ekspektasinya dibalik jadi perilaku yang benar.

```bash
cd riung && flutter test test/audit_billing_api_test.dart test/audit_paywall_widget_test.dart
```

Yang sudah benar (diverifikasi test):
- Receipt diverifikasi server dulu sebelum consume/ack.
- `autoConsume: false`.
- Status pending tidak membuka Premium.
- Pembatalan diselesaikan dengan benar.
- Kartu ditolak meneruskan pesan dari Play.
- 409 dan 5xx tidak consume, jadi pembelian bisa dipulihkan lewat restore.
- Anonim tidak bisa beli (dijaga di UI dan service).
- Harga dari Play sudah dinamis per region.
- Kontrak header (Bearer, App Check, Idempotency-Key) sesuai.
- 401 memicu refresh token sekali.
- 400/403/404 tidak di-retry.
- 429 dengan `Retry-After` besar langsung menyerah.
- 5xx di-retry dengan Idempotency-Key yang sama.
- Timeout, offline, dan JSON rusak dipetakan ke `ApiException`.
- Pindah akun di tengah retry dibatalkan.
- Snapshot `/me` di-scope per uid.
- Wallet hanya dimutasi server.

---

## Tabel prioritas temuan

| ID | Prioritas | Area | Lokasi | Masalah | Solusi |
|---|---|---|---|---|---|
| **C-01** | 🔴 Critical | Pindah akun / privasi | `lib/core/services/local_database_service.dart:30-50`, `local_user_repository.dart:138-180`, `local_prefs_store.dart:30-71`, `jurnal_pin_service.dart:22-31`, `journal_crypto_service.dart:21-34`, `auth_notifier.dart:142` | Logout tidak menghapus atau mengisolasi data lokal. Tabel `journal_entries` dan `checkin_history` tidak punya `user_id`, kunci enkripsi jurnal dan PIN berlaku untuk seluruh perangkat, dan prefs (hasil tes kepribadian, BetterMe, afirmasi custom, kosmetik, perisai, fokus prabayar, cadangan koin-beli) bersifat global. Akibatnya **akun B yang login di HP yang sama bisa membaca jurnal dan mood akun A**, dan batas jurnal harian ikut terhitung bersama. Untuk aplikasi kesehatan mental ini pelanggaran privasi serius. Copy logout ("Progresmu tersimpan…") juga menyesatkan. (REPRO di test grup 1) | Scope semua data lokal per uid (lihat §Solusi C-01). Kalau terpaksa jalan pintas: saat logout, jika outbox kosong, panggil `deleteAllLocalData()`, dan beri peringatan bahwa jurnal hanya tersimpan di HP ini. |
| **H-01** | 🟠 High | IAP pending/error | `features/toko/screens/paywall_premium_screen.dart:59-61, 97-98, 126`; `features/onboarding/widgets/paywall_step.dart:60-62, 94-95, 118` | (a) Saat **pembayaran pending** (VA, Indomaret, Alfamart) layar terkunci di "Memproses...": tombol X tidak berfungsi, dan di onboarding tombol "Lanjut versi gratis" ikut nonaktif, jadi **user tidak bisa menyelesaikan onboarding** sampai pembayaran lunas (bisa berhari-hari). (b) `buyPremium()` bisa melempar `ApiException`/`StateError`/`PlatformException` (misalnya `/me` gagal) tanpa ditangkap, sehingga `_processing` tetap `true` selamanya. | Pending tidak boleh mengunci layar: tampilkan pesan menunggu pembayaran, aktifkan lagi X dan "Lanjut versi gratis". Bungkus `buyPremium` dengan `try/catch` lalu reset `_processing`. |
| **H-02** | 🟠 High | Produk/harga langganan | `paywall_premium_screen.dart:46, 165, 185`; `paywall_step.dart:48, 152, 168`; `billing_service.dart:176-183` | Plugin Android mengembalikan **satu `ProductDetails` per offer** (base plan dan trial 7 hari). Map `{p.id: p}` hanya menyimpan item terakhir, jadi harga bisa tampil "Gratis/tahun", dan offer yang dibeli bergantung pada urutan dari Play. Teks "Coba gratis 7 hari" diambil dari Remote Config, bukan dari offer yang tersedia. User yang sudah pernah trial tetap melihat janji trial padahal Play menagih langsung (melanggar kebijakan Play: harga dan trial harus akurat). | Pilih offer secara eksplisit (§Solusi H-02). Tampilkan harga recurring dari pricing phase terakhir. Teks CTA trial hanya muncul bila offer trial benar-benar ada. |
| **H-03** | 🟠 High | Restore | `billing_service.dart:185`; `paywall_premium_screen.dart:101-107`; `paywall_step.dart:98-101`; `langganan_screen.dart:181-188, 247-254` | `restorePurchases()` tanpa riwayat pembelian menghasilkan daftar kosong dan **tidak memancarkan update apa pun**, sehingga paywall dan onboarding macet di "Memproses..." selamanya. Error dari Play (`InAppPurchaseException`) tidak ditangkap. Layar Langganan hanya menunggu `delay(3 dtk)` tanpa memberi hasil ke user. | `restorePurchases()` mengembalikan `RestoreOutcome {restored, none, failed}` (§Solusi H-03). Tampilkan "Tidak ada pembelian untuk dipulihkan". |
| **H-04** | 🟠 High | Upgrade langganan | `billing_service.dart:176-183` | Pindah bulanan ↔ tahunan memakai `buyNonConsumable` biasa tanpa `changeSubscriptionParam`, dan tidak ada guard "sudah Premium". Akibatnya **dua langganan aktif dan tertagih ganda**. Dokumen API §11.2 sudah mewajibkan `GooglePlayPurchaseParam` + `changeSubscriptionParam`. | §Solusi H-04. Sembunyikan CTA beli untuk plan yang sedang aktif. |
| **H-05** | 🟠 High | Hapus akun saat berlangganan | `hapus_akun_screen.dart:41-74` | Akun dihapus padahal langganan Play tetap aktif dan terus menagih. Saat ini hanya ada teks peringatan, tanpa tautan langsung ke halaman kelola langganan, dan alur hapus tetap bisa dilanjutkan. Ini rawan komplain dan chargeback. | Jika `premiumNow`, tampilkan tombol "Kelola di Google Play" (deeplink `https://play.google.com/store/account/subscriptions?sku=…&package=com.riung.riung`) sebelum tombol hapus. |
| M-01 | 🟡 Medium | Harga hardcode / loading | `paywall_premium_screen.dart:166, 173`; `paywall_step.dart:155, 164`; `toko_strings.dart:403-407, 445-447, 731-735, 773-775`; `langganan_screen.dart:64-74`; `premium_locked_screen.dart:48` (+ `common_strings.dart:125, 193`); `profil_strings.dart:444, 768`; `toko_screen.dart:372` (`priceShort`) | Selama produk Play dimuat, atau saat Play gagal, paywall menampilkan **"Rp590.000/tahun" hardcode** tanpa skeleton dan tanpa tombol coba lagi. User USD/EUR melihat Rupiah. Layar Langganan dan Premium-Locked **selalu** menampilkan Rupiah dari economy/Remote Config, tidak pernah dari Play. | §Solusi M-01: skeleton saat loading, teks netral + "Coba lagi" bila gagal, dan semua teks harga hanya dari `ProductDetails.price`. |
| M-02 | 🟡 Medium | Keamanan entitlement | `core/models/user_profile.dart:113-123`; `api_state.dart:130, 137-139`; gerbang di `meditasi_detail_screen.dart:28`, `tidur_detail_screen.dart:28`, `betterme_home_screen.dart:48`, `laporan_screen.dart:125`, `kepribadian_hasil_screen.dart:56` | Status Premium berasal dari server (bagus), tetapi (a) kedaluwarsa dihitung dari **jam HP**: memundurkan jam membuat Premium yang sudah habis tetap aktif (REPRO), dan (b) snapshot `/me` disimpan sebagai **plaintext di SharedPreferences** (`api_me_$uid`) dan dipakai saat offline. Di HP root, cukup edit prefs lalu matikan internet untuk membuka konten Premium yang dibundel. Gerbang koin, tiket Fokus, dan jurnal sudah dijaga server. | Simpan offset `serverTime` dari `/me` dan hitung kedaluwarsa dengan jam server. Pindahkan cache ke `flutter_secure_storage` atau tambahkan HMAC. Batasi cache offline maksimal 72 jam. Risiko sisa untuk konten offline bisa diterima. |
| M-03 | 🟡 Medium | Spam-click | `toko_screen.dart:68-79, 182` | `busy` pada kartu paket koin baru aktif setelah status pending. Dobel-tap sebelum sheet Play muncul (ada jeda `await refresh()`) memicu dua alur `buyConsumable`. Pengecualian yang dilempar juga tidak ditangkap. | Set `_purchasingCoinPack = true` sebelum `ensureAccountForPurchase`, lalu reset di `finally` saat terjadi error. |
| M-04 | 🟡 Medium | iOS / App Store | `billing_service.dart:5-6, 264`; `api_client.dart:50` | Alur billing khusus Android: `consumePurchase` via `InAppPurchaseAndroidPlatformAddition` dan `X-Platform: android` hardcode. Di iOS setiap pembelian koin akan gagal. **iOS saat ini belum layak rilis.** | Jika iOS masuk rencana, tambahkan cabang StoreKit (`completePurchase` untuk consumable, verify via App Store Server API) dan `X-Platform` dari `Platform.operatingSystem`. |
| M-05 | 🟡 Medium | Restore lintas akun | `billing_service.dart:202` | Langganan Play milik akun Riung lain (Google account yang sama di HP) ditolak server, dan klien **diam saja**: user B tidak tahu kenapa Premium-nya tidak pulih. (REPRO) | Teruskan `error.code` per baris, lalu tampilkan "Langganan ini terhubung ke akun Riung lain. Masuk dengan akun itu untuk memakainya." |
| M-06 | 🟡 Medium | Restore mapping | `billing_service.dart:200-203` | Hasil `/v1/billing/restore` dipetakan **berdasarkan indeks**, bukan `purchaseToken`. Jika server menghilangkan atau mengurutkan ulang baris, ack atau consume bisa jatuh ke pembelian yang salah. | Cocokkan dengan `row['purchaseToken']` (minta server mengembalikannya). Pakai indeks hanya sebagai fallback. |
| M-07 | 🟡 Medium | Data rusak | `riung_api.dart:82-86` (`FocusTicket`), `api_state.dart:357-365, 404` | Getter tiket memakai cast non-null. Tiket rusak di secure storage atau dari server memicu `TypeError`, padahal `prefetchTickets` hanya menangkap `ApiException`, jadi error tidak tertangani saat bootstrap. | Parse defensif (`as String? ?? ''`) dan filter tiket yang tidak valid. Tangkap `Object` di `prefetchTickets`. |
| L-01 | ⚪ Low | API error parsing | `api_client.dart:254-255` | `error.code` atau `message` yang bukan string memicu `TypeError`, bukan `ApiException`. (REPRO) | `'${error['code'] ?? 'http_error'}'`. |
| L-02 | ⚪ Low | UI 360dp | `paywall_premium_screen.dart:189` | Baris "Pulihkan pembelian · Ketentuan" berupa `Row` tanpa `Wrap`/`Flexible`, sehingga overflow 27px di 360dp dengan font test. Di HP nyata berisiko pada font scale ≥1.3. (REPRO) | Ganti dengan `Wrap(alignment: WrapAlignment.center, spacing: AppSpacing.lg, …)`. |
| L-03 | ⚪ Low | Analytics | `billing_service.dart:276-277` | Event `purchase` selalu bernilai IDR statis, sehingga data revenue untuk pasar global salah. | Pakai `product.rawPrice` dan `product.currencyCode`. |
| L-04 | ⚪ Low | Rate limit restore | `billing_service.dart:206-212` | `/billing/restore` dibatasi 5/jam. Error 429 tampil sebagai "pengiriman gagal" generik. | Map `rate_limited` ke pesan "Coba lagi dalam beberapa menit". |
| L-05 | ⚪ Low | Double snackbar | `main.dart:166-169` + `paywall_premium_screen.dart:68` | 409 `purchase_invalid` pada verify memicu snackbar global `showApiError` **dan** snackbar billing dari layar. | `verifyPurchase` / `restore` → `reportErrors: false`. |
| L-06 | ⚪ Low | Langganan | `langganan_screen.dart:73` | Teks "Diperpanjang otomatis" tetap tampil walau user sudah mematikan auto-renew (server tetap `active` sampai `expiresAt`). | Tampilkan berdasarkan `premium.autoRenewing` dari `/me`, jika server menyediakannya. |

---

## 1. Alur bisnis & user journey

| Langkah | Hasil audit |
|---|---|
| Onboarding → tes → paywall onboarding | ✅ Alur berjalan. ❌ H-01: pending mengunci "Lanjut versi gratis". ❌ H-03: restore tanpa riwayat membuat layar macet. |
| Anonim → Daftar/Masuk | ✅ `ensureAccountForPurchase` muncul sebelum pembelian uang asli. ✅ Billing service menolak transaksi anonim. ✅ `link()` memigrasi akun anonim di server. ⚠️ "Masuk" ke akun yang sudah ada **tidak** memigrasi data anonim (disengaja), tetapi data lokal anonim tetap terlihat di akun itu (bagian dari C-01). |
| Fitur gratis vs gating | Koin, tiket Fokus, App Beku, dan akses jurnal (`/v1/journal/access`) **dijaga server** ✅. Konten meditasi, tidur, BetterMe, laporan bulanan, dan gaya kartu karakter **hanya dijaga di klien**. Asetnya dibundel, jadi bisa di-bypass lewat APK patch atau M-02. Ini risiko yang bisa diterima untuk konten offline, asalkan cache diperketat (M-02). |
| Paywall → Pro | ✅ Status `success` memanggil `refreshProfile()` lalu menutup layar, sehingga Pro aktif **tanpa restart** (sesuai syarat 4a). |
| Logout | ❌ C-01. |
| Hapus akun | ✅ Server dihapus, cache dibersihkan, data lokal dihapus, kembali ke Splash. ✅ Retry yang jawabannya hilang ditangani (`deleteAccount` "uncertain"). ❌ H-05. |
| Pindah akun A → B | ✅ Snapshot `/me`, outbox, tiket, dan Idempotency-Key di-scope per uid. ✅ Retry dibatalkan jika akun berganti. ❌ Data lokal dan prefs bocor (C-01). ⚠️ Langganan Play milik A tidak pernah pindah ke B (bagus, karena server menolak via `obfuscatedAccountId`), tetapi B tidak diberi tahu (M-05). |

## 2. Fitur & edge case UI

- **Double-tap / spam click**: paywall Premium aman (`_processing` diset sebelum `buyPremium`). Paket koin di Toko tidak aman (M-03). Pulihkan di Langganan aman (`_checking`).
- **Tombol Back**: onboarding memakai `PopScope` (kembali per langkah) ✅. Di paywall, tombol Back sistem tetap bisa menutup layar walau X dikunci. Perilakunya tidak konsisten, tapi masih bisa jadi jalan keluar dari H-01.
- **Empty/loading/error**: layar inti memakai `RiungStateView` (sudah ada `screen_state_contract_test.dart`). Paywall tidak punya loading state untuk harga (M-01).
- **Offline**: `RiungOfflineBanner` dan outbox aktivitas (maksimal 10 percobaan, lalu dibuang dan dicatat di Crashlytics) ✅. Cache `/me` dipakai saat error retryable ✅.
- **Input**: jurnal dan afirmasi disimpan lokal dan terenkripsi. Validasi email/password lewat Firebase dengan pemetaan error yang lengkap (`firebase_auth_service.dart:141-165`) ✅.

## 3. API (request, response, jaringan)

Semua skenario pada tabel di bawah diuji di `audit_billing_api_test.dart` grup 3.

| Skenario | Perilaku klien | Status |
|---|---|---|
| Header | `Authorization: Bearer <Firebase ID token>`, `X-Firebase-AppCheck` (limited-use untuk verify/hapus/PIN), `X-App-Version`, `X-Platform`, `Idempotency-Key` untuk mutasi | ✅ |
| 400 | Tidak di-retry, `code`/`requestId` diteruskan | ✅ |
| 401 | Token di-refresh paksa sekali; jika gagal, `ApiException(401)` | ✅ |
| 403/404 | Tidak di-retry | ✅ |
| 426 | Konten melempar ulang (`api_repositories.dart:261`), memaksa update | ✅ |
| 429 | `Retry-After` ≤5 dtk di-retry, >5 dtk langsung menyerah | ✅ |
| 5xx | Retry eksponensial (maks 2, batas keras 5), key sama | ✅ |
| Timeout 15 dtk / offline | `ApiException(0)` retryable, lalu fallback cache | ✅ |
| JSON rusak | `invalid_response` | ✅ |
| `error.code` bukan string | `TypeError` | ❌ L-01 |
| HTTPS | Wajib, kecuali host dev lokal | ✅ |

## 4. In-App Purchase & Subscription

| Skenario | Hasil |
|---|---|
| a. Berhasil → Pro langsung aktif | ✅ verify, ack, `state.refresh()`, `refreshProfile()`, tanpa restart. ❌ H-04 jika user sudah punya plan lain. |
| b. Dibatalkan | ✅ `canceled`: `_processing` direset tanpa pesan error. |
| c. Pending (VA/Indomaret/Alfamart) | ✅ Akses Pro **tidak** diberikan dan tidak di-ack. Setelah lunas, `purchased` diproses. ❌ UI macet (H-01). |
| d. Kartu ditolak / saldo kurang | ✅ `error` + pesan lokal dari Play. Error ditampilkan di sheet Play sendiri dan aplikasi menerima `error`/`canceled`. |
| e. Restore (ganti HP/reinstall) | ✅ Otomatis setelah bootstrap `/me` (`main.dart:350-355`). ✅ Verifikasi server per chunk 20. ❌ H-03 (tanpa feedback dan macet), M-05, M-06. |
| f. Expired / grace / hold / cancel / refund | Status diambil dari server: `active` atau `in_grace` berarti Premium; `on_hold` dan `expired` berarti bukan Premium; cancel tetap Premium sampai `expiresAt` (tergantung server); refund menarik koin dan menimbulkan `debtCoins`. Klien menambah toleransi `graceHari` dan bergantung pada jam HP (M-02). Belum ada UI khusus untuk *account hold* ("perbarui metode pembayaran"); tampilannya sama dengan "Kedaluwarsa". |
| Keamanan status | ✅ Premium dan wallet tidak pernah ditulis klien. ⚠️ Cache plaintext + jam HP (M-02). |

## 5. Produk & harga dinamis per region

**Status: sebagian dinamis.**
- ✅ Dinamis: harga paket koin di Toko (`toko_screen.dart:372` → `product.price`), harga plan di Paywall dan onboarding bila Play berhasil dimuat (`yearlyProduct.price`). Mata uang, simbol, dan `currencyCode` otomatis mengikuti negara akun Play user. Diuji untuk IDR, USD, EUR, dan string panjang 40 karakter tanpa overflow di 360dp.
- ❌ Hardcode Rupiah: lihat M-01 (fallback paywall, Langganan, Premium-Locked, `priceShort`). Juga H-02 (offer trial).
- **Region `riung.id` vs `riung.global`**: aplikasi hanya punya satu `applicationId` (`com.riung.riung`, tanpa flavor). **Tidak perlu dipecah.** Google Play sudah menampilkan mata uang lokal dari satu listing. Atur harga per negara di Play Console (Monetize → Products → *Set prices* / pricing template: IDR 59.000 untuk Indonesia, USD 4.99 sebagai dasar global). Klien cukup selalu memakai `ProductDetails.price`.

### Solusi H-02 + M-01: pemilihan offer & harga

Buat helper baru, misalnya `lib/features/toko/logic/premium_offer.dart`:

```dart
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

/// Satu plan langganan yang sudah dipilih offer-nya.
class PremiumOffer {
  const PremiumOffer({required this.purchase, required this.recurringPrice, required this.trialDays});
  final ProductDetails purchase;    // diteruskan ke buyPremium (membawa offerToken)
  final String recurringPrice;      // "Rp590.000" / "$39.99" — fase berulang
  final int? trialDays;             // null = tidak eligible trial

  /// Play hanya mengembalikan offer yang eligible untuk user ini, jadi
  /// trial yang tidak muncul berarti user sudah pernah memakainya.
  static Map<String, PremiumOffer> fromProducts(Iterable<ProductDetails> all) {
    final out = <String, PremiumOffer>{};
    for (final p in all) {
      if (p is! GooglePlayProductDetails || p.subscriptionIndex == null) continue;
      final offer = p.productDetails.subscriptionOfferDetails![p.subscriptionIndex!];
      final recurring = offer.pricingPhases.last;
      final trial = offer.pricingPhases.where((ph) => ph.priceAmountMicros == 0).firstOrNull;
      final candidate = PremiumOffer(
        purchase: p,
        recurringPrice: recurring.formattedPrice,
        trialDays: trial == null ? null : _days(trial.billingPeriod) * trial.billingCycleCount,
      );
      final current = out[p.id];
      // Utamakan offer bertrial; jika sama-sama tanpa trial, pakai base plan (offerId null).
      if (current == null || (current.trialDays == null && candidate.trialDays != null) ||
          (current.trialDays == candidate.trialDays && offer.offerId == null)) {
        out[p.id] = candidate;
      }
    }
    return out;
  }

  static int _days(String iso) { // P7D, P1W, P1M
    final m = RegExp(r'P(\d+)([DWMY])').firstMatch(iso);
    if (m == null) return 0;
    final n = int.parse(m[1]!);
    return switch (m[2]) { 'D' => n, 'W' => n * 7, 'M' => n * 30, _ => n * 365 };
  }
}
```

Di paywall:

```dart
// state: null = memuat, {} = gagal
Map<String, PremiumOffer>? _offers;

billing.queryProducts().then((res) {
  if (!mounted) return;
  setState(() => _offers = PremiumOffer.fromProducts(res.productDetails));
});

// subtitle
subtitle: switch (_offers) {
  null => '',                               // + RiungSkeleton di kartu
  final o when o[PremiumSku.yearly.productId] == null => t.priceOnPlay, // "Harga tampil di Google Play"
  final o => t.yearlyWithPrice(o[PremiumSku.yearly.productId]!.recurringPrice),
},

// CTA
final offer = _offers?[sku.productId];
label: offer?.trialDays != null ? t.tryFree(offer!.trialDays!) : t.subscribeNow,
```

Copy baru (`priceOnPlay`, `subscribeNow`, `retryPrices`) perlu disetujui dulu terhadap desain, karena aturan #2 CLAUDE.md mewajibkan copy persis sesuai desain. Hapus `yearlyFallback`/`monthlyFallback` yang berformat "Rp". Untuk `langganan_screen.dart:74`, ambil `ProductDetails` plan aktif dan tampilkan `recurringPrice`. Untuk `premium_locked_screen.dart:48`, tampilkan teks tanpa angka.

### Solusi H-01 + H-03: pending & restore tidak boleh mengunci layar

```dart
// billing_service.dart
enum RestoreOutcome { restored, none, failed }

Future<RestoreOutcome> restorePurchases() async {
  final done = Completer<RestoreOutcome>();
  _restoreWaiter = done;                       // diisi di _onPurchaseUpdate
  try {
    await _iap.restorePurchases();
  } catch (error, stack) {
    _report(error, stack, 'billing_restore_call_failed');
    _restoreWaiter = null;
    return RestoreOutcome.failed;
  }
  return done.future.timeout(const Duration(seconds: 20), onTimeout: () => RestoreOutcome.failed);
}

// di awal _onPurchaseUpdate:
final waiter = _restoreWaiter;
if (waiter != null && purchases.every((p) => p.status == PurchaseStatus.restored)) {
  _restoreWaiter = null;
  // …setelah loop selesai:
  waiter.complete(purchases.isEmpty ? RestoreOutcome.none
      : delivered > 0 ? RestoreOutcome.restored : RestoreOutcome.failed);
}
```

```dart
// paywall_premium_screen.dart / paywall_step.dart
if (update.status == BillingStatus.pending) {
  setState(() { _processing = false; _pending = true; }); // X & "Lanjut gratis" aktif lagi
  // tampilkan banner: "Pembayaranmu sedang menunggu. Premium aktif otomatis begitu lunas."
  return;
}

Future<void> _mulaiTrial() async {
  // … guard yang ada …
  setState(() => _processing = true);
  try {
    await AppScope.of(context).billing.buyPremium(product);
  } catch (e) {
    if (!mounted) return;
    setState(() => _processing = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.s.toko.billingError(BillingErrorKind.purchaseFailed, null))));
  }
}

Future<void> _pulihkanPembelian() async {
  setState(() => _processing = true);
  final outcome = await AppScope.of(context).billing.restorePurchases();
  if (!mounted) return;
  setState(() => _processing = false);
  if (outcome == RestoreOutcome.none) { /* snackbar "Belum ada pembelian untuk dipulihkan" */ }
  if (outcome == RestoreOutcome.failed) { /* snackbar "Gagal memulihkan, coba lagi" */ }
}
```

### Solusi H-04: upgrade/downgrade

```dart
Future<void> buyPremium(ProductDetails product, {GooglePlayPurchaseDetails? current}) async {
  // … guard yang ada …
  final account = (await apiState?.refresh())?.billingAccountId;
  if (account == null || account.isEmpty) throw StateError('Server billing account required');
  final param = current == null
      ? GooglePlayPurchaseParam(productDetails: product, applicationUserName: account)
      : GooglePlayPurchaseParam(
          productDetails: product,
          applicationUserName: account,
          changeSubscriptionParam: ChangeSubscriptionParam(
            oldPurchaseDetails: current,
            replacementMode: ReplacementMode.chargeProratedPrice, // upgrade
          ),
        );
  await _iap.buyNonConsumable(purchaseParam: param);
}
```

`current` diambil dari purchase `restored` terakhir (simpan di `BillingService` saat restore). Di paywall, jika `profile.premiumNow && profile.premiumPlan == sku.productId`, tampilkan "Paket aktif" alih-alih CTA beli.

### Solusi C-01: isolasi data per akun

1. **DB (migrasi v3)**:
   ```sql
   ALTER TABLE journal_entries ADD COLUMN user_id TEXT;
   ALTER TABLE checkin_history ADD COLUMN user_id TEXT;
   ```
   Isi `user_id` baris lama dengan `riung_uid` terakhir. Semua query menambahkan `WHERE user_id = ?` (`local_database_service.dart:63-88`), dan `LocalUserRepository` meneruskan `uid` yang selama ini diabaikan (`local_user_repository.dart:138, 177`).
2. **Kunci enkripsi & PIN per uid**: `journal_crypto_key_$uid`, `jurnal_pin_$uid`.
3. **Prefs per uid**: bungkus key domain-user (`_kOwnedCosmetics`, `_kPersonalityJson`, `_kKenaliResultsCipher`, `_kBetterMe*`, `_kCustomAffirmationsJson`, `_kPurchasedCoinsReserve`, `_kMissionsJson`, …) dengan `'${key}_$uid'`, sementara pengaturan perangkat (bahasa, notifikasi, App Beku) tetap global. Pola `intro_seen_v1_$uid` (`local_prefs_store.dart:83`) sudah ada untuk diikuti.
4. **Logout**: panggil `notifyListeners`/`clearSession` di semua notifier agar UI tidak menampilkan state akun lama, lalu ubah copy `signOutBody` (perlu persetujuan copy): jurnal di HP ini tetap aman dan hanya terbuka untuk akunmu.

## 6. Checklist pengujian di HP fisik

### a. Setup pembayaran tanpa uang asli

**Android (Google Play):**
1. Play Console → *Setup → License testing*: tambahkan Gmail tester dengan respons `RESPOND_NORMALLY`.
2. Unggah AAB rilis bertanda tangan ke **Internal testing**, tambahkan tester, lalu install dari link opt-in. Jangan pakai `flutter run`, karena billing butuh signature yang sama dengan yang ada di Play.
3. Tester mendapat metode pembayaran uji: *"Test card, always approves"*, *"always declines"* (skenario 4d), *"Slow test card, approves/declines after a few minutes"* (skenario 4c pending).
4. Langganan uji berjalan dipercepat (1 bulan = 5 menit, 1 tahun = 30 menit, trial 3 menit, renew maks 6×). Dengan begitu expired, grace, dan hold bisa diuji dalam satu sesi. Grace dan account hold diuji dengan mengganti kartu ke "declines" di Play Store saat langganan aktif.
5. Refund/revoke: Play Console → *Order management* → Refund, centang "Revoke". Pastikan RTDN masuk ke server dan Premium hilang setelah `/me` berikutnya.
6. **Multi-region**: harga mengikuti negara profil pembayaran akun Google. Pakai akun tester berbeda (misalnya satu dengan profil Indonesia dan satu dengan profil US/SG; country Play bisa diubah sekali per tahun), atau install di HP dengan SIM/akun dari negara itu. Cek bahwa paywall menampilkan `Rp…` atau `$…` dari Play, **tidak pernah** fallback.
7. Uji juga: Play Store belum login (paywall harus menampilkan state "gagal memuat + coba lagi", bukan Rupiah palsu) dan mode pesawat saat membuka paywall.

**iOS:** belum layak diuji (M-04). Saat cabang StoreKit sudah dibuat: App Store Connect → *Users and Access → Sandbox Testers*, atur region tester per negara, install via TestFlight, lalu di HP buka *Settings → App Store → Sandbox Account*. Uji *Ask to Buy* untuk skenario pending.

### b. Lifecycle

| Skenario | Langkah | Ekspektasi |
|---|---|---|
| Telepon masuk saat sheet Play terbuka | Tap beli, lalu terima telepon, lalu kembali ke app | Sheet Play tetap terbuka atau dibatalkan dengan status `canceled`; layar tidak macet |
| Layar dikunci saat "Memproses..." | Kunci HP 30 dtk, lalu buka | `resumed` memicu `bootstrap()`; status akhirnya muncul |
| App di-minimize saat verify | Beli, lalu langsung Home | Pembelian tetap di-verify di background; jika gagal, dipulihkan saat app dibuka (restore otomatis setelah `/me`) |
| **OS kill** setelah bayar sebelum verify | Developer options → *Don't keep activities* / `adb shell am kill com.riung.riung` setelah sheet sukses | Saat dibuka lagi: restore otomatis, verify, Premium/koin masuk tepat sekali (`autoConsume:false` menjamin pembelian tidak hilang) |
| Offline di tengah check-in/jurnal | Mode pesawat, lakukan aksi, online | Event masuk outbox dan terkirim saat konektivitas kembali; koin tidak dobel (Idempotency) |
| Pindah akun | Akun A: tulis jurnal, logout, login akun B | **Saat ini gagal (C-01)**: B tidak boleh melihat jurnal A |
| Pending Indomaret | Slow test card, lalu tutup app, lalu tunggu approve | Pending tidak membuka Pro; setelah lunas Pro aktif tanpa restart. **Saat ini UI macet (H-01)** |

### c. Layar, perangkat, performa

- Ukuran: 360×640 dp (target CLAUDE.md), 412×915, tablet 800dp. Font scale 1.0 / 1.3 / 2.0 (*Settings → Display → Font size*). Perhatikan L-02.
- Notch / punch-hole / gesture nav: semua layar memakai `SafeArea`; cek tombol CTA paywall tidak tertutup gesture bar, terutama di layar dengan 3-button nav.
- Dark mode: tema hanya `AppTheme.light` (`main.dart:398`). Pastikan sistem dark mode tidak merusak teks (tidak ada `darkTheme`, jadi tetap terang, dan itu konsisten).
- Izin: notifikasi (Android 13+ `POST_NOTIFICATIONS`), Usage Access + overlay (App Beku; memori `app-lock-design`), biometrik jurnal. Uji tolak, lalu izinkan dari Settings, lalu kembali ke app.
- Performa HP 2–4 GB (mis. Redmi 9A/A-series): `flutter run --profile`. Pantau jank di Home, Monster, dan Paywall (3D WebP + kaca blur). Cek memori via Android Studio Profiler (<250 MB). Gambar sudah di-decode seukuran tampil (`cacheWidth`); cek tidak ada OOM saat membuka galeri monster berulang.

## 7. Automated test yang ditambahkan

`riung/test/audit_billing_api_test.dart` (35 test):
- IAP: pending, lunas setelah pending, cancel, kartu ditolak, 409, 5xx dengan retry, server pending, guard anonim.
- Restore: sukses, tanpa riwayat (REPRO H-03), error Play (REPRO H-03), lintas akun (REPRO M-05), offline.
- Produk/harga: harga dinamis IDR/USD/EUR, offer collapse (REPRO H-02), tanpa upgrade param (REPRO H-04), `/me` gagal saat beli (REPRO H-01), Play tidak tersedia.
- Entitlement: active, renewsSoon, grace, expired, manipulasi jam (REPRO M-02).
- API: header, 400, 401 refresh, 401 gagal, 403/404, 429, 5xx dengan key sama, timeout/offline, JSON rusak, code non-string (REPRO L-01), pindah akun saat retry, wajib HTTPS.
- Pindah akun: snapshot ter-scope, prefs bocor (REPRO C-01), jurnal tidak ter-scope (REPRO C-01).

`riung/test/audit_paywall_widget_test.dart` (9 widget test, 360dp):
- Overflow baris link (REPRO L-02).
- Harga Rupiah saat loading dan saat Play gagal (REPRO M-01).
- Harga Play untuk ID, US, IN, dan string 40 karakter: tampil apa adanya tanpa overflow di kartu harga.
- Pending mengunci X (REPRO H-01).
- Restore kosong macet (REPRO H-03).

Urutan perbaikan yang disarankan: C-01 → H-01/H-03 (satu PR billing UX) → H-02/M-01 (satu PR harga/offer) → H-04 → H-05 → Medium lainnya.
