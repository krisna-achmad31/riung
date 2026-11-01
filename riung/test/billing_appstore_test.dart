// Cabang App Store (StoreKit) di BillingService — spec backend §3.9b:
// akun = `appAccountToken` (UUID), referensi = `transactionId`, verifikasi
// lewat /v1/billing/appstore/*, finish setelah server menjawab.
import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:riung/core/services/api/api_client.dart';
import 'package:riung/core/services/api/api_config_store.dart';
import 'package:riung/core/services/api/api_state.dart';
import 'package:riung/core/services/api/riung_api.dart';
import 'package:riung/core/services/services.dart';
import 'package:riung/features/toko/logic/premium_offer.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Repo extends Fake implements UserRepository {}

class _Wallet extends Fake implements WalletFunctionsService {}

const _appAccountToken = '6f1c2a3b-4d5e-8f60-8a1b-2c3d4e5f6a7b';

class _StoreKit extends Fake implements InAppPurchase {
  final stream = StreamController<List<PurchaseDetails>>.broadcast();
  final completed = <String?>[];
  PurchaseParam? lastParam;
  bool? autoConsume;
  int buyNonConsumableCalls = 0;
  List<PurchaseDetails> restoreResult = const [];

  @override
  Future<bool> isAvailable() async => true;
  @override
  Stream<List<PurchaseDetails>> get purchaseStream => stream.stream;
  @override
  Future<void> restorePurchases({String? applicationUserName}) async => stream.add(restoreResult);
  @override
  Future<bool> buyConsumable({required PurchaseParam purchaseParam, bool autoConsume = true}) async {
    lastParam = purchaseParam;
    this.autoConsume = autoConsume;
    return true;
  }

  @override
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam}) async {
    buyNonConsumableCalls++;
    lastParam = purchaseParam;
    return true;
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async => completed.add(purchase.purchaseID);

  @override
  Future<ProductDetailsResponse> queryProductDetails(Set<String> identifiers) async => ProductDetailsResponse(
        productDetails: [_product('premium_monthly', 4.99), _product('premium_yearly', 49.99), _product('coin_pack_small', 0.99)],
        notFoundIDs: const [],
      );
}

ProductDetails _product(String id, double price) =>
    ProductDetails(id: id, title: id, description: '', price: '\$$price', rawPrice: price, currencyCode: 'USD');

PurchaseDetails _tx(String product, String id, PurchaseStatus status) => PurchaseDetails(
      productID: product,
      purchaseID: id,
      verificationData: PurchaseVerificationData(localVerificationData: '', serverVerificationData: 'jws-$id', source: 'app_store'),
      transactionDate: '0',
      status: status,
    )..pendingCompletePurchase = status == PurchaseStatus.purchased;

class _Rig {
  _Rig({this.premiumPlan, List<PurchaseDetails> unfinished = const [], Map<String, bool> eligible = const {}, this.verifyStatus = 200, this.verifyCode = 'verify_failed', bool anonymous = false}) {
    api = RiungApi(ApiClient(
      baseUrl: 'https://example.test',
      retryDelay: Duration.zero,
      token: (_) async => 'token',
      onError: apiErrors.add,
      client: MockClient((r) async {
        requests.add(r.url.path);
        if (r.url.path == '/v1/me') {
          if (meFails) return http.Response('{"error":{"code":"internal"}}', 500);
          return http.Response(
            jsonEncode({
              'user': {'id': 'u1', 'billingAccountId': 'play-account', 'appAccountToken': _appAccountToken},
              'wallet': {'coins': 0},
              'premium': {'status': premiumPlan == null ? 'none' : 'active', 'plan': premiumPlan},
            }),
            200,
          );
        }
        final body = jsonDecode(r.body) as Map<String, dynamic>;
        bodies.add(body);
        if (r.url.path == '/v1/billing/appstore/verify') {
          if (verifyStatus != 200) return http.Response(jsonEncode({'error': {'code': verifyCode}}), verifyStatus);
          final status = (body['productId'] as String).startsWith('premium') ? 'active' : 'credited';
          // Bentuk asli backend: hasil dibungkus `result`.
          return http.Response(jsonEncode({'result': {'productId': body['productId'], 'status': status}, 'wallet': {'coins': 80}}), 200);
        }
        if (r.url.path == '/v1/billing/appstore/restore') {
          final rows = [
            for (final p in (body['purchases'] as List).reversed)
              {'productId': p['productId'], 'transactionId': p['transactionId'], 'ok': true, 'result': {'status': 'active'}},
          ];
          return http.Response(jsonEncode({'results': rows}), 200);
        }
        return http.Response('{"error":{"code":"not_found"}}', 404);
      }),
    ));
    state = ApiState(api: api, db: LocalDatabaseService(), currentUid: () => 'u1');
    billing = BillingService(
      walletFunctions: _Wallet(),
      userRepository: _Repo(),
      currentUid: () => 'u1',
      analytics: AnalyticsService(),
      isAnonymous: () => anonymous,
      iap: store,
      apiState: state,
      store: StorePlatform.appStore,
      introOfferEligible: (id) async => eligible[id] ?? false,
      unfinishedTransactions: () async => unfinished,
    );
  }

