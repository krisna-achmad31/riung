// Jalur App Store (iOS): appAccountToken, /v1/billing/appstore/*,
// completePurchase hanya setelah server mengkredit (panduan-integrasi-app §11.6).
import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:riung/core/services/api/api_client.dart';
import 'package:riung/core/services/api/api_config_store.dart';
import 'package:riung/core/services/api/api_state.dart';
import 'package:riung/core/services/api/riung_api.dart';
import 'package:riung/core/services/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Repo extends Fake implements UserRepository {}

class _Wallet extends Fake implements WalletFunctionsService {}

class _StoreKit extends Fake implements InAppPurchase {
  final stream = StreamController<List<PurchaseDetails>>.broadcast();
  int completed = 0;
  PurchaseParam? lastParam;
  bool? lastAutoConsume;
  List<PurchaseDetails> restoreResult = const [];

  @override
  Future<bool> isAvailable() async => true;
  @override
  Stream<List<PurchaseDetails>> get purchaseStream => stream.stream;
  @override
  Future<void> restorePurchases({String? applicationUserName}) async => stream.add(restoreResult);
  @override
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam}) async {
    lastParam = purchaseParam;
    return true;
  }

  @override
  Future<bool> buyConsumable({required PurchaseParam purchaseParam, bool autoConsume = true}) async {
    lastParam = purchaseParam;
    lastAutoConsume = autoConsume;
    return true;
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async => completed++;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #getPlatformAddition) {
      throw StateError('App Store path must not use the Play platform addition');
    }
    return super.noSuchMethod(invocation);
  }
}

PurchaseDetails _transaction(String product, PurchaseStatus status, {String id = '2000000123'}) => PurchaseDetails(
      purchaseID: id,
      productID: product,
      verificationData: PurchaseVerificationData(localVerificationData: '', serverVerificationData: 'jws-$id', source: 'app_store'),
      transactionDate: '0',
      status: status,
    )..pendingCompletePurchase = true;

final _product = ProductDetails(id: 'coin_pack_small', title: '', description: '', price: 'Rp15.000', rawPrice: 15000, currencyCode: 'IDR');

class _Rig {
  _Rig(http.Response Function(http.Request r) server) {
    api = RiungApi(ApiClient(
      baseUrl: 'https://example.test',
      platform: 'ios',
      retryDelay: Duration.zero,
      token: (_) async => 'token',
      client: MockClient((r) async {
        requests.add(r);
        if (r.url.path == '/v1/me') {
          return _json({'user': {'billingAccountId': 'ba-A', 'appAccountToken': 'aat-A'}, 'wallet': {'coins': 0}});
        }
        return server(r);
      }),
    ));
    state = ApiState(api: api, db: LocalDatabaseService(), currentUid: () => 'user');
    billing = BillingService(
      walletFunctions: _Wallet(),
      userRepository: _Repo(),
      currentUid: () => 'user',
      analytics: AnalyticsService(),
      isAnonymous: () => false,
      iap: store,
      apiState: state,
      appStore: true,
    );
  }
  final store = _StoreKit();
  final requests = <http.Request>[];
  late final RiungApi api;
  late final ApiState state;
  late final BillingService billing;

