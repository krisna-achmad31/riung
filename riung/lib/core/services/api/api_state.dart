import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:timezone/timezone.dart' as tz;

import '../local_database_service.dart';
import '../local_prefs_store.dart';
import '../../models/personality_result.dart';
import 'api_client.dart';
import 'riung_api.dart';
import 'api_config_store.dart';
import '../device_time_zone.dart';

/// Shared server snapshot and durable event transport. Cache and outbox are
/// scoped by Firebase uid so logging into another account cannot replay data.
class ApiState extends ChangeNotifier with WidgetsBindingObserver {
  ApiState({
    required this.api,
    required this.db,
    required this.currentUid,
    this.presentationPrefs,
    FlutterSecureStorage? secureStorage,
  }) : secure = secureStorage ?? const FlutterSecureStorage() {
    api.onMutation = _acceptMutation;
  }
  final RiungApi api;
  final LocalDatabaseService db;
  final String? Function() currentUid;
  final FlutterSecureStorage secure;
  final LocalPrefsStore? presentationPrefs;
  void _acceptMutation(Map<String, dynamic> response) {
    final current = currentSnapshot;
    if (current == null) return;
    final next = Map<String, dynamic>.from(current.raw);
    var changed = false;
    for (final key in ['wallet', 'premium', 'streak', 'inventory', 'monsters', 'today', 'loadouts']) {
      if (response[key] is Map) { next[key] = response[key]; changed = true; }
    }
    if (changed) {
      snapshot = ApiSnapshot(next);
      notifyListeners();
    }
  }
  ApiSnapshot? snapshot;
  String? _snapshotUid;
  bool pendingSync = false;
  ApiException? lastError;
  String? lastCapReason;
  bool _flushing = false;
  int cachedFreeFocus = 0;
  Set<int> cachedFocusDurations = {};
  StreamSubscription<List<ConnectivityResult>>? _connectivity;
  Future<ApiSnapshot>? _refreshing;
  ApiSnapshot? get currentSnapshot =>
      _snapshotUid == currentUid() ? snapshot : null;
  void clearSession() {
    snapshot = null;
    _snapshotUid = null;
    cachedFreeFocus = 0;
    cachedFocusDurations = {};
    pendingSync = false;
    notifyListeners();
  }

  Future<void> clearDeletedAccountCache(String uid) async {
    await secure.delete(key: _ticketKey(uid));
    await secure.delete(key: 'api_focus_reserved_$uid');
    await (await SharedPreferences.getInstance()).remove('api_me_$uid');
    clearSession();
  }

  String dateFor(DateTime instant) {
    DeviceTimeZone.ensureInitialized();
    final zone =
        jsonObject(currentSnapshot?.raw['profile'])['tz'] as String? ??
        DeviceTimeZone.detect(now: instant.toLocal());
    final local = tz.TZDateTime.from(instant, tz.getLocation(zone));
    return '${local.year.toString().padLeft(4, '0')}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
  }