  final String? premiumPlan;
  final int verifyStatus;
  final String verifyCode;
  final apiErrors = <ApiException>[];
  bool meFails = false;
  final store = _StoreKit();
  final requests = <String>[];
  final bodies = <Map<String, dynamic>>[];
  late final RiungApi api;
  late final ApiState state;
  late final BillingService billing;

  Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 80));

  Future<void> dispose() async {
    billing.dispose();
    state.dispose();
    await store.stream.close();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ApiConfigStore.instance.raw = {'minAppVersion': '0.0.0'};
  });

  test('beli koin iOS: appAccountToken ke StoreKit, verify App Store, finish sekali', () async {
    final rig = _Rig();
    await rig.billing.init();
    final updates = <BillingUpdate>[];
    final sub = rig.billing.updates.listen(updates.add);

    await rig.billing.buyCoinPack(_product('coin_pack_small', 0.99));
    expect(rig.store.lastParam!.applicationUserName, _appAccountToken);
    expect(rig.store.autoConsume, isTrue, reason: 'StoreKit meng-assert autoConsume true');

    final tx = _tx('coin_pack_small', '2000000111', PurchaseStatus.purchased);
    rig.store.stream.add([tx]);
    await rig.settle();
    // Transaction.updates bisa mengirim transaksi yang sama lagi.
    rig.store.stream.add([tx]);
    await rig.settle();

    expect(rig.requests, contains('/v1/billing/appstore/verify'));
    expect(rig.requests, isNot(contains('/v1/billing/verify')));
    expect(rig.bodies.first, {'productId': 'coin_pack_small', 'transactionId': '2000000111'});
    expect(rig.store.completed, ['2000000111']);
    expect(updates.last.status, BillingStatus.success);
    await sub.cancel();
    await rig.dispose();
  });

  test('verify gagal → transaksi tidak di-finish (StoreKit akan mengirim ulang)', () async {
    final rig = _Rig();
    await rig.billing.init();
    rig.store.stream.add([_tx('coin_pack_small', '', PurchaseStatus.purchased)]);
    await rig.settle();
    expect(rig.store.completed, isEmpty);
    await rig.dispose();
  });

  test('verify Premium ditolak server → error, tidak sukses, tidak di-finish', () async {
    final rig = _Rig(verifyStatus: 400);
    await rig.billing.init();
    final updates = <BillingUpdate>[];
    final sub = rig.billing.updates.listen(updates.add);
    await rig.billing.buyPremium(_product('premium_monthly', 4.99));
    rig.store.stream.add([_tx('premium_monthly', '2000000222', PurchaseStatus.purchased)]);
    await rig.settle();
    expect(rig.requests, contains('/v1/billing/appstore/verify'));
    expect(rig.store.completed, isEmpty);
    expect(updates.map((u) => u.status), isNot(contains(BillingStatus.success)));
    expect(updates.last.status, BillingStatus.error);
    await sub.cancel();
    await rig.dispose();
  });

  test('sesi anonim: transaksi tertunda tidak dikirim ke server dan tanpa toast', () async {
    final rig = _Rig(anonymous: true, unfinished: [_tx('premium_monthly', '2000000444', PurchaseStatus.purchased)]);
    await rig.billing.init();
    await rig.billing.restorePurchases();
    rig.store.stream.add([_tx('premium_monthly', '2000000445', PurchaseStatus.purchased)]);
    await rig.settle();
    expect(rig.requests, isNot(contains('/v1/billing/appstore/verify')));
    expect(rig.store.completed, isEmpty);
    expect(rig.apiErrors, isEmpty);
    await rig.dispose();
  });

  test('langganan milik akun lain: tanpa toast otomatis, pesan akun lain, tidak di-finish', () async {
    final rig = _Rig(verifyStatus: 409, verifyCode: 'purchase_invalid');
    await rig.billing.init();
    final updates = <BillingUpdate>[];
    final sub = rig.billing.updates.listen(updates.add);
    rig.store.stream.add([_tx('premium_monthly', '2000000555', PurchaseStatus.purchased)]);
    await rig.settle();
    expect(updates.last.errorKind, BillingErrorKind.otherAccount);
    expect(rig.store.completed, isEmpty);
    expect(rig.apiErrors, isEmpty);
    await sub.cancel();
    await rig.dispose();
  });

  test('restore: transaksi tertunda milik akun lain → otherAccount, bukan none', () async {
    final rig = _Rig(verifyStatus: 409, verifyCode: 'purchase_invalid', unfinished: [_tx('premium_monthly', '2000000666', PurchaseStatus.purchased)]);
    await rig.billing.init();
    expect(await rig.billing.restorePurchases(), RestoreOutcome.otherAccount);
    await rig.dispose();
  });

  test('/v1/me gagal setelah verify sukses tidak menyembunyikan apa pun: sukses hanya setelah verify', () async {
    final rig = _Rig();
    await rig.billing.init();
    final updates = <BillingUpdate>[];
    final sub = rig.billing.updates.listen(updates.add);
    await rig.billing.buyPremium(_product('premium_monthly', 4.99));
    rig.meFails = true;
    rig.store.stream.add([_tx('premium_monthly', '2000000333', PurchaseStatus.purchased)]);
    await rig.settle();
    expect(rig.requests, contains('/v1/billing/appstore/verify'));
    expect(rig.store.completed, ['2000000333']);
    expect(updates.last.status, BillingStatus.success);
    await sub.cancel();
    await rig.dispose();
  });

  test('restore iOS: /appstore/restore, baris dicocokkan lewat transactionId', () async {
    final rig = _Rig();
    await rig.billing.init();
    rig.store.restoreResult = [
      _tx('premium_monthly', '3000000001', PurchaseStatus.restored),
      _tx('premium_yearly', '3000000002', PurchaseStatus.restored),
    ];
    final outcome = await rig.billing.restorePurchases();
    expect(outcome, RestoreOutcome.restored);
    expect(rig.requests, contains('/v1/billing/appstore/restore'));
    expect(rig.bodies.single['purchases'], [
      {'productId': 'premium_monthly', 'transactionId': '3000000001'},
      {'productId': 'premium_yearly', 'transactionId': '3000000002'},
    ]);
    // Langganan hasil restore tidak di-finish ulang.
    expect(rig.store.completed, isEmpty);
    await rig.dispose();
  });

  test('restore iOS memulihkan paket koin yang belum di-finish', () async {
    final rig = _Rig(unfinished: [_tx('coin_pack_small', '2000000999', PurchaseStatus.purchased)]);
    await rig.billing.init();
    final outcome = await rig.billing.restorePurchases();
    expect(outcome, RestoreOutcome.restored);
    expect(rig.bodies.first, {'productId': 'coin_pack_small', 'transactionId': '2000000999'});
    expect(rig.store.completed, ['2000000999']);
    await rig.dispose();
  });

  test('pindah plan iOS: dibeli biasa (satu subscription group), tanpa ChangeSubscriptionParam', () async {
    final rig = _Rig(premiumPlan: 'premium_monthly');
    await rig.billing.init();
    rig.store.restoreResult = [_tx('premium_monthly', '3000000001', PurchaseStatus.restored)];
    await rig.billing.buyPremium(_product('premium_yearly', 49.99));
    expect(rig.store.buyNonConsumableCalls, 1);
    expect(rig.store.lastParam.runtimeType, PurchaseParam);
    expect(rig.store.lastParam!.applicationUserName, _appAccountToken);
    await rig.dispose();
  });

  test('Premium aktif dari Play (tidak ada di Apple ID ini) → tidak membuka pembelian kedua', () async {
    final rig = _Rig(premiumPlan: 'premium_monthly');
    await rig.billing.init();
    rig.store.restoreResult = const [];
    await expectLater(rig.billing.buyPremium(_product('premium_yearly', 49.99)), throwsStateError);
    expect(rig.store.buyNonConsumableCalls, 0);
    await rig.dispose();
  });

  test('trial iOS: hanya plan yang eligible, lamanya dari economy', () async {
    final rig = _Rig(eligible: {'premium_yearly': true, 'premium_monthly': false, 'coin_pack_small': true});
    await rig.billing.init();
    final offers = await PremiumOffer.load(rig.billing);
    expect(offers['premium_yearly']!.trialDays, 7);
    expect(offers['premium_yearly']!.recurringPrice, '\$49.99');
    expect(offers['premium_monthly']!.trialDays, isNull);
    await rig.dispose();
  });

  test('BillingResult membaca respons verify asli yang dibungkus `result`', () {
    expect(BillingResult({'result': {'status': 'credited'}, 'wallet': {}}).consumableDelivered, isTrue);
    expect(BillingResult({'status': 'active'}).subscriptionVerified, isTrue);
  });

  test('tautan kelola langganan & nama toko ikut platform', () {
    expect(StorePlatform.appStore.manageSubscriptionsUri('premium_monthly').host, 'apps.apple.com');
    expect(StorePlatform.googlePlay.manageSubscriptionsUri('premium_monthly').queryParameters['sku'], 'premium_monthly');
    expect(StorePlatform.appStore.label, 'App Store');
  });
}
