import 'dart:async';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
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

/// Hasil "Pulihkan pembelian": [none] = akun Play ini tidak punya pembelian,
/// [failed] = Play/server gagal atau tidak menjawab (boleh dicoba lagi),
/// [otherAccount] = langganan di Play ini milik akun Riung lain.
enum RestoreOutcome { restored, none, failed, otherAccount }

/// Jenis kegagalan pembelian — UI menerjemahkannya sesuai bahasa aktif lewat
/// `TokoStrings.billingError` (layer ini tidak membuat kalimat sendiri).
/// [otherAccount] = server menolak langganan yang dipulihkan karena terikat
/// ke akun Riung lain (`purchase_invalid` pada baris restore).
enum BillingErrorKind { purchaseFailed, deliveryFailed, otherAccount }

class BillingUpdate {
  const BillingUpdate({required this.productId, required this.status, this.errorKind, this.detail});
  final String productId;
  final BillingStatus status;
  final BillingErrorKind? errorKind;

  /// Pesan mentah dari Google Play (sudah dilokalisasi oleh Play) — cuma
  /// terisi untuk [BillingErrorKind.purchaseFailed].
  final String? detail;
}

/// Google Play & App Store purchases are verified by the backend before
/// consumption, acknowledgement or StoreKit `finish()`. Failed delivery
/// remains recoverable through restore (Play) or StoreKit re-delivering the
/// unfinished transaction on the next launch (App Store).
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
    bool? appStore,
  })  : _analytics = analytics,
        _isAnonymous = isAnonymous,
        _iap = iap ?? InAppPurchase.instance,
        appStore = appStore ?? defaultTargetPlatform == TargetPlatform.iOS;

  final AnalyticsService _analytics;
  final bool Function() _isAnonymous;
  final InAppPurchase _iap;
  final ApiState? apiState;

  /// true = StoreKit (iOS): akun lewat `appAccountToken`, verifikasi ke
  /// `/v1/billing/appstore/*` dengan `transactionId`, selesai lewat
  /// `completePurchase`. false = Google Play.
  final bool appStore;

  /// Dipanggil setelah paket koin terverifikasi & dikreditkan — dipakai
  /// `WalletNotifier` untuk melacak koin beli vs koin hasil latihan.
  final void Function(int totalCoins)? onCoinsPurchased;

  /// Batas pembelian per panggilan `/v1/billing/restore` &
  /// `/v1/billing/appstore/restore`.
  static const restoreChunkSize = 20;

  static const allProductIds = {
    'coin_pack_small',
    'coin_pack_medium',
    'coin_pack_large',
    'premium_monthly',
    'premium_yearly',
  };

  /// Batas tunggu jawaban Play setelah `restorePurchases` — Play tidak
  /// menjamin selalu memancarkan update, jadi UI tidak boleh menunggu
  /// selamanya.
  static const restoreTimeout = Duration(seconds: 20);

  StreamSubscription<List<PurchaseDetails>>? _subscription;
  Future<void> _processing = Future.value();
  Completer<RestoreOutcome>? _restoreWaiter;

  /// Langganan Premium yang terakhir terverifikasi di HP ini (dari restore
  /// atau pembelian) — dipakai sebagai `oldPurchaseDetails` saat pindah plan
  /// (hanya Play; App Store mengganti plan dalam satu subscription group).
  GooglePlayPurchaseDetails? _activeSubscription;
  final Set<String> _consumed = {};
  final _updatesController = StreamController<BillingUpdate>.broadcast();

  /// Emit tiap kali status satu pembelian berubah — Toko screen dengarkan
  /// ini untuk menampilkan loading/sukses/gagal.
  Stream<BillingUpdate> get updates => _updatesController.stream;

  /// false bila Play Billing tidak siap (emulator tanpa Play Store, Play
  /// Services mati, plugin belum siap). Toko tetap tampil; tombol beli
  /// memberi tahu paket belum tersedia ([queryProducts] kosong).
  bool get available => _available;
  bool _available = false;

  Future<bool> init() async {
    try {
      final available = await _iap.isAvailable();
      if (!available) return false;
      _subscription = _iap.purchaseStream.listen((purchases) {
        // Jawaban restore = daftar yang semuanya `restored` (boleh kosong).
        final pendingRestore = _restoreWaiter;
        final waiter = pendingRestore != null && purchases.every((p) => p.status == PurchaseStatus.restored) ? pendingRestore : null;
        if (waiter != null) _restoreWaiter = null;
        _processing = _processing.then((_) async {
          final result = await _onPurchaseUpdate(purchases);
          if (waiter != null && !waiter.isCompleted) {
            waiter.complete(switch (result) {
              _ when purchases.isEmpty => RestoreOutcome.none,
              (delivered: > 0, otherAccount: _) => RestoreOutcome.restored,
              (delivered: _, otherAccount: true) => RestoreOutcome.otherAccount,
              _ => RestoreOutcome.failed,
            });
          }
        }).catchError((Object error, StackTrace stack) {
          // Jangan menelan diam-diam: pembelian yang belum terproses tetap
          // tertunda di Play & dipulihkan lewat restore berikutnya.
          _report(error, stack, 'billing_update_failed');
          for (final p in purchases) {
            _updatesController.add(BillingUpdate(productId: p.productID, status: BillingStatus.error, errorKind: BillingErrorKind.deliveryFailed));
          }
          if (waiter != null && !waiter.isCompleted) waiter.complete(RestoreOutcome.failed);
        });
      }, onError: (Object error, StackTrace stack) => _report(error, stack, 'billing_stream_error'));
      _available = true;
      // The app restores after /me bootstrap so receipts have an authenticated
      // server billing account, including when signing in after launch.
      return true;
    } catch (error, stack) {
      // Play services tidak tersedia (emulator tanpa Play Store, dsb) atau
      // plugin belum siap (mis. widget test) — toko cuma tidak aktif,
      // bukan crash.
      _report(error, stack, 'billing_init_failed');
      return false;
    }
  }

  void _report(Object error, StackTrace stack, String reason) {
    try {
      FirebaseCrashlytics.instance.recordError(error, stack, reason: reason);
    } catch (_) {
      // Tanpa Firebase (test) — cukup diabaikan.
    }
  }

  /// Tidak pernah throw: tanpa Play Billing hasilnya daftar kosong, dan
  /// layar Toko/Paywall menampilkan "paket belum tersedia" saat ditap.
  Future<ProductDetailsResponse> queryProducts() async {
    if (!_available) return _emptyProducts('unavailable');
    try {
      return await _iap.queryProductDetails(allProductIds);
    } catch (error, stack) {
      _report(error, stack, 'billing_query_failed');
      return _emptyProducts('$error');
    }
  }

  static ProductDetailsResponse _emptyProducts(String message) => ProductDetailsResponse(
        productDetails: const [],
        notFoundIDs: allProductIds.toList(),
        error: IAPError(source: 'google_play', code: 'unavailable', message: message),
      );

  /// Poin 2 — jaring pengaman lapis kedua. UI (lihat
  /// `ensureAccountForPurchase`) sudah harus mencegah ini tercapai dalam
  /// keadaan anonim; kalau tetap tercapai berarti ada titik panggil baru
  /// yang lupa pasang guard-nya di layar.
  Future<void> buyCoinPack(ProductDetails product) async {
    if (_isAnonymous()) {
      throw StateError('buyCoinPack dipanggil selagi masih anonim — pasang ensureAccountForPurchase() di UI pemanggil.');
    }
    final account = _storeAccount(await apiState?.refresh());
    final param = PurchaseParam(productDetails: product, applicationUserName: account);
    // StoreKit menolak autoConsume: false; koin baru "terpakai" saat
    // completePurchase setelah server mengkredit. Play wajib false supaya
    // pembelian tidak di-consume sebelum diverifikasi.
    final launched = appStore
        ? await _iap.buyConsumable(purchaseParam: param)
        : await _iap.buyConsumable(purchaseParam: param, autoConsume: false);
    // Tanpa sheet toko tidak akan ada update di stream — UI harus tahu.
    if (!launched) throw StateError('Store purchase flow not launched');
  }

  /// `appAccountToken` (App Store) atau `billingAccountId` (Play) dari
  /// `GET /v1/me` — server menolak pembelian tanpa penanda akun ini.
  String _storeAccount(ApiSnapshot? me) {
    final account = appStore ? me?.appAccountToken : me?.billingAccountId;
    if (account == null || account.isEmpty) throw StateError('Server billing account required');
    return account;
  }

  /// Beli atau pindah plan Premium. Bila server menyatakan akun ini sudah
  /// Premium di plan lain, pembelian dikirim sebagai penggantian langganan
  /// (`ChangeSubscriptionParam`) supaya Play tidak membuat langganan kedua
  /// yang tertagih ganda. Plan yang sama tidak bisa dibeli dua kali.
  Future<void> buyPremium(ProductDetails product) async {
    if (_isAnonymous()) {
      throw StateError('buyPremium dipanggil selagi masih anonim — pasang ensureAccountForPurchase() di UI pemanggil.');
    }
    final me = await apiState?.refresh();
    final account = _storeAccount(me);
    final activePlan = me!.activePremiumPlan;
    if (activePlan == product.id) throw StateError('Plan $activePlan sudah aktif');
    if (appStore) {
      // Bulanan ↔ tahunan di satu subscription group: App Store sendiri
      // yang mengganti plan tanpa tagihan ganda.
      final launched = await _iap.buyNonConsumable(purchaseParam: PurchaseParam(productDetails: product, applicationUserName: account));
      if (!launched) throw StateError('App Store purchase flow not launched');
      return;
    }
    ChangeSubscriptionParam? change;
    if (activePlan != null) {
      if (_activeSubscription?.productID != activePlan) await restorePurchases();
      final current = _activeSubscription;
      if (current == null || current.productID != activePlan) {
        throw StateError('Langganan aktif $activePlan tidak ditemukan di akun Play ini');
      }
      // withTimeProration berlaku untuk dua arah (bulanan ↔ tahunan); harga
      // per bulan tahunan lebih murah, jadi chargeProratedPrice ditolak Play.
      change = ChangeSubscriptionParam(oldPurchaseDetails: current, replacementMode: ReplacementMode.withTimeProration);
    }
    final launched = await _iap.buyNonConsumable(
      purchaseParam: GooglePlayPurchaseParam(productDetails: product, applicationUserName: account, changeSubscriptionParam: change),
    );
    if (!launched) throw StateError('Google Play purchase flow not launched');
  }

  /// Tidak pernah throw. Selesai saat toko menjawab (termasuk daftar
  /// kosong), saat Play melempar error, atau setelah [restoreTimeout].
  Future<RestoreOutcome> restorePurchases() async {
    final pending = _restoreWaiter;
    if (pending != null) return pending.future;
    final waiter = Completer<RestoreOutcome>();
    _restoreWaiter = waiter;
    try {
      await _iap.restorePurchases();
    } catch (error, stack) {
      _report(error, stack, 'billing_restore_call_failed');
      if (identical(_restoreWaiter, waiter)) _restoreWaiter = null;
      if (!waiter.isCompleted) waiter.complete(RestoreOutcome.failed);
    }
    return waiter.future.timeout(restoreTimeout, onTimeout: () {
      if (identical(_restoreWaiter, waiter)) _restoreWaiter = null;
      return RestoreOutcome.failed;
    });
  }

  /// Mengembalikan jumlah pembelian yang berhasil diverifikasi & diterima,
  /// dan apakah ada langganan yang ditolak karena milik akun Riung lain.
  Future<({int delivered, bool otherAccount})> _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    var deliveredCount = 0;
    var otherAccount = false;
    final restored = purchases.where((p) => p.status == PurchaseStatus.restored).toList();
    final restoredResults = <String, BillingResult>{};
    if (restored.isNotEmpty && apiState != null) {
      // Per chunk: satu chunk gagal tidak membatalkan chunk lain yang
      // sudah terverifikasi (pemulihan parsial). Chunk gagal dicoba ulang
      // sekali; sisanya tetap tertunda di Play untuk restore berikutnya.
      for (var offset = 0; offset < restored.length; offset += restoreChunkSize) {
        final chunk = restored.skip(offset).take(restoreChunkSize).toList();
        for (var attempt = 0; attempt < 2; attempt++) {
          try {
            final response = appStore
                ? await apiState!.api.restoreAppStore(chunk.map((p) => (productId: p.productID, transactionId: _purchaseKey(p))).toList())
                : await apiState!.api.restore(chunk.map((p) => (productId: p.productID, purchaseToken: _purchaseKey(p))).toList());
            final results = response['results'] as List? ?? [];
            for (final (i, raw) in results.indexed) {
              final row = jsonObject(raw);
              final purchase = _restoreRowPurchase(row, i, chunk, results.length, appStore: appStore);
              if (purchase == null) continue;
              if (row['error'] != null) {
                final code = jsonObject(row['error'])['code'];
                if (code == 'purchase_invalid' && PremiumSku.values.any((s) => s.productId == purchase.productID)) {
                  otherAccount = true;
                  _updatesController.add(BillingUpdate(productId: purchase.productID, status: BillingStatus.error, errorKind: BillingErrorKind.otherAccount));
                }
                continue;
              }
              restoredResults[_purchaseKey(purchase)] = BillingResult(row['result'] is Map ? jsonObject(row['result']) : row);
            }
            break;
          } catch (error, stack) {
            if (attempt == 0 && error is ApiException && error.retryable) continue;
            _report(error, stack, 'billing_restore_failed');
            _logApiError('restore', error);
            for (final p in chunk) {
              _updatesController.add(BillingUpdate(productId: p.productID, status: BillingStatus.error, errorKind: BillingErrorKind.deliveryFailed));
            }
            break;
          }
        }
      }
      // Never consume or acknowledge a restore that failed verification:
      // restored purchases without a verified result are skipped below.
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
            if (purchase.status == PurchaseStatus.restored && !restoredResults.containsKey(_purchaseKey(purchase))) continue;
            final delivered = await _deliver(purchase, restoredResult: restoredResults[_purchaseKey(purchase)]);
            if (!delivered) continue;
            deliveredCount++;
            if (purchase is GooglePlayPurchaseDetails && PremiumSku.values.any((s) => s.productId == purchase.productID)) {
              _activeSubscription = purchase;
            }
            _updatesController.add(BillingUpdate(productId: purchase.productID, status: BillingStatus.success));
          } catch (error, stack) {
            // Jangan ditelan: catat (termasuk requestId server) lalu tampilkan
            // gagal. Transaksi tidak diselesaikan sehingga tetap bisa dipulihkan.
            _report(error, stack, 'billing_verify_failed');
            _logApiError('verify ${purchase.productID}', error);
            _updatesController.add(BillingUpdate(
              productId: purchase.productID,
              status: BillingStatus.error,
              errorKind: BillingErrorKind.deliveryFailed,
            ));
          }
      }
    }
    return (delivered: deliveredCount, otherAccount: otherAccount);
  }

  /// Penanda transaksi yang dikirim ke server: `purchaseToken` (Play) atau
  /// `transactionId` StoreKit = `PurchaseDetails.purchaseID` (App Store).
  String _purchaseKey(PurchaseDetails p) =>
      appStore ? p.purchaseID ?? '' : p.verificationData.serverVerificationData;

  void _logApiError(String what, Object error) {
    if (error is ApiException) {
      debugPrint('billing $what failed: ${error.status} ${error.code} requestId=${error.requestId}');
    }
  }

  /// Baris hasil restore dicocokkan lewat `purchaseToken` (Play) atau
  /// `transactionId` (App Store) — server boleh menghilangkan/mengurutkan
  /// ulang baris. Indeks hanya dipakai bila server tidak mengirim penanda
  /// DAN jumlah baris sama persis — selain itu baris diabaikan (pembelian
  /// tetap tertunda di toko) daripada ack/consume jatuh ke pembelian yang salah.
  static PurchaseDetails? _restoreRowPurchase(Map<String, dynamic> row, int index, List<PurchaseDetails> chunk, int rowCount, {bool appStore = false}) {
    final field = appStore ? 'transactionId' : 'purchaseToken';
    final token = row[field] ?? jsonObject(row['result'])[field];
    if (token is String && token.isNotEmpty) {
      return chunk.where((p) => (appStore ? p.purchaseID : p.verificationData.serverVerificationData) == token).firstOrNull;
    }
    return rowCount == chunk.length ? chunk[index] : null;
  }

  Future<bool> _deliver(PurchaseDetails purchase, {BillingResult? restoredResult}) async {
    final state = apiState;
    if (state == null) throw StateError('Server verification required');
    final key = _purchaseKey(purchase);
    if (key.isEmpty) throw StateError('Purchase without transaction id');
    final result = restoredResult ??
        (appStore ? await state.api.verifyAppStore(purchase.productID, key) : await state.api.verifyPurchase(purchase.productID, key));
    if (result.status == 'pending') return false;
    if (appStore) {
      // App Store: finish() hanya setelah server mengkredit/mencatat.
      if (!result.consumableDelivered && !result.subscriptionVerified) {
        throw const ApiException(502, 'invalid_response', 'Unknown billing status');
      }
      if (purchase.pendingCompletePurchase) await _iap.completePurchase(purchase);
    } else if (result.consumableDelivered) {
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
