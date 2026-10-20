import '../../models/wallet.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'api_client.dart';

Map<String, dynamic> jsonObject(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : {};

class ApiSnapshot {
  ApiSnapshot(Map<String, dynamic> response)
    : raw = {
        ...response,
        'profile': response['profile'] ?? response['user'],
        'billingAccountId': response['billingAccountId'] ?? jsonObject(response['user'])['billingAccountId'],
      };
  final Map<String, dynamic> raw;
  Wallet get wallet => Wallet.fromMap(jsonObject(raw['wallet']));
  String get billingAccountId => raw['billingAccountId'] as String? ?? '';
  Map<String, dynamic> get today => jsonObject(raw['today']);
  Map<String, dynamic> get inventory => jsonObject(raw['inventory']);

  /// Plan Premium yang sedang berjalan menurut server (`active`/`in_grace`,
  /// sama dengan `ApiUserRepository.getUserProfile`), null bila tidak ada.
  String? get activePremiumPlan {
    final premium = jsonObject(raw['premium']);
    final active = premium['status'] == 'active' || premium['status'] == 'in_grace' || premium['active'] == true;
    final plan = premium['plan'];
    return active && plan is String && plan.isNotEmpty ? plan : null;
  }
}

enum ActivityType {
  checkin,
  journalSaved,
  meditationCompleted,
  bettermeLessonCompleted,
  missionCompleted,
  minigameFinished,
  focusCompleted,
}

class ActivityEvent {
  ActivityEvent._(this.body);
  factory ActivityEvent.fromMap(Map<String, dynamic> body) =>
      ActivityEvent._(body);
  factory ActivityEvent(
    ActivityType type, {
    required DateTime occurredAt,
    String? date,
    String? entryId,
    String? promptId,
    String? sessionId,
    String? lessonId,
    int? index,
    String? ref,
    String? saboteurId,
    bool? won,
    String? ticketId,
  }) {
    const names = [
      'checkin',
      'journal_saved',
      'meditation_completed',
      'betterme_lesson_completed',
      'mission_completed',
      'minigame_finished',
      'focus_completed',
    ];
    return ActivityEvent._({
      'type': names[type.index],
      'occurredAt': occurredAt.toUtc().toIso8601String(),
      'date': ?date,
      'entryId': ?entryId,
      'promptId': ?promptId,
      'sessionId': ?sessionId,
      'lessonId': ?lessonId,
      'index': ?index,
      'ref': ?ref,
      'saboteurId': ?saboteurId,
      'won': ?won,
      'ticketId': ?ticketId,
    });
  }
  final Map<String, dynamic> body;
  Map<String, dynamic> toMap() => Map.of(body);
}

class FocusTicket {
  FocusTicket(this.raw);
  final Map<String, dynamic> raw;
  String get id => raw['id'] as String;
  int get durationMin => (raw['durationMin'] as num).toInt();
  String get source => raw['source'] as String;
  DateTime get expiresAt => DateTime.parse(raw['expiresAt'] as String);
  bool get valid => expiresAt.isAfter(DateTime.now());
}

class BillingResult {
  BillingResult(this.raw);
  final Map<String, dynamic> raw;
  String get status => raw['status'] as String? ?? 'pending';
  bool get consumableDelivered =>
      status == 'credited' || status == 'already_credited';
  bool get subscriptionVerified => status == 'active' || status == 'inactive';
}

class JournalAccess {
  JournalAccess(Map<String, dynamic> raw)
    : canWrite = raw['canWrite'] == true,
      reason = raw['reason'] as String?;
  final bool canWrite;
  final String? reason;
}

class PublicContentItem {
  PublicContentItem(this.raw);
  final Map<String, dynamic> raw;
  String get id => raw['id'] as String? ?? '';
  String get title => raw['judul'] as String? ?? raw['title'] as String? ?? '';
  String get text => raw['teks'] as String? ?? raw['text'] as String? ?? '';
  String get source =>
      raw['sumber'] as String? ?? raw['source'] as String? ?? '';
  int get durationMin => (raw['durasi_min'] as num? ?? 0).toInt();
  bool get free => raw['free'] == true;
}

class UnlockGrant {
  UnlockGrant(Map<String, dynamic> raw)
    : appId = raw['appId'] as String,
      minutes = (raw['minutes'] as num).toInt();
  final String appId;
  final int minutes;
}

class UnlockResponse {
  UnlockResponse(this.raw);
  final Map<String, dynamic> raw;
  Map<String, dynamic> get result => jsonObject(raw['result']);
  List<UnlockGrant> get grants => (result['grants'] as List? ?? [])
      .map((e) => UnlockGrant(jsonObject(e)))
      .toList();
  int get paidUnlocksUsed => (result['paidUnlocksUsed'] as num? ?? 0).toInt();
  int get price => (result['price'] as num? ?? 0).toInt();
}

/// Complete public/app REST surface. Admin and Pub/Sub credentials must never
/// be included in a mobile build; their callers use separate ApiClient objects.
class RiungApi {
  RiungApi(this.client);
  final ApiClient client;
  void Function(Map<String, dynamic>)? onMutation;
  final Map<String, String> _pendingActions = {};
  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Object? body,
    Map<String, String>? query,
    bool limitedUse = false,
    String? key,
    bool reportErrors = true,
  }) async {
    final mutation =
        method != 'GET' &&
        path != '/v1/activities/batch' &&
        !path.startsWith('/v1/billing/');
    final action =
        '${client.accountId?.call()}:$method:$path:${jsonEncode(body)}';
    final actionKey =
        key ??
        (mutation
            ? _pendingActions.putIfAbsent(action, () => const Uuid().v4())
            : null);
    try {
      final response = await client.request(
        method,
        path,
        body: body,
        query: query,
        limitedUse: limitedUse,
        idempotencyKey: actionKey,
        reportErrors: reportErrors,
      );
      if (method != 'GET') onMutation?.call(response.object);
      _pendingActions.remove(action);
      return response.object;
    } on ApiException catch (e) {
      if (!e.retryable && e.status != 401 && e.status != 426) {
        _pendingActions.remove(action);
      }
      rethrow;
    }
  }

  Future<ApiResponse> health() =>
      client.request('GET', '/healthz', authenticated: false, appCheck: false);
  Future<ApiResponse> ready() =>
      client.request('GET', '/readyz', authenticated: false, appCheck: false);
  Future<ApiResponse> config({String? etag}) => client.request(
    'GET',
    '/v1/config',
    authenticated: false,
    headers: {'If-None-Match': ?etag},
  );
  Future<List<Map<String, dynamic>>> content(
    String kind, {
    String locale = 'id',
  }) async {
    const kinds = {
      'saboteurs',
      'affirmations',
      'research_facts',
      'meditations',
      'sleep_stories',
      'betterme_lessons',
    };
    if (!kinds.contains(kind)) throw ArgumentError.value(kind);
    final response = await client.request(
      'GET',
      '/v1/content/$kind',
      authenticated: false,
      query: {'locale': locale},
      reportErrors: false,
    );
    final items = response.data is List
        ? response.data as List
        : response.object['items'] as List? ?? [];
    return items.map(jsonObject).toList();
  }

  Future<void> waitlist(
    String email, {
    String lang = 'id',
    String source = 'app',
  }) async {
    await client.request(
      'POST',
      '/v1/waitlist',
      authenticated: false,
      appCheck: false,
      body: {'email': email, 'lang': lang, 'source': source, 'website': ''},
    );
  }

  Future<ApiSnapshot> me() async => ApiSnapshot(await _send('GET', '/v1/me'));
  Future<void> profile(Map<String, dynamic> fields) async {
    await _send('PATCH', '/v1/me/profile', body: fields);
  }

  Future<void> assessment({
    required List<String> dominantSaboteurs,
    required Map<String, int> scores,
    required DateTime completedAt,
  }) async {
    await _send(
      'PUT',
      '/v1/me/assessment',
      body: {
        'dominantSaboteurs': dominantSaboteurs,
        'scores': scores,
        'completedAt': completedAt.toUtc().toIso8601String(),
      },
    );
  }

  Future<void> link() async {
    await _send('POST', '/v1/me/link');
  }

  Future<Map<String, dynamic>> export() => _send('GET', '/v1/me/export');
  Future<void> deleteAccount() async {
    var uncertain = false;
    for (var attempt = 0; ; attempt++) {
      try {
        await client.request(
          'DELETE',
          '/v1/me',
          limitedUse: true,
          maxRetries: 0,
          reportErrors: false,
        );
        return;
      } on ApiException catch (e) {
        // A deleted Firebase user cannot authenticate the retry when the
        // first successful deletion response was lost in transit.
        if (uncertain && e.code == 'unauthenticated') return;
        if (!e.retryable || attempt >= 2) rethrow;
        uncertain = true;
        await Future<void>.delayed(client.retryDelay * (1 << attempt));
      }
    }
  }

  Future<void> savePin(String hash, String salt) async {
    await _send(
      'PUT',
      '/v1/me/journal-pin-backup',
      body: {'hash': hash, 'salt': salt},
    );
  }

  Future<Map<String, dynamic>> pinSalt() =>
      _send('GET', '/v1/me/journal-pin-backup', reportErrors: false);
  Future<bool> verifyPin(String hash) async =>
      (await _send(
        'POST',
        '/v1/me/journal-pin-backup/verify',
        body: {'hash': hash},
        limitedUse: true,
      ))['match'] ==
      true;
  Future<void> deletePin() async {
    await _send('DELETE', '/v1/me/journal-pin-backup');
  }

  Future<Map<String, dynamic>> activity(ActivityEvent event, {String? key}) =>
      _send('POST', '/v1/activities', body: event.toMap(), key: key);
  Future<Map<String, dynamic>> batch(List<ActivityEvent> events) {
    if (events.isEmpty || events.length > 50) {
      throw ArgumentError('Batch size must be 1..50');
    }
    return _send(
      'POST',
      '/v1/activities/batch',
      body: {'events': events.map((e) => e.toMap()).toList()},
    );
  }

  Future<Wallet> wallet() async =>
      Wallet.fromMap(await _send('GET', '/v1/wallet'));
  Future<Map<String, dynamic>> transactions({int limit = 20, String? cursor}) =>
      _send(
        'GET',
        '/v1/wallet/transactions',
        query: {'limit': '$limit', 'cursor': ?cursor},
      );
  Future<JournalAccess> journalAccess(String promptId) async => JournalAccess(
    await _send(
      'GET',
      '/v1/journal/access',
      query: {if (promptId.isNotEmpty) 'promptId': promptId},
    ),
  );
  Future<BillingResult> verifyPurchase(
    String productId,
    String purchaseToken,
  ) async => BillingResult(
    await _send(
      'POST',
      '/v1/billing/verify',
      limitedUse: true,
      body: {'productId': productId, 'purchaseToken': purchaseToken},
    ),
  );
  Future<Map<String, dynamic>> restore(
    List<({String productId, String purchaseToken})> purchases,
  ) {
    if (purchases.length > 20) throw ArgumentError('Maximum 20 purchases');
    return _send(
      'POST',
      '/v1/billing/restore',
      body: {
        'purchases': [
          for (final p in purchases)
            {'productId': p.productId, 'purchaseToken': p.purchaseToken},
        ],
      },
    );
  }

  Future<Map<String, dynamic>> subscription() =>
      _send('GET', '/v1/billing/subscription');
  Future<Map<String, dynamic>> dailyCoins() =>
      _send('POST', '/v1/premium/daily-coins');
  Future<Map<String, dynamic>> purchase(
    String itemType,
    String itemId,
    int expectedPrice,
  ) => _send(
    'POST',
    '/v1/shop/purchase',
    body: {
      'itemType': itemType,
      'itemId': itemId,
      'expectedPrice': expectedPrice,
    },
  );
  Future<void> monsterLoadout(String id, List<String> items) async {
    await _send(
      'PUT',
      '/v1/loadouts/monsters/${Uri.encodeComponent(id)}',
      body: {'items': items},
    );
  }

  Future<void> characterLoadout(
    String id,
    List<String> accessories,
    String cardStyle,
  ) async {
    await _send(
      'PUT',
      '/v1/loadouts/characters/${Uri.encodeComponent(id)}',
      body: {'accessories': accessories, 'cardStyle': cardStyle},
    );
  }

  Future<FocusTicket> issueTicket(
    String source,
    int durationMin, {
    int? expectedPrice,
  }) async {
    final response = await _send(
      'POST',
      '/v1/focus/tickets',
      reportErrors: source == 'coins',
      body: {
        'source': source,
        'durationMin': durationMin,
        'expectedPrice': ?expectedPrice,
      },
    );
    return FocusTicket(jsonObject(response['ticket']));
  }

  Future<List<FocusTicket>> tickets() async =>
      ((await _send('GET', '/v1/focus/tickets'))['tickets'] as List? ?? [])
          .map((e) => FocusTicket(jsonObject(e)))
          .toList();
  Future<UnlockResponse> unlock({
    String? appId,
    int? minutes,
    String? bundleId,
    List<String>? appIds,
    required int expectedPrice,
  }) async => UnlockResponse(
    await _send(
      'POST',
      '/v1/appbeku/unlocks',
      body: {
        'appId': ?appId,
        'minutes': ?minutes,
        'bundleId': ?bundleId,
        'appIds': ?appIds,
        'expectedPrice': expectedPrice,
      },
    ),
  );
}

class RiungAdminApi {
  RiungAdminApi(this.client);
  final ApiClient client;
  Future<ApiResponse> settings() => client.request('GET', '/admin/v1/settings');
  Future<ApiResponse> updateSetting(String key, Object value, String reason) =>
      client.request(
        'PUT',
        '/admin/v1/settings/${Uri.encodeComponent(key)}',
        body: {'value': value, 'reason': reason},
      );
  Future<ApiResponse> resetSetting(String key, String reason) => client.request(
    'DELETE',
    '/admin/v1/settings/${Uri.encodeComponent(key)}',
    body: {'reason': reason},
  );
  Future<ApiResponse> audit({int limit = 50, String? cursor}) => client.request(
    'GET',
    '/admin/v1/audit',
    query: {'limit': '$limit', 'cursor': ?cursor},
  );
}
