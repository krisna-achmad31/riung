import 'dart:async';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart' hide kIAPSource;
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart' show SK2PurchaseDetails, kIAPSource;
import 'package:in_app_purchase_storekit/store_kit_2_wrappers.dart' show SK2Product, SK2Transaction;
import 'api/api_state.dart';
import 'api/api_client.dart';
import 'api/riung_api.dart';

import '../config/economy.dart';
import 'firebase/analytics_service.dart';
import 'store_platform.dart';
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

/// Hasil "Pulihkan pembelian": [none] = akun toko (Play/Apple ID) ini tidak
/// punya pembelian, [failed] = toko/server gagal atau tidak menjawab (boleh
/// dicoba lagi), [otherAccount] = langganan di akun toko ini milik akun Riung
/// lain.
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

  /// Pesan mentah dari toko (sudah dilokalisasi oleh Play/App Store) — cuma
  /// terisi untuk [BillingErrorKind.purchaseFailed].
  final String? detail;
}

/// Pembelian Google Play & App Store diverifikasi backend sebelum
/// di-consume/acknowledge (Play) atau di-finish (StoreKit). Pengiriman yang
/// gagal tetap bisa dipulihkan: Play lewat restore, App Store lewat transaksi
/// yang belum di-finish (dikirim ulang StoreKit / dibaca saat restore).
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
    StorePlatform? store,
    Future<bool> Function(String productId)? introOfferEligible,
    Future<List<PurchaseDetails>> Function()? unfinishedTransactions,
  })  : _analytics = analytics,
        _isAnonymous = isAnonymous,
        _iap = iap ?? InAppPurchase.instance,
        _store = store ?? StorePlatform.current,
        _introOfferEligible = introOfferEligible ?? SK2Product.isIntroductoryOfferEligible,
        _unfinishedTransactions = unfinishedTransactions ?? _storeKitUnfinished;

  final AnalyticsService _analytics;
  final bool Function() _isAnonymous;
  final InAppPurchase _iap;
  final ApiState? apiState;
  final StorePlatform _store;
  final Future<bool> Function(String productId) _introOfferEligible;
  final Future<List<PurchaseDetails>> Function() _unfinishedTransactions;

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

  /// Batas tunggu `completePurchase` di iOS: `finish()` plugin StoreKit tidak
  /// pernah menjawab bila transaksinya sudah tidak ada di `Transaction.all`
  /// (consumable yang sudah di-finish), dan antrean pembelian tidak boleh macet.
  static const finishTimeout = Duration(seconds: 10);

  StreamSubscription<List<PurchaseDetails>>? _subscription;
  Future<void> _processing = Future.value();
  Completer<RestoreOutcome>? _restoreWaiter;

  /// Langganan Premium yang terakhir terverifikasi di HP ini (dari restore
  /// atau pembelian). Android: `oldPurchaseDetails` saat pindah plan. iOS:
  /// bukti langganan aktif memang milik Apple ID ini (bukan dari Play).
  PurchaseDetails? _activeSubscription;

  /// Referensi pembelian yang sudah di-consume (Play) / di-finish (StoreKit).
  final Set<String> _completed = {};

  /// Hasil [queryProducts] terakhir — sumber harga & mata uang lokal untuk
  /// analytics.
  final Map<String, ProductDetails> _products = {};
  final _updatesController = StreamController<BillingUpdate>.broadcast();

  /// Emit tiap kali status satu pembelian berubah — Toko screen dengarkan
  /// ini untuk menampilkan loading/sukses/gagal.
  Stream<BillingUpdate> get updates => _updatesController.stream;

  /// false bila toko tidak siap (emulator tanpa Play Store, Play Services
  /// mati, pembelian dibatasi Screen Time di iOS, plugin belum siap). Toko
  /// tetap tampil; tombol beli memberi tahu paket belum tersedia
  /// ([queryProducts] kosong).
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

  /// Tidak pernah throw: tanpa toko hasilnya daftar kosong, dan layar
  /// Toko/Paywall menampilkan "paket belum tersedia" saat ditap.
  Future<ProductDetailsResponse> queryProducts() async {
    if (!_available) return _emptyProducts('unavailable');
    try {
      final response = await _iap.queryProductDetails(allProductIds);
      for (final p in response.productDetails) {
        // Play memecah langganan jadi satu entri per offer (trial = 0);
        // simpan harga berulang, bukan harga trial.
        final current = _products[p.id];
        if (current == null || p.rawPrice > current.rawPrice) _products[p.id] = p;
      }
      return response;
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

  /// Lama trial gratis per plan Premium di App Store, hanya untuk plan yang
  /// trial-nya masih boleh dipakai Apple ID ini. Plugin StoreKit tidak
  /// membuka detail introductory offer, jadi lamanya dari
  /// [EconomyPremium.trialHari] — harus sama dengan offer di App Store
  /// Connect. Android: map kosong (trial dibaca dari offer Play). Tidak
  /// pernah throw: gagal cek = tanpa trial.
  Future<Map<String, int>> appStoreTrialDays(Iterable<ProductDetails> products) async {
    if (!_store.isAppStore) return const {};
    final out = <String, int>{};
    for (final id in products.map((p) => p.id).toSet()) {
      if (!PremiumSku.values.any((s) => s.productId == id)) continue;
      try {
        if (await _introOfferEligible(id)) out[id] = EconomyPremium.trialHari;
      } catch (error, stack) {
        _report(error, stack, 'billing_intro_offer_failed');
      }
    }
    return out;
  }

  /// Akun server yang ditempelkan ke pembelian: `billingAccountId` (Play,
  /// `obfuscatedExternalAccountId`) atau `appAccountToken` (StoreKit, UUID).
  String _purchaseAccount(ApiSnapshot? me) {
    final account = _store.isAppStore ? me?.appAccountToken : me?.billingAccountId;
    if (account == null || account.isEmpty) throw StateError('Server billing account required');
    return account;
  }

  /// Kunci satu pembelian di server: `purchaseToken` Play, atau
  /// `transactionId` StoreKit (`purchaseID`; JWS di `serverVerificationData`
  /// tidak dipakai server).
  String _ref(PurchaseDetails purchase) =>
      _store.isAppStore ? purchase.purchaseID ?? '' : purchase.verificationData.serverVerificationData;

  /// Transaksi StoreKit 2 yang belum di-finish (kredit yang terputus).
  static Future<List<PurchaseDetails>> _storeKitUnfinished() async => [
        for (final t in await SK2Transaction.unfinishedTransactions())
          SK2PurchaseDetails(
            productID: t.productId,
            purchaseID: t.id,
            verificationData: PurchaseVerificationData(
              localVerificationData: t.jsonRepresentation ?? '',
              serverVerificationData: t.receiptData ?? '',
              source: kIAPSource,
            ),
            transactionDate: t.purchaseDate,
            status: PurchaseStatus.purchased,
            appAccountToken: t.appAccountToken,
          ),
      ];

  /// Poin 2 — jaring pengaman lapis kedua. UI (lihat
  /// `ensureAccountForPurchase`) sudah harus mencegah ini tercapai dalam
  /// keadaan anonim; kalau tetap tercapai berarti ada titik panggil baru
  /// yang lupa pasang guard-nya di layar.
  Future<void> buyCoinPack(ProductDetails product) async {
    if (_isAnonymous()) {
      throw StateError('buyCoinPack dipanggil selagi masih anonim — pasang ensureAccountForPurchase() di UI pemanggil.');
    }
    final account = _purchaseAccount(await apiState?.refresh());
    // Play: autoConsume false supaya consume baru terjadi setelah server
    // memverifikasi. StoreKit mewajibkan true (assert), tapi tidak pernah
    // mem-finish sendiri — finish tetap menunggu verifikasi di [_deliver].
    final launched = await _iap.buyConsumable(
      purchaseParam: PurchaseParam(productDetails: product, applicationUserName: account),
      autoConsume: _store.isAppStore,
    );
    // Tanpa sheet toko tidak akan ada update di stream — UI harus tahu.
    if (!launched) throw StateError('Store purchase flow not launched');
  }

  /// Beli atau pindah plan Premium. Plan yang sama tidak bisa dibeli dua
  /// kali. Bila server menyatakan akun ini sudah Premium di plan lain:
  /// Play — dikirim sebagai penggantian langganan (`ChangeSubscriptionParam`)
  /// supaya tidak ada langganan kedua yang tertagih ganda; App Store — kedua
  /// plan satu subscription group, jadi Apple sendiri yang menukar plan.
  /// Keduanya hanya boleh bila langganan aktif ada di akun toko HP ini
  /// (langganan dari toko lain harus diubah di toko asalnya).
  Future<void> buyPremium(ProductDetails product) async {
    if (_isAnonymous()) {
      throw StateError('buyPremium dipanggil selagi masih anonim — pasang ensureAccountForPurchase() di UI pemanggil.');
    }
    final me = await apiState?.refresh();
    final account = _purchaseAccount(me);
    final activePlan = me!.activePremiumPlan;
    if (activePlan == product.id) throw StateError('Plan $activePlan sudah aktif');
    if (activePlan != null && _activeSubscription?.productID != activePlan) await restorePurchases();
    if (activePlan != null && _activeSubscription?.productID != activePlan) {
      throw StateError('Langganan aktif $activePlan tidak ditemukan di akun toko ini');
    }
    if (_store.isAppStore) {
      final launched = await _iap.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: product, applicationUserName: account),
      );
      if (!launched) throw StateError('App Store purchase flow not launched');
      return;
    }
    ChangeSubscriptionParam? change;
    if (activePlan != null) {
      final current = _activeSubscription;
      if (current is! GooglePlayPurchaseDetails) {
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
  /// kosong), saat toko melempar error, atau setelah [restoreTimeout].
  ///
  /// iOS: restore StoreKit hanya mengembalikan langganan aktif, jadi paket
  /// koin yang terbayar tapi belum terkirim (belum di-finish) diproses dulu
  /// dari transaksi yang belum selesai.
  Future<RestoreOutcome> restorePurchases() async {
    final pending = _restoreWaiter;
    if (pending != null) return pending.future;
    final recovered = _store.isAppStore ? await _recoverUnfinished() : 0;
    final outcome = await _restoreFromStore();
    return recovered > 0 && outcome == RestoreOutcome.none ? RestoreOutcome.restored : outcome;
  }

  Future<int> _recoverUnfinished() async {
    final List<PurchaseDetails> unfinished;
    try {
      unfinished = await _unfinishedTransactions();
    } catch (error, stack) {
      _report(error, stack, 'billing_unfinished_failed');
      return 0;
    }
    if (unfinished.isEmpty) return 0;
    final run = _processing.then((_) => _onPurchaseUpdate(unfinished));
    _processing = run.then((_) {}, onError: (Object error, StackTrace stack) => _report(error, stack, 'billing_unfinished_failed'));
    try {
      return (await run).delivered;
    } catch (_) {
      return 0;
    }
  }

  Future<RestoreOutcome> _restoreFromStore() async {
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
    final restored = purchases.where((p) => p.status == PurchaseStatus.restored && _ref(p).isNotEmpty).toList();
    final restoredResults = <String, BillingResult>{};
    if (restored.isNotEmpty && apiState != null) {
      // Per chunk: satu chunk gagal tidak membatalkan chunk lain yang
      // sudah terverifikasi (pemulihan parsial). Chunk gagal dicoba ulang
      // sekali; sisanya tetap tertunda di Play untuk restore berikutnya.
      for (var offset = 0; offset < restored.length; offset += restoreChunkSize) {
        final chunk = restored.skip(offset).take(restoreChunkSize).toList();
        for (var attempt = 0; attempt < 2; attempt++) {
          try {
            final api = apiState!.api;
            final response = _store.isAppStore
                ? await api.restoreAppStore(chunk.map((p) => (productId: p.productID, transactionId: _ref(p))).toList())
                : await api.restore(chunk.map((p) => (productId: p.productID, purchaseToken: _ref(p))).toList());
            final results = response['results'] as List? ?? [];
            for (final (i, raw) in results.indexed) {
              final row = jsonObject(raw);
              final purchase = _restoreRowPurchase(row, i, chunk, results.length, _ref, refKey: _store.isAppStore ? 'transactionId' : 'purchaseToken');
              if (purchase == null) continue;
              if (row['error'] != null) {
                final code = jsonObject(row['error'])['code'];
                if (code == 'purchase_invalid' && PremiumSku.values.any((s) => s.productId == purchase.productID)) {
                  otherAccount = true;
                  _updatesController.add(BillingUpdate(productId: purchase.productID, status: BillingStatus.error, errorKind: BillingErrorKind.otherAccount));
                }
                continue;
              }
              restoredResults[_ref(purchase)] = BillingResult(row);
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
      // Never consume, acknowledge or finish a restore that failed verification:
      // restored purchases without a verified result are skipped below.
    }
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          _updatesController.add(BillingUpdate(productId: purchase.productID, status: BillingStatus.pending));
        case PurchaseStatus.error:
          _logApiError('store ${purchase.productID}', purchase.error ?? 'unknown');
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
            if (purchase.status == PurchaseStatus.restored && !restoredResults.containsKey(_ref(purchase))) continue;
            final delivered = await _deliver(purchase, restoredResult: restoredResults[_ref(purchase)]);
            if (!delivered) continue;
            deliveredCount++;
            if (PremiumSku.values.any((s) => s.productId == purchase.productID)) {
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

  void _logApiError(String what, Object error) {
    if (error is ApiException) {
      debugPrint('billing $what failed: ${error.status} ${error.code} requestId=${error.requestId}');
    } else {
      debugPrint('billing $what failed: $error');
    }
  }

  /// Baris hasil restore dicocokkan lewat [refKey] (`purchaseToken` Play /
  /// `transactionId` App Store) — server boleh menghilangkan/mengurutkan
  /// ulang baris. Indeks hanya dipakai bila server tidak mengirim referensi
  /// DAN jumlah baris sama persis — selain itu baris diabaikan (pembelian
  /// tetap tertunda di toko) daripada ack/consume/finish jatuh ke pembelian
  /// yang salah.
  static PurchaseDetails? _restoreRowPurchase(
    Map<String, dynamic> row,
    int index,
    List<PurchaseDetails> chunk,
    int rowCount,
    String Function(PurchaseDetails) ref, {
    required String refKey,
  }) {
    final token = row[refKey] ?? jsonObject(row['result'])[refKey];
    if (token is String && token.isNotEmpty) {
      return chunk.where((p) => ref(p) == token).firstOrNull;
    }
    return rowCount == chunk.length ? chunk[index] : null;
  }

  Future<bool> _deliver(PurchaseDetails purchase, {BillingResult? restoredResult}) async {
    final state = apiState;
    if (state == null) throw StateError('Server verification required');
    final ref = _ref(purchase);
    if (ref.isEmpty) throw StateError('Purchase reference missing');
    final result = restoredResult ??
        (_store.isAppStore
            ? await state.api.verifyAppStorePurchase(purchase.productID, ref)
            : await state.api.verifyPurchase(purchase.productID, ref));
    if (result.status == 'pending') return false;
    if (result.consumableDelivered) {
      if (_store.isAppStore) {
        if (purchase.pendingCompletePurchase) await _finishAppStore(purchase);
      } else if (!_completed.contains(ref)) {
        final consumed = await _iap.getPlatformAddition<InAppPurchaseAndroidPlatformAddition>().consumePurchase(purchase);
        if (consumed.responseCode != BillingResponse.ok) throw StateError('Google Play consumption failed');
        _completed.add(ref);
      }
    } else if (result.subscriptionVerified) {
      if (purchase.pendingCompletePurchase) {
        _store.isAppStore ? await _finishAppStore(purchase) : await _iap.completePurchase(purchase);
      }
    } else {
      throw const ApiException(502, 'invalid_response', 'Unknown billing status');
    }
    // Sudah terverifikasi & di-finish/consume: premium/koin dari jawaban
    // verify sudah masuk snapshot (`ApiState._acceptMutation`). Gagal muat
    // ulang `/v1/me` di sini tidak boleh membuat pembelian dilaporkan gagal.
    try {
      await state.refresh();
    } catch (error, stack) {
      _report(error, stack, 'billing_refresh_after_delivery_failed');
    }
    if (purchase.status == PurchaseStatus.purchased) await _logPurchase(purchase.productID);
    return true;
  }

  /// Transaksi yang sama bisa datang dua kali (`Transaction.updates` saat app
  /// dibuka + pemulihan saat restore); finish cukup sekali.
  Future<void> _finishAppStore(PurchaseDetails purchase) async {
    final ref = _ref(purchase);
    if (_completed.contains(ref)) return;
    await _iap.completePurchase(purchase).timeout(finishTimeout, onTimeout: () {});
    _completed.add(ref);
  }

  /// Nilai dalam mata uang toko user (harga lokal). Rupiah dari config hanya
  /// cadangan bila daftar produk belum termuat.
  Future<void> _logPurchase(String productId) {
    final product = _products[productId];
    if (product != null) {
      return _analytics.purchase(productId: productId, value: product.rawPrice, currency: product.currencyCode);
    }
    final coin = CoinPackSku.values.where((s) => s.productId == productId);
    final premium = PremiumSku.values.where((s) => s.productId == productId);
    return _analytics.purchase(
      productId: productId,
      value: coin.isNotEmpty ? coin.first.priceIdr : premium.isNotEmpty ? premium.first.priceIdr : 0,
      currency: 'IDR',
    );
  }

  void dispose() {
    _subscription?.cancel();
    _updatesController.close();
  }
}
