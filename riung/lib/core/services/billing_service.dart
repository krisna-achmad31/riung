import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';

import '../config/economy.dart';
import 'firebase/analytics_service.dart';
import 'user_repository.dart';
import 'wallet_functions_service.dart';

/// SKU koin (consumable) — jumlah koin dikreditkan lewat
/// [WalletFunctionsService.earnCoins], harus cocok dengan daftar earn yang
/// sah di `firestore.rules` (isValidWalletDelta). Nilai koin & harga IDR
/// bersumber dari `lib/core/config/economy.dart` § EconomyCoinPacks.
enum CoinPackSku {
  small('coin_pack_small', EconomyCoinPacks.kantong),
  medium('coin_pack_medium', EconomyCoinPacks.peti),
  large('coin_pack_large', EconomyCoinPacks.brankas);

  const CoinPackSku(this.productId, this.pack);
  final String productId;
  final CoinPack pack;
  int get totalCoins => pack.totalCoins;
  int get priceIdr => pack.priceIdr;
}

enum PremiumSku {
  monthly('premium_monthly', 30, EconomyPremium.hargaBulananIdr),
  yearly('premium_yearly', 365, EconomyPremium.hargaTahunanIdr);

  const PremiumSku(this.productId, this.durationDays, this.priceIdr);
  final String productId;
  final int durationDays;
  final int priceIdr;
}

enum BillingStatus { pending, success, error, canceled }

/// Jenis kegagalan pembelian — UI menerjemahkannya sesuai bahasa aktif lewat
/// `TokoStrings.billingError` (layer ini tidak membuat kalimat sendiri).
enum BillingErrorKind { purchaseFailed, deliveryFailed }

class BillingUpdate {
  const BillingUpdate({required this.productId, required this.status, this.errorKind, this.detail});
  final String productId;
  final BillingStatus status;
  final BillingErrorKind? errorKind;

  /// Pesan mentah dari Google Play (sudah dilokalisasi oleh Play) — cuma
  /// terisi untuk [BillingErrorKind.purchaseFailed].
  final String? detail;
}

/// Integrasi Google Play Billing lewat `in_app_purchase`. Alur: tap beli →
/// Play sheet (native) → status `purchased` masuk lewat [purchaseStream] →
/// [completePurchase] (ini yang memicu `acknowledgePurchase` di sisi Play)
/// → kredit koin/aktifkan Premium lewat service yang sama dipakai fitur
/// lain, supaya tunduk pada validasi delta `firestore.rules` yang sama.
///
/// CATATAN KEAMANAN: di Spark plan (tanpa Cloud Functions) tidak ada
/// verifikasi *server-side* atas token pembelian ke Google Play Developer
/// API — status `purchased` di sini murni hasil laporan Play Billing
/// Library on-device. Ini cukup untuk pengembangan/rilis awal, tapi
/// idealnya diverifikasi ulang server-side (Cloud Functions, Blaze plan)
/// sebelum benar-benar mengandalkan ini untuk transaksi bernilai besar.
/// Detail di `docs/setup-firebase.md`.
class BillingService {
  BillingService({
    required WalletFunctionsService walletFunctions,
    required UserRepository userRepository,
    required String Function() currentUid,
    required AnalyticsService analytics,
    required bool Function() isAnonymous,
    this.onCoinsPurchased,
    InAppPurchase? iap,
  })  : _walletFunctions = walletFunctions,
        _userRepository = userRepository,
        _currentUid = currentUid,
        _analytics = analytics,
        _isAnonymous = isAnonymous,
        _iap = iap ?? InAppPurchase.instance;

  final WalletFunctionsService _walletFunctions;
  final UserRepository _userRepository;
  final String Function() _currentUid;
  final AnalyticsService _analytics;
  final bool Function() _isAnonymous;
  final InAppPurchase _iap;

  /// Dipanggil setelah paket koin terverifikasi & dikreditkan — dipakai
  /// `WalletNotifier` untuk melacak koin beli vs koin hasil latihan.
  final void Function(int totalCoins)? onCoinsPurchased;

  static const allProductIds = {
    'coin_pack_small',
    'coin_pack_medium',
    'coin_pack_large',
    'premium_monthly',
    'premium_yearly',
  };

