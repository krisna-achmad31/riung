// Audit kelayakan 2026-10-17 — skenario IAP, API & pindah akun.
//
// Konvensi: test bernama `REPRO <ID>` MENGUNCI perilaku yang saat ini
// salah (lihat docs/audit-kelayakan-2026-10.md). Begitu bug-nya diperbaiki,
// test itu akan gagal — balik ekspektasinya jadi perilaku yang benar.
// Test tanpa prefix REPRO = regresi untuk perilaku yang sudah benar.
import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:riung/core/models/user_profile.dart';
import 'package:riung/core/services/api/api_client.dart';
import 'package:riung/core/services/api/api_config_store.dart';
import 'package:riung/core/services/api/api_state.dart';
import 'package:riung/core/services/api/riung_api.dart';
import 'package:riung/core/services/services.dart';
import 'package:riung/features/toko/logic/premium_offer.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Repo extends Fake implements UserRepository {}

class _Wallet extends Fake implements WalletFunctionsService {}

class _Android extends Fake implements InAppPurchaseAndroidPlatformAddition {
  int consumed = 0;
  @override
  Future<BillingResultWrapper> consumePurchase(PurchaseDetails purchase) async {
    consumed++;
    return const BillingResultWrapper(responseCode: BillingResponse.ok);
  }
}

class _Play extends Fake implements InAppPurchase {
  final stream = StreamController<List<PurchaseDetails>>.broadcast();
  final android = _Android();
  int completed = 0;
  int buyNonConsumableCalls = 0;
  PurchaseParam? lastParam;
  List<PurchaseDetails> restoreResult = const [];
  Object? restoreError;

  /// true = Play tidak pernah menjawab restore (tanpa update di stream).
  bool silentRestore = false;

  @override
  Future<bool> isAvailable() async => true;
  @override
  Stream<List<PurchaseDetails>> get purchaseStream => stream.stream;
  @override
  Future<void> restorePurchases({String? applicationUserName}) async {
    if (restoreError != null) throw restoreError!;
    if (silentRestore) return;
    // Perilaku asli in_app_purchase_android 0.5.3: daftar KOSONG tetap
    // di-add ke purchaseStream bila tidak ada pembelian.
    stream.add(restoreResult);
  }

  @override
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam}) async {
    buyNonConsumableCalls++;
    lastParam = purchaseParam;
    return true;
  }

  @override
  Future<bool> buyConsumable({required PurchaseParam purchaseParam, bool autoConsume = true}) async {
    lastParam = purchaseParam;
    return true;
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async => completed++;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #getPlatformAddition) return android;
    return super.noSuchMethod(invocation);
  }
}

PurchaseDetails _purchase(
  String product,
  PurchaseStatus status, {
  String token = 'token-1',
  IAPError? error,
  bool pendingComplete = true,
}) =>
    PurchaseDetails(
      productID: product,
      verificationData: PurchaseVerificationData(
        localVerificationData: '',
        serverVerificationData: token,
        source: 'google_play',
      ),
      transactionDate: '0',
      status: status,
    )
      ..error = error
      ..pendingCompletePurchase = pendingComplete;

/// Pembelian Play asli (bukan PurchaseDetails polos) — dibutuhkan sebagai
/// `oldPurchaseDetails` saat pindah plan.
GooglePlayPurchaseDetails _playPurchase(String product, PurchaseStatus status, {required String token}) =>
    GooglePlayPurchaseDetails.fromPurchase(PurchaseWrapper(
      orderId: 'order-$token',
      packageName: 'id.riung.riung',
      purchaseTime: 0,
      purchaseToken: token,
      signature: '',
      products: [product],
      isAutoRenewing: true,
      originalJson: '{}',
      isAcknowledged: true,
      purchaseState: PurchaseStateWrapper.purchased,
    )).single
      ..status = status;

/// Rangkaian BillingService + ApiState dengan server palsu.
class _Rig {
  _Rig(http.Response Function(http.Request r) server, {String uid = 'user'}) : _uid = uid {
    api = RiungApi(ApiClient(
      baseUrl: 'https://example.test',
      retryDelay: Duration.zero,
      token: (_) async => 'token',
      client: MockClient((r) async {
        requests.add('${r.method} ${r.url.path}');
        return server(r);
      }),
    ));
    state = ApiState(api: api, db: LocalDatabaseService(), currentUid: () => _uid);
    billing = BillingService(
      walletFunctions: _Wallet(),
      userRepository: _Repo(),
      currentUid: () => _uid ?? '',
      analytics: AnalyticsService(),
      isAnonymous: () => anonymous,
      iap: play,
      apiState: state,
    );
  }
  final String? _uid;
  bool anonymous = false;
  final play = _Play();
  final requests = <String>[];
  late final RiungApi api;
  late final ApiState state;
  late final BillingService billing;

