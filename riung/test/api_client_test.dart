import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:riung/core/services/api/api_client.dart';
import 'package:riung/core/services/api/riung_api.dart';
import '../tool/google_play_webhook_client.dart';

void main() {
  test('admin and RTDN use separately configured clients and documented routes', () async {
    final calls = <String>[];
    final client = ApiClient(baseUrl: 'http://172.19.0.16:8081', allowPrivateHttp: true, token: (_) async => 'separate-admin-token', client: MockClient((r) async {
      calls.add('${r.method} ${r.url.path}');
      expect(r.headers['Authorization'], 'Bearer separate-admin-token');
      return http.Response('{}', 200);
    }));
    final admin = RiungAdminApi(client);
    await admin.settings();
    await admin.updateSetting('journalRewardsPerDay', 4, 'test');
    await admin.resetSetting('journalRewardsPerDay', 'reset');
    await admin.audit();
    await GooglePlayWebhookClient(client).send(base64Data: 'e30=', messageId: 'message', subscription: 'dev-subscription');
    expect(calls, ['GET /admin/v1/settings', 'PUT /admin/v1/settings/journalRewardsPerDay', 'DELETE /admin/v1/settings/journalRewardsPerDay', 'GET /admin/v1/audit', 'POST /v1/webhooks/google-play']);
    expect(() => ApiClient(baseUrl: 'http://public.example.test', allowPrivateHttp: true), throwsArgumentError);
  });

  test('a user retry preserves an uncertain financial action key', () async {
    final keys = <String?>[];
    var online = false;
    final api = RiungApi(ApiClient(baseUrl: 'https://example.test', retryDelay: Duration.zero, token: (_) async => 'token', client: MockClient((r) async {
      keys.add(r.headers['Idempotency-Key']);
      if (!online) throw http.ClientException('offline');
      return http.Response('{"wallet":{"coins":0}}', 200);
    })));
    await expectLater(api.purchase('focus_pack', 'focus_5', 100), throwsA(isA<ApiException>()));
    online = true;
    await api.purchase('focus_pack', 'focus_5', 100);
    expect(keys.toSet().length, 1);
    await api.purchase('focus_pack', 'focus_5', 100);
    expect(keys.toSet().length, 2);
  });

  test('lost delete reply followed by unauthenticated means deletion completed', () async {
    var calls = 0;
    final api = RiungApi(ApiClient(baseUrl: 'https://example.test', retryDelay: Duration.zero, token: (_) async => 'token', client: MockClient((_) async {
      calls++;
      if (calls == 1) throw http.ClientException('reply lost');
      return http.Response('{"error":{"code":"unauthenticated"}}', 401);
    })));
    await api.deleteAccount();
    expect(calls, 3);
  });
  test(
    '401 refresh preserves the action body/key and refreshes both tokens',
    () async {
      final requests = <http.Request>[];
      final authRefreshes = <bool>[];
      final checkRefreshes = <bool>[];
      final client = ApiClient(
        baseUrl: 'https://example.test',
        token: (force) async {
          authRefreshes.add(force);
          return force ? 'new' : 'old';
        },
        appCheckToken: (limited, force) async {
          checkRefreshes.add(force);
          return force ? 'fresh-check' : 'check';
        },
        client: MockClient((request) async {
          requests.add(request);
          return requests.length == 1
              ? http.Response('{"error":{"code":"unauthenticated"}}', 401)
              : http.Response('{"wallet":{"coins":5}}', 200);
        }),
      );
      await client.request(
        'POST',
        '/v1/activities',
        body: {'type': 'checkin'},
        idempotencyKey: 'stable-action',
      );
      expect(authRefreshes, [false, true]);
      expect(checkRefreshes, [false, true]);
      expect(
        requests.map((r) => r.headers['Idempotency-Key']),
        everyElement('stable-action'),
      );
      expect(requests[0].body, requests[1].body);
      expect(requests.last.headers['Authorization'], 'Bearer new');
      expect(requests.last.headers['X-Firebase-AppCheck'], 'fresh-check');
    },
  );

  test(
    '503 retries with the same generated key and never retries domain 409',
    () async {
      final keys = <String?>[];
      final client = ApiClient(
        baseUrl: 'https://example.test',
        retryDelay: Duration.zero,
        token: (_) async => 'token',
        client: MockClient((r) async {
          keys.add(r.headers['Idempotency-Key']);
          return keys.length < 3
              ? http.Response('{"error":{"code":"unavailable"}}', 503)
              : http.Response(
                  '{"error":{"code":"price_changed","requestId":"r1","details":{"price":200}}}',
                  409,
                );
        }),
      );
      await expectLater(
        client.request('POST', '/v1/shop/purchase', body: {'itemId': 'hat'}),
        throwsA(
          isA<ApiException>()
              .having((e) => e.code, 'code', 'price_changed')
              .having((e) => e.requestId, 'requestId', 'r1'),
        ),
      );
      expect(keys.length, 3);
      expect(keys.toSet().length, 1);
      expect(keys.first, isNotEmpty);
    },
  );

  test(
    'recent login is not silently refreshed; redirects cannot leak auth',
    () async {
      var calls = 0;
      final client = ApiClient(
        baseUrl: 'https://example.test',
        token: (_) async => 'secret',
        client: MockClient((r) async {
          calls++;
          expect(r.followRedirects, isFalse);
          return http.Response(
            '{"error":{"code":"recent_login_required"}}',
            401,
          );
        }),
      );
      await expectLater(
        client.request('DELETE', '/v1/me', limitedUse: true),
        throwsA(isA<ApiException>()),
      );
      expect(calls, 1);
      await expectLater(
        client.request('GET', 'https://evil.test/steal'),
        throwsArgumentError,
      );
      expect(calls, 1);
    },
  );

  test(
    'public endpoints omit auth and handle ETag 304/204 empty body',
    () async {
      final client = ApiClient(
        baseUrl: 'http://10.0.2.2:8080',
        client: MockClient((r) async {
          expect(r.headers.containsKey('Authorization'), isFalse);
          expect(r.headers['X-App-Version'], '1.0.0');
          expect(r.headers['If-None-Match'], 'etag-1');
          return http.Response('', 304);
        }),
      );
      final response = await RiungApi(client).config(etag: 'etag-1');
      expect(response.status, 304);
      expect(response.object, isEmpty);
    },
  );

  test(
    'limited-use tokens on verify/delete/PIN; no idempotency on excluded operations',
    () async {
      final limitedUses = <bool>[];
      final client = ApiClient(
        baseUrl: 'https://example.test',
        token: (_) async => 'token',
        appCheckToken: (limited, _) async {
          limitedUses.add(limited);
          return 'one-use-${limitedUses.length}';
        },
        client: MockClient((r) async {
          if (r.url.path == '/v1/billing/verify') {
            expect(r.headers['Idempotency-Key'], isNotEmpty);
            expect(jsonDecode(r.body), {
              'productId': 'premium_yearly',
              'purchaseToken': 'receipt',
            });
            return http.Response('{"status":"active"}', 200);
          }
          expect(r.headers.containsKey('Idempotency-Key'), isFalse);
          return r.method == 'DELETE'
              ? http.Response('', 204)
              : http.Response('{"match":true}', 200);
        }),
      );
      final api = RiungApi(client);
      await api.verifyPurchase('premium_yearly', 'receipt');
      await api.verifyPin('salted-hash');
      await api.deleteAccount();
      expect(limitedUses, [true, true, true]);
    },
  );

  test('all Postman app domains send documented paths and bodies', () async {
    final paths = <String>[];
    final client = ApiClient(
      baseUrl: 'https://example.test',
      token: (_) async => 'token',
      client: MockClient((r) async {
        paths.add('${r.method} ${r.url.path}');
        if (r.url.path == '/v1/content/saboteurs')
          return http.Response('{"items":[]}', 200);
        if (r.url.path == '/v1/focus/tickets' && r.method == 'POST')
          return http.Response(
            '{"ticket":{"id":"t","durationMin":25,"source":"coins","expiresAt":"2099-01-01T00:00:00Z"}}',
            200,
          );
        return http.Response('{}', 200);
      }),
    );
    final api = RiungApi(client);
    await api.health();
    await api.ready();
    await api.me();
    await api.profile({'displayName': 'Rani'});
    await api.assessment(
      dominantSaboteurs: ['kabut'],
      scores: {'kabut': 64},
      completedAt: DateTime.utc(2026),
    );
    await api.link();
    await api.export();
    await api.savePin('hash', 'salt');
    await api.pinSalt();
    await api.deletePin();
    await api.activity(
      ActivityEvent(
        ActivityType.checkin,
        occurredAt: DateTime.utc(2026),
        date: '2026-01-01',
      ),
    );
    await api.batch([
      ActivityEvent(
        ActivityType.journalSaved,
        occurredAt: DateTime.utc(2026),
        entryId: 'entry',
      ),
    ]);
    await api.wallet();
    await api.transactions(cursor: 'cursor');
    await api.journalAccess('p_kabut');
    await api.restore([
      (productId: 'coin_pack_small', purchaseToken: 'receipt'),
    ]);
    await api.subscription();
    await api.dailyCoins();
    await api.purchase('cosmetic', 'topi_rajut', 100);
    await api.monsterLoadout('kabut', ['topi_rajut']);
    await api.characterLoadout('jung', ['beanie'], 'taman');
    await api.issueTicket('coins', 25, expectedPrice: 25);
    await api.tickets();
    await api.unlock(bundleId: 'santai', expectedPrice: 35);
    await api.content('saboteurs');
    await api.waitlist('example@example.com');
    expect(paths.toSet().length, 26);
    expect(
      paths,
      containsAll([
        'POST /v1/activities/batch',
        'PUT /v1/loadouts/characters/jung',
        'POST /v1/appbeku/unlocks',
      ]),
    );
  });
}
