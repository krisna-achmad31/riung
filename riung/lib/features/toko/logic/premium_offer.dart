import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

import '../../../core/services/billing_service.dart';

/// Satu plan langganan Premium yang offer-nya sudah dipilih secara eksplisit.
///
/// Plugin Android memecah satu produk langganan jadi satu [ProductDetails]
/// per offer (base plan, trial 7 hari, …) dengan `id` yang sama — map
/// `{p.id: p}` biasa hanya menyimpan item terakhir, sehingga harga bisa
/// tampil "Gratis/tahun" dan offer yang dibeli bergantung urutan Play.
class PremiumOffer {
  const PremiumOffer({required this.purchase, required this.recurringPrice, required this.trialDays});

  /// Diteruskan ke `BillingService.buyPremium` (membawa `offerToken`).
  final ProductDetails purchase;

  /// Harga fase berulang ("Rp590.000", "$39.99"), bukan harga fase trial.
  final String recurringPrice;

  /// null = user ini tidak eligible trial (Play hanya mengembalikan offer
  /// yang eligible, jadi trial yang tidak muncul berarti sudah pernah dipakai;
  /// App Store dicek lewat `BillingService.appStoreTrialDays`).
  final int? trialDays;

  bool get hasTrial => trialDays != null;

  /// Map productId → offer terpilih. Utamakan offer bertrial; bila sama-sama
  /// tanpa trial, pakai base plan (offerId null). [appStoreTrialDays]: lama
  /// trial per produk App Store (satu harga per produk, tanpa offer terpisah).
  static Map<String, PremiumOffer> fromProducts(Iterable<ProductDetails> all, {Map<String, int> appStoreTrialDays = const {}}) {
    final out = <String, PremiumOffer>{};
    final isBasePlan = <String, bool>{};
    for (final p in all) {
      final PremiumOffer candidate;
      final bool base;
      final index = p is GooglePlayProductDetails ? p.subscriptionIndex : null;
      final offers = p is GooglePlayProductDetails ? p.productDetails.subscriptionOfferDetails : null;
      if (index != null && offers != null && index < offers.length && offers[index].pricingPhases.isNotEmpty) {
        final offer = offers[index];
        final trial = offer.pricingPhases.where((ph) => ph.priceAmountMicros == 0).firstOrNull;
        final trialDays = trial == null ? 0 : _days(trial.billingPeriod) * trial.billingCycleCount;
        candidate = PremiumOffer(
          purchase: p,
          recurringPrice: offer.pricingPhases.last.formattedPrice,
          trialDays: trialDays > 0 ? trialDays : null,
        );
        base = offer.offerId == null;
      } else {
        // Bukan langganan Play Billing v5+ (mis. App Store): satu harga.
        candidate = PremiumOffer(purchase: p, recurringPrice: p.price, trialDays: appStoreTrialDays[p.id]);
        base = true;
      }
      final current = out[p.id];
      final better = current == null ||
          (!current.hasTrial && candidate.hasTrial) ||
          (current.hasTrial == candidate.hasTrial && base && !(isBasePlan[p.id] ?? false));
      if (better) {
        out[p.id] = candidate;
        isBasePlan[p.id] = base;
      }
    }
    return out;
  }

  /// Muat offer dari toko. Tidak pernah throw: toko gagal → map kosong.
  static Future<Map<String, PremiumOffer>> load(BillingService billing) async {
    final products = (await billing.queryProducts()).productDetails;
    return fromProducts(products, appStoreTrialDays: await billing.appStoreTrialDays(products));
  }

  /// Durasi ISO-8601 Play (P7D, P1W, P1M, P1Y) → hari.
  static int _days(String iso) {
    final m = RegExp(r'P(\d+)([DWMY])').firstMatch(iso);
    if (m == null) return 0;
    final n = int.parse(m[1]!);
    return switch (m[2]) { 'D' => n, 'W' => n * 7, 'M' => n * 30, _ => n * 365 };
  }
}