  Iterable<http.Request> at(String path) => requests.where((r) => r.url.path == path);

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    ApiConfigStore.instance.raw = {'minAppVersion': '0.0.0'};
  });

  test('beli koin: applicationUserName = appAccountToken, tanpa autoConsume: false', () async {
    final rig = _Rig((r) => _json({}));
    await rig.billing.init();
    await rig.billing.buyCoinPack(_product);
    expect(rig.store.lastParam!.applicationUserName, 'aat-A');
    expect(rig.store.lastAutoConsume, isTrue);
  });

  test('beli Premium: PurchaseParam biasa dengan appAccountToken', () async {
    final rig = _Rig((r) => _json({}));
    await rig.billing.init();
    await rig.billing.buyPremium(ProductDetails(id: 'premium_monthly', title: '', description: '', price: '', rawPrice: 0, currencyCode: 'IDR'));
    expect(rig.store.lastParam.runtimeType, PurchaseParam);
    expect(rig.store.lastParam!.applicationUserName, 'aat-A');
  });

  test('purchased → appstore/verify {productId, transactionId} + Idempotency-Key + X-Platform ios → complete', () async {
    final rig = _Rig((r) => _json({'status': 'credited'}));
    final updates = await rig.run(() async => rig.store.stream.add([_transaction('coin_pack_small', PurchaseStatus.purchased)]));
    final verify = rig.at('/v1/billing/appstore/verify').single;
    expect(jsonDecode(verify.body), {'productId': 'coin_pack_small', 'transactionId': '2000000123'});
    expect(verify.headers['Idempotency-Key'], isNotEmpty);
    expect(verify.headers['X-Platform'], 'ios');
    expect(rig.at('/v1/billing/verify'), isEmpty);
    expect(rig.store.completed, 1);
    expect(updates.single.status, BillingStatus.success);
  });

  for (final status in ['already_credited', 'active', 'inactive']) {
    test('status $status → completePurchase', () async {
      final rig = _Rig((r) => _json({'status': status}));
      await rig.run(() async => rig.store.stream.add([_transaction('premium_monthly', PurchaseStatus.purchased)]));
      expect(rig.store.completed, 1);
    });
  }

  test('409 purchase_invalid → tidak di-complete, deliveryFailed', () async {
    final rig = _Rig((r) => _json({'error': {'code': 'purchase_invalid', 'requestId': 'req-1'}}, 409));
    final updates = await rig.run(() async => rig.store.stream.add([_transaction('coin_pack_small', PurchaseStatus.purchased)]));
    expect(rig.store.completed, 0);
    expect(updates.single.errorKind, BillingErrorKind.deliveryFailed);
  });

  test('403 permanent_account_required → tidak di-complete', () async {
    final rig = _Rig((r) => _json({'error': {'code': 'permanent_account_required'}}, 403));
    final updates = await rig.run(() async => rig.store.stream.add([_transaction('premium_monthly', PurchaseStatus.purchased)]));
    expect(rig.store.completed, 0);
    expect(updates.single.status, BillingStatus.error);
  });

  test('status pending → tidak di-complete', () async {
    final rig = _Rig((r) => _json({'status': 'pending'}));
    await rig.run(() async => rig.store.stream.add([_transaction('coin_pack_small', PurchaseStatus.purchased)]));
    expect(rig.store.completed, 0);
  });

  test('Idempotency-Key sama untuk transaksi yang sama saat dikirim ulang StoreKit', () async {
    var fail = true;
    final rig = _Rig((r) => fail ? _json({'error': {'code': 'internal'}}, 500) : _json({'status': 'credited'}));
    await rig.run(() async => rig.store.stream.add([_transaction('coin_pack_small', PurchaseStatus.purchased)]));
    expect(rig.store.completed, 0);
    fail = false;
    rig.store.stream.add([_transaction('coin_pack_small', PurchaseStatus.purchased)]);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    final keys = rig.at('/v1/billing/appstore/verify').map((r) => r.headers['Idempotency-Key']).toSet();
    expect(keys, hasLength(1));
    expect(rig.store.completed, 1);
  });

  test('restore → appstore/restore, baris dicocokkan lewat transactionId', () async {
    final rig = _Rig((r) => _json({
          'results': [
            {'productId': 'premium_yearly', 'transactionId': 't-2', 'ok': true, 'result': {'status': 'active'}},
            {'productId': 'premium_monthly', 'transactionId': 't-1', 'ok': false, 'error': {'code': 'purchase_invalid'}},
          ],
        }));
    rig.store.restoreResult = [
      _transaction('premium_monthly', PurchaseStatus.restored, id: 't-1'),
      _transaction('premium_yearly', PurchaseStatus.restored, id: 't-2'),
    ];
    RestoreOutcome? outcome;
    await rig.run(() async => outcome = await rig.billing.restorePurchases());
    final restore = rig.at('/v1/billing/appstore/restore').single;
    expect(jsonDecode(restore.body), {
      'purchases': [
        {'productId': 'premium_monthly', 'transactionId': 't-1'},
        {'productId': 'premium_yearly', 'transactionId': 't-2'},
      ],
    });
    expect(restore.headers['Idempotency-Key'], isNotEmpty);
    expect(rig.at('/v1/billing/restore'), isEmpty);
    expect(rig.store.completed, 1, reason: 'hanya t-2 yang terverifikasi');
    expect(outcome, RestoreOutcome.restored);
  });
}
