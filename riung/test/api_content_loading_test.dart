import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:riung/core/services/services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('live /me user shape restores completed onboarding and billing account', () async {
    ApiConfigStore.instance.raw = {'minAppVersion': '0.0.0'};
    final api = RiungApi(ApiClient(baseUrl: 'https://example.test', token: (_) async => 'token', client: MockClient((r) async =>
      http.Response('{"user":{"id":"backend-user","billingAccountId":"billing-id","displayName":"Rani","locale":"id","onboardingDone":true,"tz":"Asia/Makassar"},"wallet":{"coins":0}}', 200))));
    final state = ApiState(api: api, db: LocalDatabaseService(), currentUid: () => 'firebase-user');
    final repository = ApiUserRepository(state: state, prefs: await LocalPrefsStore.init(), db: LocalDatabaseService(), crypto: JournalCryptoService());
    final profile = await repository.getUserProfile('firebase-user');
    expect(profile.onboardingDone, isTrue);
    expect(profile.displayName, 'Rani');
    expect(state.snapshot!.billingAccountId, 'billing-id');
    expect(state.dateFor(DateTime.utc(2026, 10, 14, 16, 30)), '2026-10-15');
    state.dispose();
    ApiConfigStore.instance.raw = {};
  });

  test('concurrent content loads complete and release their in-flight request', () async {
    var calls = 0;
    final client = ApiClient(baseUrl: 'https://example.test', client: MockClient((r) async {
      calls++;
      return http.Response(jsonEncode({'items': [{'id': 'kabut', 'nama': 'Si Kabut', 'distorsi_cbt': '', 'warna': '#9AA2B8', 'deskripsi': '', 'tanda': [], 'cara_menjinakkan': '', 'fakta_riset': ''}]}), 200);
    }));
    final content = ApiContentRepository(RiungApi(client));
    final loads = await Future.wait([content.getSaboteurs(), content.getSaboteurs()]).timeout(const Duration(seconds: 2));
    expect(loads[0].single.id, 'kabut');
    expect(loads[1].single.id, 'kabut');
    expect(calls, 1);
    expect((await content.getSaboteurs().timeout(const Duration(seconds: 2))).single.id, 'kabut');
    expect(calls, 1);
    client.close();
  });

  test('a non-completing App Check provider has a bounded timeout', () async {
    var calls = 0;
    final client = ApiClient(baseUrl: 'https://example.test', timeout: const Duration(milliseconds: 10), retryDelay: Duration.zero,
      appCheckToken: (_, _) => Completer<String?>().future,
      client: MockClient((r) async { calls++; return http.Response('{}', 200); }));
    await expectLater(client.request('GET', '/v1/config', authenticated: false), throwsA(isA<ApiException>().having((e) => e.code, 'code', 'timeout')));
    expect(calls, 0);
    client.close();
  });
}