  void start() {
    WidgetsBinding.instance.addObserver(this);
    _connectivity ??= Connectivity().onConnectivityChanged.listen((results) {
      if (!results.contains(ConnectivityResult.none)) unawaited(sync());
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(bootstrap());
  }

  Future<ApiSnapshot> refresh() {
    final uid = currentUid();
    if (uid == null) {
      throw const ApiException(
        401,
        'unauthenticated',
        'Authentication required',
      );
    }
    if (_snapshotUid != uid) {
      snapshot = null;
      _snapshotUid = uid;
      _refreshing = null;
    }
    return _refreshing ??= _refresh(uid).whenComplete(() {
      if (_snapshotUid == uid) _refreshing = null;
    });
  }

  Future<ApiSnapshot> _refresh(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    try {
      if (ApiConfigStore.instance.raw.isEmpty) {
        await ApiConfigStore.instance.load(api);
      }
      final next = await api.me();
      if (currentUid() != uid) {
        throw const ApiException(401, 'account_changed', 'Account changed');
      }
      snapshot = next;
      lastError = null;
      await prefs.setString('api_me_$uid', jsonEncode(next.raw));
      await _cachePresentation(next);
      notifyListeners();
      return next;
    } on ApiException catch (e) {
      lastError = e;
      if (e.retryable && currentSnapshot != null) return currentSnapshot!;
      final cached = prefs.getString('api_me_$uid');
      if (!e.retryable || cached == null) rethrow;
      snapshot = ApiSnapshot(jsonObject(jsonDecode(cached)));
      await _cachePresentation(snapshot!);
      notifyListeners();
      return snapshot!;
    }
  }

  Future<void> _cachePresentation(ApiSnapshot me) async {
    final prefs = presentationPrefs;
    if (prefs == null) return;
    final catalog = ApiConfigStore.instance.catalog;
    final loadouts = jsonObject(me.raw['loadouts']);
    final monsterRows = jsonObject(loadouts['monsters']);
    final monsters = <String, Map<String, String>>{};
    for (final entry in monsterRows.entries) {
      final raw = entry.value;
      final ids = raw is List ? raw : jsonObject(raw)['items'] as List? ?? [];
      final slots = <String, String>{};
      for (final id in ids) {
        for (final cosmetic in catalog['monsterCosmetics'] as List? ?? []) {
          final row = jsonObject(cosmetic);
          if (row['id'] == id && row['slot'] is String) {
            slots[row['slot'] as String] = '$id';
          }
        }
      }
      monsters[entry.key] = slots;
    }
    await prefs.setMonsterCosmetics(monsters);
    final characters = jsonObject(loadouts['characters']);
    final accessories = <String, Map<String, String>>{};
    for (final entry in characters.entries) {
      final raw = jsonObject(entry.value);
      final slots = <String, String>{};
      for (final id in raw['accessories'] as List? ?? []) {
        for (final accessory in catalog['accessories'] as List? ?? []) {
          final row = jsonObject(accessory);
          if (row['id'] == id && row['slot'] is String) {
            slots[row['slot'] as String] = '$id';
          }
        }
      }
      accessories[entry.key] = slots;
      for (final test in PersonalityTest.values) {
        if (test.name == entry.key) {
          await prefs.setPersonalityCardStyle(
            test,
            raw['cardStyle'] as String? ?? 'klasik',
          );
        }
      }
    }
    await prefs.setPersonalityAccessories(accessories);
    await prefs.setOwnedCosmetics(
      (me.inventory['cosmetics'] as List? ??
              me.inventory['ownedCosmetics'] as List? ??
              [])
          .cast<String>()
          .toSet(),
    );
    await prefs.setPrepaidFocusSessions(
      (me.inventory['prepaidFocus'] as num? ?? 0).toInt(),
    );
    await prefs.setStreakShieldBalance(
      (jsonObject(me.raw['streak'])['shields'] as num? ?? 0).toInt(),
    );
  }

  void reportError(ApiException error) {
    lastError = error;
    notifyListeners();
  }

  Future<void> bootstrap() async {
    if (currentUid() == null) return;
    try {
      await ApiConfigStore.instance.load(api);
      await refresh();
      await _syncTimeZone();
      await sync();
      await prefetchTickets();
    } on ApiException catch (e) {
      lastError = e;
      notifyListeners();
    }
  }

  /// Server memakai `profile.tz` untuk batas hari (streak, cap harian).
  /// Kirim zona perangkat bila berbeda — user di WITA/WIT/luar negeri tidak
  /// lagi dihitung memakai WIB.
  Future<void> _syncTimeZone() async {
    final device = DeviceTimeZone.detect();
    final server = jsonObject(currentSnapshot?.raw['profile'])['tz'] as String?;
    if (server == device) return;
    try {
      await api.profile({'tz': device});
      await refresh();
    } on ApiException {
      // Best-effort: dicoba lagi saat bootstrap berikutnya.
    }
  }

  Future<void> record(ActivityEvent event, {String? stableId}) async {
    final uid = currentUid();
    if (uid == null) {
      throw const ApiException(
        401,
        'unauthenticated',
        'Authentication required',
      );
    }
    await db.enqueueActivity(
      stableId ?? const Uuid().v4(),
      uid,
      jsonEncode(event.toMap()),
      event.body['occurredAt'] as String,
    );
    lastCapReason = null;
    pendingSync = true;
    notifyListeners();
    await sync();
  }

  /// Satu aktivitas yang ditolak/gagal sebanyak ini dianggap gagal permanen
  /// dan dibuang dari outbox (lihat [LocalDatabaseService.dropExhaustedActivities]).
  static const maxOutboxAttempts = 10;

  Future<void> sync() async {
    final uid = currentUid();
    if (_flushing || uid == null) return;
    _flushing = true;
    try {
      final dropped = await db.dropExhaustedActivities(uid, maxOutboxAttempts);
      if (dropped > 0) {
        try {
          FirebaseCrashlytics.instance.log('outbox_dropped:$dropped');
        } catch (_) {
          /* No Firebase app in isolated tests. */
        }
      }
      while (currentUid() == uid) {
        final rows = await db.pendingActivities(uid);
        pendingSync = rows.isNotEmpty;
        if (rows.isEmpty) break;
        for (final row in rows) {
          await db.attemptActivity(row['id'] as String);
        }
        final result = await api.batch(
          rows
              .map(
                (row) => ActivityEvent.fromMap(
                  jsonObject(jsonDecode(row['body_json'] as String)),
                ),
              )
              .toList(),
        );
        final results = result['results'] as List?;
        if (results == null || results.length != rows.length) {
          throw const ApiException(
            502,
            'invalid_response',
            'Batch result count mismatch',
          );
        }
        var removed = 0;
        for (var i = 0; i < rows.length; i++) {
          final item = jsonObject(results[i]);
          final error = jsonObject(item['error']);
          final activityResult = jsonObject(item['result']);
          _acceptMutation(activityResult);
          if (activityResult['capped'] == true || item['capped'] == true) {
            lastCapReason =
                (activityResult['capReason'] ?? item['capReason']) as String? ??
                'daily_cap';
          }
          if (const {
            'invalid_request',
            'ticket_invalid',
          }.contains(error['code'])) {
            try {
              FirebaseCrashlytics.instance.log(
                'activity_rejected:${error['code']}',
              );
              if (error['requestId'] != null) {
                FirebaseCrashlytics.instance.setCustomKey(
                  'api_request_id',
                  '${error['requestId']}',
                );
              }
            } catch (_) {
              /* No Firebase app in isolated tests. */
            }
          }
          if (item['ok'] == true ||
              (error.isEmpty &&
                  (item.containsKey('result') ||
                      item.containsKey('coinsGranted') ||
                      item['replayed'] == true)) ||
              const {
                'invalid_request',
                'ticket_invalid',
              }.contains(error['code'])) {
            await db.removeActivity(rows[i]['id'] as String);
            removed++;
          }
        }
        if (removed == 0) break;
      }
      await refresh();
    } on ApiException catch (e) {
      lastError = e;
    } finally {
      _flushing = false;
      notifyListeners();
    }
  }

  String _ticketKey(String uid) => 'api_focus_tickets_$uid';
  Future<List<FocusTicket>> cachedTickets() async {
    final uid = currentUid();
    if (uid == null) return [];
    final raw = await secure.read(key: _ticketKey(uid));
    return (raw == null ? <dynamic>[] : jsonDecode(raw) as List)
        .map((e) => FocusTicket(jsonObject(e)))
        .where((t) => t.valid)
        .toList();
  }

  Future<void> _saveTickets(List<FocusTicket> tickets) async {
    final uid = currentUid();
    if (uid != null) {
      await secure.write(
        key: _ticketKey(uid),
        value: jsonEncode(tickets.map((t) => t.raw).toList()),
      );
    }
    cachedFreeFocus = tickets
        .where((t) => t.valid && t.source == 'free_daily')
        .length;
    cachedFocusDurations = tickets.where((t) => t.valid).map((t) => t.durationMin).toSet();
    notifyListeners();
  }

  Future<void> prefetchTickets() async {
    try {
      final local = await cachedTickets();
      await _saveTickets(local);
      final server = await api.tickets();
      // A locally reserved ticket must not become available again after restart.
      final used =
          await secure.read(key: 'api_focus_reserved_${currentUid()}') ?? '[]';
      final reserved = (jsonDecode(used) as List).toSet();
      final merged = {
        for (final t in [...local, ...server])
          if (!reserved.contains(t.id)) t.id: t,
      };
      if (!merged.values.any((t) => t.source == 'free_daily' && t.valid)) {
        try {
          final free = await api.issueTicket('free_daily', 25);
          merged[free.id] = free;
        } on ApiException catch (e) {
          if (e.code != 'limit_reached') rethrow;
        }
      }
      await _saveTickets(merged.values.toList());
    } on ApiException catch (e) {
      lastError = e;
    }
  }

  Future<FocusTicket> reserveFocus(int minutes, int expectedPrice) async {
    final cached = await cachedTickets();
    FocusTicket? ticket;
    for (final candidate in cached) {
      if (candidate.durationMin == minutes) {
        ticket = candidate;
        break;
      }
    }
    if (ticket == null) {
      for (final source in ['free_daily', 'prepaid', 'coins']) {
        try {
          ticket = await api.issueTicket(
            source,
            minutes,
            expectedPrice: source == 'coins' ? expectedPrice : null,
          );
          break;
        } on ApiException catch (e) {
          if (e.code != 'limit_reached' || source == 'coins') rethrow;
        }
      }
    }
    if (ticket == null) {
      throw const ApiException(409, 'ticket_invalid', 'No focus ticket');
    }
    final key = 'api_focus_reserved_${currentUid()}';
    final reserved = (jsonDecode(await secure.read(key: key) ?? '[]') as List)
        .cast<String>();
    await secure.write(key: key, value: jsonEncode([...reserved, ticket.id]));
    await _saveTickets(cached.where((t) => t.id != ticket!.id).toList());
    // A valid cached ticket must also start offline.
    try {
      await refresh();
    } on ApiException catch (e) {
      if (!e.retryable) rethrow;
    }
    return ticket;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivity?.cancel();
    api.client.close();
    super.dispose();
  }
}