  Future<List<BillingUpdate>> run(Future<void> Function() action) async {
    await billing.init();
    final updates = <BillingUpdate>[];
    final sub = billing.updates.listen(updates.add);
    await action();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await sub.cancel();
    return updates;
  }
}

http.Response _json(Object body, [int status = 200]) => http.Response(jsonEncode(body), status);

http.Response _meThen(http.Request r, http.Response Function() billing) =>
    r.url.path == '/v1/me' ? _json({'billingAccountId': 'acct-A', 'wallet': {'coins': 0}}) : billing();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    ApiConfigStore.instance.raw = {'minAppVersion': '0.0.0'};
  });

  group('4. IAP — status transaksi', () {
    test('4c pending (VA/Indomaret): emit pending, TIDAK verify, TIDAK ack/consume', () async {
      final rig = _Rig((r) => _meThen(r, () => _json({'status': 'active'})));
      final updates = await rig.run(() async => rig.play.stream.add([_purchase('premium_yearly', PurchaseStatus.pending)]));
      expect(updates.single.status, BillingStatus.pending);
      expect(rig.requests.where((p) => p.contains('/billing/')), isEmpty);
      expect(rig.play.completed, 0);
    });

    test('4c lunas setelah pending: purchased → verify → ack → success', () async {
      final rig = _Rig((r) => _meThen(r, () => _json({'status': 'active'})));
      final updates = await rig.run(() async {
        rig.play.stream.add([_purchase('premium_yearly', PurchaseStatus.pending)]);
        rig.play.stream.add([_purchase('premium_yearly', PurchaseStatus.purchased)]);
      });
      expect(updates.map((u) => u.status), [BillingStatus.pending, BillingStatus.success]);
      expect(rig.play.completed, 1);
    });

    test('4b dibatalkan user: emit canceled & selesaikan transaksi', () async {
      final rig = _Rig((r) => _meThen(r, () => _json({})));
      final updates = await rig.run(() async => rig.play.stream.add([_purchase('premium_monthly', PurchaseStatus.canceled)]));
      expect(updates.single.status, BillingStatus.canceled);
      expect(rig.play.completed, 1);
      expect(rig.requests.where((p) => p.contains('/billing/')), isEmpty);
    });

    test('4d kartu ditolak: emit error purchaseFailed + pesan Play diteruskan', () async {
      final rig = _Rig((r) => _meThen(r, () => _json({})));
      final updates = await rig.run(() async => rig.play.stream.add([
            _purchase('coin_pack_small', PurchaseStatus.error,
                error: IAPError(source: 'google_play', code: 'purchase_error', message: 'Kartu ditolak')),
          ]));
      expect(updates.single.status, BillingStatus.error);
      expect(updates.single.errorKind, BillingErrorKind.purchaseFailed);
      expect(updates.single.detail, 'Kartu ditolak');
    });

    test('server menolak receipt (409 purchase_invalid): deliveryFailed, tidak consume', () async {
      final rig = _Rig((r) => _meThen(r, () => _json({'error': {'code': 'purchase_invalid'}}, 409)));
      final updates = await rig.run(() async => rig.play.stream.add([_purchase('coin_pack_small', PurchaseStatus.purchased)]));
      expect(updates.single.errorKind, BillingErrorKind.deliveryFailed);
      expect(rig.play.android.consumed, 0);
    });

    test('server 500 berulang: retry lalu deliveryFailed, pembelian tetap tertunda di Play', () async {
      final rig = _Rig((r) => _meThen(r, () => _json({'error': {'code': 'internal'}}, 500)));
      final updates = await rig.run(() async => rig.play.stream.add([_purchase('premium_yearly', PurchaseStatus.purchased)]));
      expect(updates.single.errorKind, BillingErrorKind.deliveryFailed);
      expect(rig.requests.where((p) => p == 'POST /v1/billing/verify').length, 3, reason: '1 + 2 retry');
      expect(rig.play.completed, 0);
    });

    test('server balas status pending (Play belum lunas): tidak ada success, tidak ack', () async {
      final rig = _Rig((r) => _meThen(r, () => _json({'status': 'pending'})));
      final updates = await rig.run(() async => rig.play.stream.add([_purchase('premium_yearly', PurchaseStatus.purchased)]));
      expect(updates, isEmpty);
      expect(rig.play.completed, 0);
    });

    test('anonim tidak bisa beli (jaring pengaman lapis 2)', () async {
      final rig = _Rig((r) => _meThen(r, () => _json({})))..anonymous = true;
      await rig.billing.init();
      final product = ProductDetails(id: 'premium_yearly', title: '', description: '', price: 'Rp590.000', rawPrice: 590000, currencyCode: 'IDR');
      expect(() => rig.billing.buyPremium(product), throwsStateError);
    });
  });

  group('4e/4f Restore', () {
    test('restore langganan aktif: server verifikasi → ack → success', () async {
      final rig = _Rig((r) => _meThen(r, () => _json({'results': [{'result': {'status': 'active'}}]})));
      rig.play.restoreResult = [_purchase('premium_yearly', PurchaseStatus.restored)];
      RestoreOutcome? outcome;
      final updates = await rig.run(() async => outcome = await rig.billing.restorePurchases());
      expect(updates.single.status, BillingStatus.success);
      expect(rig.play.completed, 1);
      expect(outcome, RestoreOutcome.restored);
    });

    test('H-03: restore tanpa pembelian sama sekali → RestoreOutcome.none (UI tidak menunggu update)', () async {
      final rig = _Rig((r) => _meThen(r, () => _json({'results': []})));
      RestoreOutcome? outcome;
      final updates = await rig.run(() async => outcome = await rig.billing.restorePurchases());
      expect(outcome, RestoreOutcome.none);
      expect(updates, isEmpty);
    });

    test('H-03: error Play saat restore ditangkap → RestoreOutcome.failed, tidak throw', () async {
      final rig = _Rig((r) => _meThen(r, () => _json({})));
      rig.play.restoreError = InAppPurchaseException(source: 'google_play', code: 'restore_error', message: '6');
      await rig.billing.init();
      expect(await rig.billing.restorePurchases(), RestoreOutcome.failed);
    });

    testWidgets('H-03: Play tidak pernah menjawab restore → failed setelah timeout', (tester) async {
      final rig = _Rig((r) => _meThen(r, () => _json({})));
      rig.play.silentRestore = true;
      await rig.billing.init();
      RestoreOutcome? outcome;
      unawaited(rig.billing.restorePurchases().then((o) => outcome = o));
      await tester.pump(BillingService.restoreTimeout - const Duration(seconds: 1));
      expect(outcome, isNull);
      await tester.pump(const Duration(seconds: 2));
      expect(outcome, RestoreOutcome.failed);
    });

    test('M-05: langganan milik akun lain di HP yang sama ditolak server → user diberi tahu', () async {
      final rig = _Rig((r) => _meThen(r, () => _json({'results': [{'error': {'code': 'purchase_invalid'}}]})));
      rig.play.restoreResult = [_purchase('premium_yearly', PurchaseStatus.restored)];
      RestoreOutcome? outcome;
      final updates = await rig.run(() async => outcome = await rig.billing.restorePurchases());
      expect(outcome, RestoreOutcome.otherAccount);
      expect(rig.play.completed, 0, reason: 'tidak ack token milik akun lain');
      expect(updates.single.status, BillingStatus.error);
      expect(updates.single.errorKind, BillingErrorKind.otherAccount);
      expect(updates.single.productId, 'premium_yearly');
    });

    test('M-06: server menghilangkan satu baris → hanya pembelian yang tokennya cocok yang di-ack', () async {
      final rig = _Rig((r) => _meThen(r, () => _json({'results': [
            {'purchaseToken': 'yearly-token', 'result': {'status': 'active'}},
          ]})));
      rig.play.restoreResult = [
        _purchase('premium_monthly', PurchaseStatus.restored, token: 'monthly-token'),
        _purchase('premium_yearly', PurchaseStatus.restored, token: 'yearly-token'),
      ];
      RestoreOutcome? outcome;
      final updates = await rig.run(() async => outcome = await rig.billing.restorePurchases());
      expect(updates.where((u) => u.status == BillingStatus.success).map((u) => u.productId), ['premium_yearly']);
      expect(rig.play.completed, 1);
      expect(outcome, RestoreOutcome.restored);
    });

    test('M-06: urutan baris server berbeda → hasil jatuh ke pembelian yang benar lewat purchaseToken', () async {
      final rig = _Rig((r) => _meThen(r, () => _json({'results': [
            {'purchaseToken': 'yearly-token', 'result': {'status': 'active'}},
            {'purchaseToken': 'monthly-token', 'error': {'code': 'purchase_invalid'}},
          ]})));
      rig.play.restoreResult = [
        _purchase('premium_monthly', PurchaseStatus.restored, token: 'monthly-token'),
        _purchase('premium_yearly', PurchaseStatus.restored, token: 'yearly-token'),
      ];
      final updates = await rig.run(rig.billing.restorePurchases);
      expect(updates.firstWhere((u) => u.status == BillingStatus.success).productId, 'premium_yearly');
      expect(updates.firstWhere((u) => u.status == BillingStatus.error).productId, 'premium_monthly');
      expect(updates.firstWhere((u) => u.status == BillingStatus.error).errorKind, BillingErrorKind.otherAccount);
      expect(rig.play.completed, 1);
    });

    test('M-06: tanpa token & jumlah baris tidak sama → tidak menebak lewat indeks (tidak ada ack)', () async {
      final rig = _Rig((r) => _meThen(r, () => _json({'results': [{'result': {'status': 'active'}}]})));
      rig.play.restoreResult = [
        _purchase('premium_monthly', PurchaseStatus.restored, token: 'monthly-token'),
        _purchase('premium_yearly', PurchaseStatus.restored, token: 'yearly-token'),
      ];
      final updates = await rig.run(rig.billing.restorePurchases);
      expect(updates.where((u) => u.status == BillingStatus.success), isEmpty);
      expect(rig.play.completed, 0);
    });

    test('restore gagal jaringan: deliveryFailed, tidak ack (pulih di restore berikutnya)', () async {
      final rig = _Rig((r) => r.url.path == '/v1/me'
          ? _json({'billingAccountId': 'acct-A'})
          : throw http.ClientException('offline'));
      rig.play.restoreResult = [_purchase('premium_yearly', PurchaseStatus.restored)];
      final updates = await rig.run(rig.billing.restorePurchases);
      expect(updates.single.errorKind, BillingErrorKind.deliveryFailed);
      expect(rig.play.completed, 0);
    });
  });

  group('4/5 Produk & harga dari Play', () {
    ProductDetailsWrapper subs(List<SubscriptionOfferDetailsWrapper> offers) => ProductDetailsWrapper(
          description: 'Riung Premium',
          name: 'Premium Tahunan',
          productId: 'premium_yearly',
          productType: ProductType.subs,
          title: 'Premium Tahunan (Riung)',
          subscriptionOfferDetails: offers,
        );
    PricingPhaseWrapper phase(String price, int micros, String ccy, String period, RecurrenceMode mode) =>
        PricingPhaseWrapper(billingCycleCount: 1, billingPeriod: period, formattedPrice: price, priceAmountMicros: micros, priceCurrencyCode: ccy, recurrenceMode: mode);

    test('harga, mata uang & currencyCode berasal dari Play (dinamis per region)', () {
      for (final (price, ccy) in [('Rp590.000', 'IDR'), (r'$39.99', 'USD'), ('39,99 €', 'EUR')]) {
        final p = GooglePlayProductDetails.fromProductDetails(subs([
          SubscriptionOfferDetailsWrapper(basePlanId: 'yearly', offerTags: const [], offerIdToken: 'base',
              pricingPhases: [phase(price, 1, ccy, 'P1Y', RecurrenceMode.infiniteRecurring)]),
        ])).single;
        expect(p.price, price);
        expect(p.currencyCode, ccy);
      }
    });

    final baseOffer = SubscriptionOfferDetailsWrapper(basePlanId: 'yearly', offerTags: const [], offerIdToken: 'base',
        pricingPhases: [phase('Rp590.000', 590000000000, 'IDR', 'P1Y', RecurrenceMode.infiniteRecurring)]);
    final trialOffer = SubscriptionOfferDetailsWrapper(basePlanId: 'yearly', offerId: 'trial-7d', offerTags: const [], offerIdToken: 'trial',
        pricingPhases: [
          phase('Gratis', 0, 'IDR', 'P1W', RecurrenceMode.finiteRecurring),
          phase('Rp590.000', 590000000000, 'IDR', 'P1Y', RecurrenceMode.infiniteRecurring),
        ]);

    test('H-02: offer trial + base plan → PremiumOffer memilih offer trial & harga recurring', () {
      for (final order in [[baseOffer, trialOffer], [trialOffer, baseOffer]]) {
        final list = GooglePlayProductDetails.fromProductDetails(subs(order));
        expect(list.length, 2, reason: 'plugin tetap memecah per offer');
        final offers = PremiumOffer.fromProducts(list);
        final yearly = offers['premium_yearly']!;
        expect(yearly.recurringPrice, 'Rp590.000', reason: 'bukan "Gratis/tahun"');
        expect(yearly.trialDays, 7);
        expect((yearly.purchase as GooglePlayProductDetails).offerToken, 'trial', reason: 'tidak bergantung urutan Play');
      }
    });

    test('H-02: user yang sudah pernah trial (Play hanya kirim base plan) → tanpa label trial', () {
      final offers = PremiumOffer.fromProducts(GooglePlayProductDetails.fromProductDetails(subs([baseOffer])));
      expect(offers['premium_yearly']!.trialDays, isNull);
      expect(offers['premium_yearly']!.recurringPrice, 'Rp590.000');
    });

    final yearlyProduct = ProductDetails(id: 'premium_yearly', title: '', description: '', price: 'Rp590.000', rawPrice: 590000, currencyCode: 'IDR');
    http.Response premiumMonthlyServer(http.Request r) => r.url.path == '/v1/me'
        ? _json({'billingAccountId': 'acct-A', 'premium': {'status': 'active', 'plan': 'premium_monthly'}})
        : _json({'results': [{'result': {'status': 'active'}}]});

    test('H-04: sudah Premium bulanan → beli tahunan memakai ChangeSubscriptionParam(oldPurchaseDetails)', () async {
      final rig = _Rig(premiumMonthlyServer);
      rig.play.restoreResult = [_playPurchase('premium_monthly', PurchaseStatus.restored, token: 'monthly-token')];
      await rig.billing.init();
      await rig.billing.buyPremium(yearlyProduct);
      expect(rig.play.buyNonConsumableCalls, 1);
      final param = rig.play.lastParam! as GooglePlayPurchaseParam;
      expect(param.changeSubscriptionParam?.oldPurchaseDetails.productID, 'premium_monthly');
      expect(param.changeSubscriptionParam?.oldPurchaseDetails.verificationData.serverVerificationData, 'monthly-token');
      expect(param.applicationUserName, 'acct-A');
    });

    test('H-04: server bilang Premium aktif tapi langganan lama tidak ada di Play ini → tidak membuat langganan kedua', () async {
      final rig = _Rig(premiumMonthlyServer);
      await rig.billing.init();
      await expectLater(rig.billing.buyPremium(yearlyProduct), throwsStateError);
      expect(rig.play.buyNonConsumableCalls, 0);
    });

    test('H-04: plan yang sedang aktif tidak bisa dibeli lagi', () async {
      final rig = _Rig(premiumMonthlyServer);
      await rig.billing.init();
      final monthly = ProductDetails(id: 'premium_monthly', title: '', description: '', price: 'Rp59.000', rawPrice: 59000, currencyCode: 'IDR');
      await expectLater(rig.billing.buyPremium(monthly), throwsStateError);
      expect(rig.play.buyNonConsumableCalls, 0);
    });

    test('H-04: belum Premium → GooglePlayPurchaseParam tanpa changeSubscriptionParam', () async {
      final rig = _Rig((r) => _json({'billingAccountId': 'acct-A'}));
      await rig.billing.init();
      await rig.billing.buyPremium(yearlyProduct);
      final param = rig.play.lastParam! as GooglePlayPurchaseParam;
      expect(param.changeSubscriptionParam, isNull);
    });

    test('H-01: buyPremium melempar ApiException saat /me gagal → paywall wajib menangkapnya (lihat widget test H-01)', () async {
      final rig = _Rig((r) => _json({'error': {'code': 'internal'}}, 503));
      await rig.billing.init();
      final product = ProductDetails(id: 'premium_yearly', title: '', description: '', price: 'Rp590.000', rawPrice: 590000, currencyCode: 'IDR');
      await expectLater(rig.billing.buyPremium(product), throwsA(isA<ApiException>()));
    });

    test('queryProducts saat Play tidak tersedia: daftar kosong + error, tidak throw', () async {
      final billing = BillingService(
        walletFunctions: _Wallet(),
        userRepository: _Repo(),
        currentUid: () => 'u',
        analytics: AnalyticsService(),
        isAnonymous: () => false,
        iap: _Play(),
      );
      final res = await billing.queryProducts(); // init() belum dipanggil = unavailable
      expect(res.productDetails, isEmpty);
      expect(res.error, isNotNull);
    });
  });

  group('4f Status langganan (entitlement dari server)', () {
    UserProfile profile(bool active, DateTime? renews) => UserProfile.kosong('u').copyWith(premiumActive: active, premiumRenewsAt: renews);
    final now = DateTime(2026, 10, 17, 12);

    test('aktif, hampir habis, masa tenggang, kedaluwarsa', () {
      expect(profile(true, now.add(const Duration(days: 20))).premiumStatus(now), PremiumStatus.active);
      expect(profile(true, now.add(const Duration(days: 1))).premiumStatus(now), PremiumStatus.renewsSoon);
      expect(profile(true, now.subtract(const Duration(hours: 1))).premiumStatus(now), PremiumStatus.renewsSoon);
      expect(profile(true, now.subtract(const Duration(days: 30))).premiumStatus(now), PremiumStatus.expired);
      expect(profile(false, null).premiumStatus(now), PremiumStatus.none);
    });

    test('REPRO M-02: entitlement bergantung jam HP — mundurkan jam = Premium kedaluwarsa tetap aktif', () {
      final expiredLastMonth = profile(true, DateTime(2026, 9, 1));
      final tamperedClock = DateTime(2026, 8, 1);
      expect(expiredLastMonth.premiumStatus(tamperedClock), PremiumStatus.active);
    });
  });

  group('3. API — kontrak & kegagalan', () {
    ApiClient client(http.Response Function(http.Request) handler, {List<bool>? forced}) => ApiClient(
          baseUrl: 'https://example.test',
          retryDelay: Duration.zero,
          token: (force) async {
            forced?.add(force);
            return 'id-token';
          },
          appCheckToken: (_, _) async => 'app-check',
          client: MockClient((r) async => handler(r)),
        );

    test('header kontrak: Bearer, App Check, versi, platform, Idempotency-Key utk mutasi', () async {
      late http.Request seen;
      final c = client((r) {
        seen = r;
        return _json({'data': {'ok': true}});
      });
      final res = await c.request('POST', '/v1/shop/purchase', body: {'a': 1});
      expect(res.object['ok'], true);
      expect(seen.headers['Authorization'], 'Bearer id-token');
      expect(seen.headers['X-Firebase-AppCheck'], 'app-check');
      expect(seen.headers['X-Platform'], 'android');
      expect(seen.headers['Idempotency-Key'], isNotEmpty);
      expect(seen.headers['Content-Type'], startsWith('application/json'));
    });

    test('400 validasi: tidak di-retry, kode & requestId diteruskan', () async {
      var calls = 0;
      final c = client((r) {
        calls++;
        return _json({'error': {'code': 'invalid_request', 'message': 'x', 'requestId': 'req-1'}}, 400);
      });
      final e = await c.request('POST', '/v1/x', body: {}).then<ApiException?>((_) => null, onError: (Object e) => e as ApiException);
      expect(calls, 1);
      expect(e!.code, 'invalid_request');
      expect(e.requestId, 'req-1');
    });

    test('401 token expired: refresh token paksa lalu sukses', () async {
      final forced = <bool>[];
      var calls = 0;
      final c = client((r) => ++calls == 1 ? _json({'error': {'code': 'unauthenticated'}}, 401) : _json({'ok': 1}), forced: forced);
      await c.request('GET', '/v1/me');
      expect(forced, [false, true]);
    });

    test('401 terus-menerus (refresh gagal): ApiException 401, berhenti setelah 1 refresh', () async {
      var calls = 0;
      final c = client((r) {
        calls++;
        return _json({'error': {'code': 'unauthenticated'}}, 401);
      });
      await expectLater(c.request('GET', '/v1/me'), throwsA(isA<ApiException>().having((e) => e.status, 'status', 401)));
      expect(calls, 2);
    });

    test('403 & 404: tidak retry, tidak retryable', () async {
      for (final status in [403, 404]) {
        var calls = 0;
        final c = client((r) {
          calls++;
          return _json({'error': {'code': 'x'}}, status);
        });
        await expectLater(c.request('GET', '/v1/x'), throwsA(isA<ApiException>().having((e) => e.retryable, 'retryable', false)));
        expect(calls, 1);
      }
    });

    test('429 dengan Retry-After besar: langsung menyerah (tidak menahan UI)', () async {
      var calls = 0;
      final c = client((r) {
        calls++;
        return http.Response('{"error":{"code":"rate_limited"}}', 429, headers: {'retry-after': '60'});
      });
      await expectLater(c.request('GET', '/v1/me'), throwsA(isA<ApiException>().having((e) => e.status, 'status', 429)));
      expect(calls, 1);
    });

    test('500 lalu sukses: retry dengan Idempotency-Key yang SAMA', () async {
      final keys = <String?>[];
      final c = client((r) {
        keys.add(r.headers['Idempotency-Key']);
        return keys.length < 3 ? _json({'error': {'code': 'internal'}}, 500) : _json({'ok': 1});
      });
      await c.request('POST', '/v1/shop/purchase', body: {});
      expect(keys.length, 3);
      expect(keys.toSet().length, 1);
    });

    test('timeout & offline dipetakan ke ApiException status 0 (retryable)', () async {
      final slow = ApiClient(
        baseUrl: 'https://example.test',
        retryDelay: Duration.zero,
        timeout: const Duration(milliseconds: 10),
        client: MockClient((r) async {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          return _json({});
        }),
      );
      await expectLater(slow.request('GET', '/healthz', authenticated: false, maxRetries: 0),
          throwsA(isA<ApiException>().having((e) => e.code, 'code', 'timeout')));
      final offline = client((r) => throw http.ClientException('no network'));
      await expectLater(offline.request('GET', '/v1/me', maxRetries: 0),
          throwsA(isA<ApiException>().having((e) => e.code, 'code', 'network')));
    });

    test('JSON rusak: ApiException invalid_response, bukan FormatException', () async {
      final c = client((r) => http.Response('<html>502 Bad Gateway</html>', 502));
      await expectLater(c.request('GET', '/v1/me', maxRetries: 0),
          throwsA(isA<ApiException>().having((e) => e.code, 'code', 'invalid_response')));
    });

    test('REPRO L-01: error.code non-string dari server → TypeError lolos (bukan ApiException)', () async {
      final c = client((r) => _json({'error': {'code': 42, 'message': 'x'}}, 400));
      await expectLater(c.request('GET', '/v1/me'), throwsA(isA<TypeError>()));
    });

    test('pindah akun di tengah retry dibatalkan (account_changed)', () async {
      var account = 'A';
      final c = ApiClient(
        baseUrl: 'https://example.test',
        retryDelay: Duration.zero,
        token: (_) async => 't',
        accountId: () => account,
        client: MockClient((r) async {
          account = 'B';
          return _json({'error': {'code': 'internal'}}, 500);
        }),
      );
      await expectLater(c.request('GET', '/v1/me'), throwsA(isA<ApiException>().having((e) => e.code, 'code', 'account_changed')));
    });

    test('HTTP non-lokal ditolak (wajib HTTPS)', () {
      expect(() => ApiClient(baseUrl: 'http://api.riung.id'), throwsArgumentError);
    });
  });

  group('1. Pindah akun di perangkat yang sama', () {
    test('snapshot /me akun A tidak terlihat oleh akun B', () async {
      var uid = 'A';
      final api = RiungApi(ApiClient(
        baseUrl: 'https://example.test',
        retryDelay: Duration.zero,
        token: (_) async => 't',
        client: MockClient((r) async => uid == 'A'
            ? _json({'premium': {'status': 'active'}, 'wallet': {'coins': 500}})
            : _json({'error': {'code': 'internal'}}, 503)),
      ));
      final state = ApiState(api: api, db: LocalDatabaseService(), currentUid: () => uid);
      await state.refresh();
      expect(state.currentSnapshot, isNotNull);
      uid = 'B';
      expect(state.currentSnapshot, isNull);
      await expectLater(state.refresh(), throwsA(isA<ApiException>()), reason: 'B tanpa cache tidak memakai cache A');
    });

    test('C-01: kosmetik/perisai/fokus prabayar akun A tidak terlihat oleh akun B', () async {
      var uid = 'A';
      final prefs = await LocalPrefsStore.init();
      prefs.bindAccount(() => uid);
      addTearDown(() => prefs.bindAccount(null));
      final api = RiungApi(ApiClient(
        baseUrl: 'https://example.test',
        retryDelay: Duration.zero,
        token: (_) async => 't',
        client: MockClient((r) async => uid == 'A'
            ? _json({
                'inventory': {'cosmetics': ['topi_pesta'], 'prepaidFocus': 4},
                'streak': {'shields': 2},
              })
            : _json({'error': {'code': 'internal'}}, 503)),
      ));
      final state = ApiState(api: api, db: LocalDatabaseService(), currentUid: () => uid, presentationPrefs: prefs);
      await state.refresh();
      uid = 'B';
      state.clearSession(); // persis yang dilakukan main.dart saat uid berganti
      await state.refresh().catchError((Object _) => state.snapshot ?? ApiSnapshot({}));
      expect(prefs.ownedCosmetics, isEmpty);
      expect(prefs.prepaidFocusSessions, 0);
      expect(prefs.streakShieldBalance, 0);
      uid = 'A';
      expect(prefs.ownedCosmetics, contains('topi_pesta'), reason: 'data A tetap utuh saat A masuk lagi');
      expect(prefs.prepaidFocusSessions, 4);
      expect(prefs.streakShieldBalance, 2);
    });

    test('C-01: prefs global lama diserahkan sekali ke pemilik terakhir, akun lain mulai kosong', () async {
      SharedPreferences.setMockInitialValues({
        'riung_uid': 'A',
        'riung_owned_cosmetics': ['topi_pesta'],
        'riung_custom_affirmations_json': '[{"text":"aku cukup"}]',
        'riung_language_code': 'en',
      });
      final prefs = LocalPrefsStore.forTesting(await SharedPreferences.getInstance());
      var uid = 'B';
      prefs.bindAccount(() => uid);
      await LegacyAccountMigration.run(prefs: prefs, currentUid: uid, db: _CountingDb(), crypto: JournalCryptoService(), pin: JurnalPinService());
      expect(prefs.ownedCosmetics, isEmpty);
      expect(prefs.customAffirmations, isEmpty);
      expect(prefs.languageCode, 'en', reason: 'pengaturan perangkat tetap global');
      uid = 'A';
      expect(prefs.ownedCosmetics, {'topi_pesta'});
      expect(prefs.customAffirmations, hasLength(1));
      await LegacyAccountMigration.run(prefs: prefs, currentUid: uid);
      expect(prefs.ownedCosmetics, {'topi_pesta'}, reason: 'migrasi tidak jalan dua kali');
    });

    test('C-01: PIN jurnal per uid, PIN lama diserahkan ke pemiliknya', () async {
      FlutterSecureStorage.setMockInitialValues({'riung_jurnal_pin_v1': '123456'});
      final pin = JurnalPinService();
      await pin.adoptLegacyPin('A');
      expect(await pin.verifyPin('A', '123456'), isTrue);
      expect(await pin.hasPin('B'), isFalse);
      expect(await pin.verifyPin('B', '123456'), isFalse);
    });

    test('C-01: jurnal, check-in & batas jurnal harian di-scope per uid', () async {
      final db = _CountingDb();
      final repo = LocalUserRepository(prefs: await LocalPrefsStore.init(), db: db, crypto: JournalCryptoService());
      await repo.getJournalEntries('akun-B');
      await repo.journalEntryCountForDate('akun-B', DateTime(2026, 10, 17));
      await repo.getCheckIns('akun-B');
      await repo.hasCheckedInToday('akun-B');
      expect(db.calls, [
        'allJournalEntries(akun-B)',
        'journalEntryCountForDate(akun-B, 2026-10-17)',
        'allCheckIns(akun-B)',
        'allCheckIns(akun-B)',
      ]);
    });
  });
}

class _CountingDb extends Fake implements LocalDatabaseService {
  final calls = <String>[];
  @override
  Future<List<Map<String, Object?>>> allJournalEntries(String uid) async {
    calls.add('allJournalEntries($uid)');
    return const [];
  }

  @override
  Future<int> journalEntryCountForDate(String uid, String isoDate) async {
    calls.add('journalEntryCountForDate($uid, $isoDate)');
    return 0;
  }

  @override
  Future<List<Map<String, Object?>>> allCheckIns(String uid) async {
    calls.add('allCheckIns($uid)');
    return const [];
  }

  @override
  Future<void> adoptOrphanRows(String uid) async => calls.add('adoptOrphanRows($uid)');
}