  StreamSubscription<List<PurchaseDetails>>? _subscription;
  final _updatesController = StreamController<BillingUpdate>.broadcast();

  /// Emit tiap kali status satu pembelian berubah — Toko screen dengarkan
  /// ini untuk menampilkan loading/sukses/gagal.
  Stream<BillingUpdate> get updates => _updatesController.stream;

  Future<bool> init() async {
    try {
      final available = await _iap.isAvailable();
      if (!available) return false;
      _subscription = _iap.purchaseStream.listen(_onPurchaseUpdate, onError: (_) {});
      // Cek langganan yang mungkin sudah aktif dari sesi sebelumnya (mis.
      // habis install ulang) — hasilnya juga lewat purchaseStream di atas.
      unawaited(_iap.restorePurchases());
      return true;
    } catch (_) {
      // Play services tidak tersedia (emulator tanpa Play Store, dsb) atau
      // plugin belum siap (mis. widget test) — toko cuma tidak aktif,
      // bukan crash.
      return false;
    }
  }

  Future<ProductDetailsResponse> queryProducts() => _iap.queryProductDetails(allProductIds);

  /// Poin 2 — jaring pengaman lapis kedua. UI (lihat
  /// `ensureAccountForPurchase`) sudah harus mencegah ini tercapai dalam
  /// keadaan anonim; kalau tetap tercapai berarti ada titik panggil baru
  /// yang lupa pasang guard-nya di layar.
  Future<void> buyCoinPack(ProductDetails product) {
    if (_isAnonymous()) {
      throw StateError('buyCoinPack dipanggil selagi masih anonim — pasang ensureAccountForPurchase() di UI pemanggil.');
    }
    return _iap.buyConsumable(purchaseParam: PurchaseParam(productDetails: product));
  }

  Future<void> buyPremium(ProductDetails product) {
    if (_isAnonymous()) {
      throw StateError('buyPremium dipanggil selagi masih anonim — pasang ensureAccountForPurchase() di UI pemanggil.');
    }
    return _iap.buyNonConsumable(purchaseParam: PurchaseParam(productDetails: product));
  }

  Future<void> restorePurchases() => _iap.restorePurchases();

  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          _updatesController.add(BillingUpdate(productId: purchase.productID, status: BillingStatus.pending));
        case PurchaseStatus.error:
          _updatesController.add(BillingUpdate(
            productId: purchase.productID,
            status: BillingStatus.error,
            errorKind: BillingErrorKind.purchaseFailed,
            detail: purchase.error?.message,
          ));
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
        case PurchaseStatus.canceled:
          _updatesController.add(BillingUpdate(productId: purchase.productID, status: BillingStatus.canceled));
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          try {
            await _deliver(purchase);
            _updatesController.add(BillingUpdate(productId: purchase.productID, status: BillingStatus.success));
          } catch (e) {
            _updatesController.add(BillingUpdate(
              productId: purchase.productID,
              status: BillingStatus.error,
              errorKind: BillingErrorKind.deliveryFailed,
            ));
          }
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
      }
    }
  }

  Future<void> _deliver(PurchaseDetails purchase) async {
    final uid = _currentUid();

    final coinPack = CoinPackSku.values.where((s) => s.productId == purchase.productID).firstOrNull;
    if (coinPack != null) {
      await _walletFunctions.earnCoins(
        uid: uid,
        amount: coinPack.totalCoins,
        reason: 'purchase:${purchase.productID}',
      );
      onCoinsPurchased?.call(coinPack.totalCoins);
      await _analytics.purchase(productId: coinPack.productId, valueIdr: coinPack.priceIdr);
      return;
    }

    final premium = PremiumSku.values.where((s) => s.productId == purchase.productID).firstOrNull;
    if (premium != null) {
      final profile = await _userRepository.getUserProfile(uid);
      final renewsAt = DateTime.now().add(Duration(days: premium.durationDays));
      await _userRepository.saveUserProfile(
        profile.copyWith(premiumActive: true, premiumPlan: purchase.productID, premiumRenewsAt: renewsAt),
      );
      await _analytics.purchase(productId: premium.productId, valueIdr: premium.priceIdr);
    }
  }

  void dispose() {
    _subscription?.cancel();
    _updatesController.close();
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
