import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:riung/core/services/services.dart';
import 'package:riung/core/services/api/api_client.dart';
import 'package:riung/core/services/api/api_config_store.dart';
import 'package:riung/core/services/api/api_state.dart';
import 'package:riung/core/services/api/riung_api.dart';

class FakeRepository extends Fake implements UserRepository {}

class FakeWallet extends Fake implements WalletFunctionsService {}

class FakeAndroid extends Fake implements InAppPurchaseAndroidPlatformAddition {
  int consumed = 0;
  @override
  Future<BillingResultWrapper> consumePurchase(PurchaseDetails purchase) async {
    consumed++;
    return const BillingResultWrapper(responseCode: BillingResponse.ok);
  }
}

class FakePlay extends Fake implements InAppPurchase {
  final stream = StreamController<List<PurchaseDetails>>.broadcast();
  final android = FakeAndroid();
  int completed = 0;
  bool? autoConsume;
  String? account;
  @override
  Future<bool> isAvailable() async => true;
  @override
  Stream<List<PurchaseDetails>> get purchaseStream => stream.stream;
  @override
  Future<void> restorePurchases({String? applicationUserName}) async {}
  @override
  Future<bool> buyConsumable({
    required PurchaseParam purchaseParam,
    bool autoConsume = true,
  }) async {
    this.autoConsume = autoConsume;
    account = purchaseParam.applicationUserName;
    return true;
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {
    completed++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #getPlatformAddition) return android;
    return super.noSuchMethod(invocation);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ApiConfigStore.instance.raw = {'minAppVersion': '0.0.0'};
  });

  for (final scenario in [
    (
      status: 'credited',
      product: 'coin_pack_small',
      consume: 1,
      acknowledge: 0,
    ),
    (status: 'active', product: 'premium_yearly', consume: 0, acknowledge: 1),
    (status: 'pending', product: 'coin_pack_small', consume: 0, acknowledge: 0),
    (status: 'invalid', product: 'coin_pack_small', consume: 0, acknowledge: 0),
    (
      status: 'unavailable',
      product: 'coin_pack_small',
      consume: 0,
      acknowledge: 0,
    ),
  ]) {
    test(
      'Play ${scenario.status}: consume/acknowledge follows verified server status',
      () async {
        final play = FakePlay();
        final serverRequests = <String>[];
        final api = RiungApi(
          ApiClient(
            baseUrl: 'https://example.test',
            retryDelay: Duration.zero,
            token: (_) async => 'token',
            client: MockClient((r) async {
              serverRequests.add(r.url.path);
              if (r.url.path == '/v1/me')
                return http.Response(
                  '{"billingAccountId":"billing-account","wallet":{"coins":80}}',
                  200,
                );
              if (scenario.status == 'invalid')
                return http.Response(
                  '{"error":{"code":"purchase_invalid"}}',
                  409,
                );
              if (scenario.status == 'unavailable')
                return http.Response('{"error":{"code":"unavailable"}}', 503);
              return http.Response(
                jsonEncode({'status': scenario.status}),
                200,
              );
            }),
          ),
        );
        final state = ApiState(
          api: api,
          db: LocalDatabaseService(),
          currentUid: () => 'user',
        );
        final billing = BillingService(
          walletFunctions: FakeWallet(),
          userRepository: FakeRepository(),
          currentUid: () => 'user',
          analytics: AnalyticsService(),
          isAnonymous: () => false,
          iap: play,
          apiState: state,
        );
        await billing.init();
        final updates = <BillingUpdate>[];
        final subscription = billing.updates.listen(updates.add);
        final purchase = PurchaseDetails(
          productID: scenario.product,
          verificationData: PurchaseVerificationData(
            localVerificationData: '',
            serverVerificationData: 'receipt',
            source: 'google_play',
          ),
          transactionDate: '1',
          status: PurchaseStatus.purchased,
        )..pendingCompletePurchase = true;
        play.stream.add([purchase]);
        await Future<void>.delayed(const Duration(milliseconds: 80));
        expect(serverRequests, contains('/v1/billing/verify'));
        expect(play.android.consumed, scenario.consume);
        expect(play.completed, scenario.acknowledge);
        if (scenario.consume + scenario.acknowledge > 0)
          expect(updates.last.status, BillingStatus.success);
        if (scenario.status == 'invalid' || scenario.status == 'unavailable')
          expect(updates.last.status, BillingStatus.error);
        if (scenario.status == 'pending')
          expect(
            updates.where((u) => u.status == BillingStatus.success),
            isEmpty,
          );
        await subscription.cancel();
        billing.dispose();
        state.dispose();
        await play.stream.close();
      },
    );
  }
  test(
    'coin purchase disables autoConsume and sends server billing account to Play',
    () async {
      final play = FakePlay();
      final api = RiungApi(
        ApiClient(
          baseUrl: 'https://example.test',
          token: (_) async => 'token',
          client: MockClient(
            (_) async => http.Response(
              '{"billingAccountId":"billing-123","wallet":{"coins":0}}',
              200,
            ),
          ),
        ),
      );
      final state = ApiState(
        api: api,
        db: LocalDatabaseService(),
        currentUid: () => 'user',
      );
      final billing = BillingService(
        walletFunctions: FakeWallet(),
        userRepository: FakeRepository(),
        currentUid: () => 'user',
        analytics: AnalyticsService(),
        isAnonymous: () => false,
        iap: play,
        apiState: state,
      );
      await billing.buyCoinPack(
        ProductDetails(
          id: 'coin_pack_small',
          title: 'Coins',
          description: '',
          price: 'Rp15.000',
          rawPrice: 15000,
          currencyCode: 'IDR',
        ),
      );
      expect(play.autoConsume, isFalse);
      expect(play.account, 'billing-123');
      billing.dispose();
      state.dispose();
      await play.stream.close();
    },
  );
}
