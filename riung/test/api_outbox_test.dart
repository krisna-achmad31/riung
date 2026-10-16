import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riung/core/services/local_database_service.dart';
import 'package:riung/core/services/api/api_client.dart';
import 'package:riung/core/services/api/api_config_store.dart';
import 'package:riung/core/services/api/api_state.dart';
import 'package:riung/core/services/api/riung_api.dart';

class MemoryOutbox extends LocalDatabaseService {
  final rows = <String, Map<String, Object?>>{};
  @override
  Future<void> enqueueActivity(
    String id,
    String uid,
    String body,
    String createdAt,
  ) async {
    rows.putIfAbsent(
      id,
      () => {
        'id': id,
        'user_id': uid,
        'body_json': body,
        'created_at': createdAt,
        'attempts': 0,
      },
    );
  }

  @override
  Future<List<Map<String, Object?>>> pendingActivities(String uid) async =>
      rows.values.where((r) => r['user_id'] == uid).take(50).toList();
  @override
  Future<void> removeActivity(String id) async {
    rows.remove(id);
  }

  @override
  Future<void> attemptActivity(String id) async {
    rows[id]!['attempts'] = (rows[id]!['attempts'] as int) + 1;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ApiConfigStore.instance.raw = {'minAppVersion': '0.0.0'};
  });
  test(
    'offline replay preserves event identity, batches <=50, only removes acknowledged events',
    () async {
      final db = MemoryOutbox();
      final sent = <List<dynamic>>[];
      var offline = true;
      final api = RiungApi(
        ApiClient(
          baseUrl: 'https://example.test',
          retryDelay: Duration.zero,
          token: (_) async => 'token',
          client: MockClient((request) async {
            if (request.url.path == '/v1/me')
              return http.Response('{"wallet":{"coins":5}}', 200);
            if (offline) throw http.ClientException('offline');
            final events = (jsonDecode(request.body) as Map)['events'] as List;
            sent.add(events);
            return http.Response(
              jsonEncode({
                'results': events
                    .map(
                      (_) => {
                        'ok': true,
                        'result': {'replayed': true},
                      },
                    )
                    .toList(),
              }),
              200,
            );
          }),
        ),
      );
      final state = ApiState(api: api, db: db, currentUid: () => 'alice');
      final at = DateTime.utc(2026, 10, 15);
      await state.record(
        ActivityEvent(
          ActivityType.journalSaved,
          occurredAt: at,
          entryId: 'original-entry',
        ),
        stableId: 'original',
      );
      expect(state.pendingSync, isTrue);
      expect(state.snapshot?.wallet.coins, isNull);
      expect(db.rows['original']!['body_json'], contains('original-entry'));
      for (var i = 0; i < 54; i++) {
        await db.enqueueActivity(
          'e$i',
          'alice',
          jsonEncode(
            ActivityEvent(
              ActivityType.journalSaved,
              occurredAt: at,
              entryId: 'entry-$i',
            ).toMap(),
          ),
          at.toIso8601String(),
        );
      }
      offline = false;
      await state.sync();
      expect(sent.map((b) => b.length), [50, 5]);
      expect(sent.first.first['entryId'], 'original-entry');
      expect(sent.first.first['occurredAt'], at.toIso8601String());
      expect(db.rows, isEmpty);
      expect(state.pendingSync, isFalse);
      expect(state.snapshot!.wallet.coins, 5);
      state.dispose();
    },
  );

  test(
    'outbox never crosses accounts and permanent per-event failures are discarded',
    () async {
      final db = MemoryOutbox();
      final event = ActivityEvent(
        ActivityType.focusCompleted,
        occurredAt: DateTime.utc(2026),
        ticketId: 't',
        saboteurId: 'kabut',
      );
      await db.enqueueActivity(
        'alice-event',
        'alice',
        jsonEncode(event.toMap()),
        '2026',
      );
      await db.enqueueActivity(
        'bob-event',
        'bob',
        jsonEncode(event.toMap()),
        '2026',
      );
      final api = RiungApi(
        ApiClient(
          baseUrl: 'https://example.test',
          token: (_) async => 'token',
          client: MockClient(
            (r) async => http.Response(
              r.url.path == '/v1/me'
                  ? '{"wallet":{"coins":0}}'
                  : '{"results":[{"ok":false,"error":{"code":"ticket_invalid"}}]}',
              200,
            ),
          ),
        ),
      );
      final state = ApiState(api: api, db: db, currentUid: () => 'bob');
      await state.sync();
      expect(db.rows.keys, ['alice-event']);
      state.dispose();
    },
  );

  test('date follows server timezone across a UTC day boundary', () {
    final state = ApiState(
      api: RiungApi(ApiClient(baseUrl: 'https://example.test')),
      db: MemoryOutbox(),
      currentUid: () => null,
    );
    expect(state.dateFor(DateTime.utc(2026, 10, 14, 18)), '2026-10-15');
    state.dispose();
  });

  test('mutation wallet is authoritative even if the next bootstrap is offline', () async {
    var offline = false;
    final api = RiungApi(ApiClient(baseUrl: 'https://example.test', retryDelay: Duration.zero, token: (_) async => 'token', client: MockClient((request) async {
      if (request.url.path == '/v1/shop/purchase') return http.Response('{"wallet":{"coins":80,"earnedCoins":80}}', 200);
      if (offline) throw http.ClientException('offline');
      return http.Response('{"wallet":{"coins":100,"earnedCoins":100}}', 200);
    })));
    final state = ApiState(api: api, db: MemoryOutbox(), currentUid: () => 'user');
    await state.refresh();
    expect(state.snapshot!.wallet.coins, 100);
    await api.purchase('streak_shield', 'streak_shield', 20);
    expect(state.snapshot!.wallet.coins, 80);
    offline = true;
    expect((await state.refresh()).wallet.coins, 80);
    state.dispose();
  });

  test(
    'cached focus tickets start offline and cannot be reused after a restart',
    () async {
      final ticket = {
        'id': 'signed-ticket',
        'userId': 'user',
        'durationMin': 25,
        'source': 'free_daily',
        'expiresAt': '2099-01-01T00:00:00Z',
        'kid': 'k1',
        'sig': 'signature',
      };
      FlutterSecureStorage.setMockInitialValues({
        'api_focus_tickets_user': jsonEncode([ticket]),
      });
      final state = ApiState(
        api: RiungApi(
          ApiClient(
            baseUrl: 'https://example.test',
            retryDelay: Duration.zero,
            token: (_) async => 'token',
            client: MockClient(
              (_) async => throw http.ClientException('offline'),
            ),
          ),
        ),
        db: MemoryOutbox(),
        currentUid: () => 'user',
      );
      final reserved = await state.reserveFocus(25, 25);
      expect(reserved.id, 'signed-ticket');
      expect(await state.cachedTickets(), isEmpty);
      expect(
        await state.secure.read(key: 'api_focus_reserved_user'),
        contains('signed-ticket'),
      );
      await expectLater(
        state.reserveFocus(25, 25),
        throwsA(isA<ApiException>()),
      );
      state.dispose();
    },
  );
}
