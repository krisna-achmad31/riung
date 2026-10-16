import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'api/api_state.dart';
import 'api/api_client.dart';
import 'api/riung_api.dart';

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

/// Google Play purchases are verified by the backend before consumption or
/// acknowledgement. Failed delivery remains recoverable through Play restore.
class BillingService {
  BillingService({
    required WalletFunctionsService walletFunctions,
    required UserRepository userRepository,
    required String Function() currentUid,
    required AnalyticsService analytics,
    required bool Function() isAnonymous,
    this.onCoinsPurchased,
    InAppPurchase? iap,
    this.apiState,
  })  : _analytics = analytics,
        _isAnonymous = isAnonymous,
        _iap = iap ?? InAppPurchase.instance;

  final AnalyticsService _analytics;
  final bool Function() _isAnonymous;
  final InAppPurchase _iap;
  final ApiState? apiState;

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
  Future<void> _processing = Future.value();
  final Set<String> _consumed = {};
  final _updatesController = StreamController<BillingUpdate>.broadcast();

  /// Emit tiap kali status satu pembelian berubah — Toko screen dengarkan
  /// ini untuk menampilkan loading/sukses/gagal.
  Stream<BillingUpdate> get updates => _updatesController.stream;

  Future<bool> init() async {
    try {
      final available = await _iap.isAvailable();
      if (!available) return false;
      _subscription = _iap.purchaseStream.listen((purchases) {
        _processing = _processing.then((_) => _onPurchaseUpdate(purchases)).catchError((Object _) {});
      }, onError: (_) {});
      // The app restores after /me bootstrap so receipts have an authenticated
      // server billing account, including when signing in after launch.
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
  Future<void> buyCoinPack(ProductDetails product) async {
    if (_isAnonymous()) {
      throw StateError('buyCoinPack dipanggil selagi masih anonim — pasang ensureAccountForPurchase() di UI pemanggil.');
    }
    final account = (await apiState?.refresh())?.billingAccountId;
    if (account == null || account.isEmpty) throw StateError('Server billing account required');
    await _iap.buyConsumable(purchaseParam: PurchaseParam(productDetails: product, applicationUserName: account), autoConsume: false);
  }

  Future<void> buyPremium(ProductDetails product) async {
    if (_isAnonymous()) {
      throw StateError('buyPremium dipanggil selagi masih anonim — pasang ensureAccountForPurchase() di UI pemanggil.');
    }
    final account = (await apiState?.refresh())?.billingAccountId;
    if (account == null || account.isEmpty) throw StateError('Server billing account required');
    await _iap.buyNonConsumable(purchaseParam: PurchaseParam(productDetails: product, applicationUserName: account));
  }

  Future<void> restorePurchases() => _iap.restorePurchases();

  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    final restored = purchases.where((p) => p.status == PurchaseStatus.restored).toList();
    final restoredResults = <String, BillingResult>{};
    if (restored.isNotEmpty && apiState != null) {
      try {
        for (var offset = 0; offset < restored.length; offset += 20) {
          final chunk = restored.skip(offset).take(20).toList();
          final response = await apiState!.api.restore(chunk.map((p) => (productId: p.productID, purchaseToken: p.verificationData.serverVerificationData)).toList());
          final results = response['results'] as List? ?? [];
          for (var i = 0; i < results.length && i < chunk.length; i++) {
            final row = jsonObject(results[i]);
            if (row['error'] != null) continue;
            restoredResults[chunk[i].verificationData.serverVerificationData] = BillingResult(row['result'] is Map ? jsonObject(row['result']) : row);
          }
        }
      } catch (_) {
        for (final p in restored) {
          _updatesController.add(BillingUpdate(productId: p.productID, status: BillingStatus.error, errorKind: BillingErrorKind.deliveryFailed));
        }
        // Never consume or acknowledge a restore that failed verification.
        purchases = purchases.where((p) => p.status != PurchaseStatus.restored).toList();
      }
    }
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
            if (purchase.status == PurchaseStatus.restored && !restoredResults.containsKey(purchase.verificationData.serverVerificationData)) continue;
            final delivered = await _deliver(purchase, restoredResult: restoredResults[purchase.verificationData.serverVerificationData]);
            if (!delivered) continue;
            _updatesController.add(BillingUpdate(productId: purchase.productID, status: BillingStatus.success));
          } catch (e) {
            _updatesController.add(BillingUpdate(
              productId: purchase.productID,
              status: BillingStatus.error,
              errorKind: BillingErrorKind.deliveryFailed,
            ));
          }
      }
    }
  }

  Future<bool> _deliver(PurchaseDetails purchase, {BillingResult? restoredResult}) async {
    final state = apiState;
    if (state == null) throw StateError('Server verification required');
    final result = restoredResult ?? await state.api.verifyPurchase(purchase.productID, purchase.verificationData.serverVerificationData);
    if (result.status == 'pending') return false;
    if (result.consumableDelivered) {
      final token = purchase.verificationData.serverVerificationData;
      if (!_consumed.contains(token)) {
        final consumed = await _iap.getPlatformAddition<InAppPurchaseAndroidPlatformAddition>().consumePurchase(purchase);
        if (consumed.responseCode != BillingResponse.ok) throw StateError('Google Play consumption failed');
        _consumed.add(token);
      }
    } else if (result.subscriptionVerified) {
      if (purchase.pendingCompletePurchase) await _iap.completePurchase(purchase);
    } else {
      throw const ApiException(502, 'invalid_response', 'Unknown billing status');
    }
    await state.refresh();
    final coin = CoinPackSku.values.where((s) => s.productId == purchase.productID);
    final premium = PremiumSku.values.where((s) => s.productId == purchase.productID);
    if (purchase.status == PurchaseStatus.purchased) await _analytics.purchase(productId: purchase.productID,
      valueIdr: coin.isNotEmpty ? coin.first.priceIdr : premium.isNotEmpty ? premium.first.priceIdr : 0);
    return true;
  }

  void dispose() {
    _subscription?.cancel();
    _updatesController.close();
  }
}
