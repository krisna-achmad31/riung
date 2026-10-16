import '../../models/affirmation.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/coin_transaction.dart';
import '../../models/journal_pin_backup.dart';
import '../../models/monster_progress.dart';
import '../../models/saboteur.dart';
import '../../models/user_profile.dart';
import '../../models/wallet.dart';
import '../content_repository.dart';
import '../local_user_repository.dart';
import '../wallet_functions_service.dart';
import 'api_config_store.dart';
import 'api_client.dart';
import 'api_state.dart';
import 'riung_api.dart';

class ApiUserRepository extends LocalUserRepository {
  ApiUserRepository({
    required this.state,
    required super.prefs,
    required super.db,
    required super.crypto,
  });
  final ApiState state;
  Future<ApiSnapshot> _me() async =>
      state.currentSnapshot ?? await state.refresh();

  @override
  Future<UserProfile> getUserProfile(String uid) async {
    final raw = (await _me()).raw;
    final premium = jsonObject(raw['premium']);
    return UserProfile.fromMap(uid, {
      ...raw,
      'premium': {
        ...premium,
        'active':
            premium['status'] == 'active' ||
            premium['status'] == 'in_grace' ||
            premium['active'] == true,
        'renewsAt': premium['expiresAt'] ?? premium['renewsAt'],
      },
    });
  }

  @override
  Future<Wallet> getWallet(String uid) async => (await _me()).wallet;
  @override
  Future<Map<String, MonsterProgress>> getMonsterProgress(String uid) async =>
      jsonObject((await _me()).raw['monsters']).map(
        (id, value) =>
            MapEntry(id, MonsterProgress.fromMap(id, jsonObject(value))),
      );
  @override
  Future<void> saveUserProfile(UserProfile profile) async {
    final old = await getUserProfile(profile.uid);
    final before = jsonObject(old.toMap()['profile']);
    final after = jsonObject(profile.toMap()['profile'])..remove('createdAt');
    after.removeWhere((key, value) => value == before[key] || value == null);
    if (after.isNotEmpty) await state.api.profile(after);
    if (profile.assessmentCompletedAt != null &&
        (profile.assessmentCompletedAt != old.assessmentCompletedAt ||
            profile.assessmentScores.toString() !=
                old.assessmentScores.toString())) {
      await state.api.assessment(
        dominantSaboteurs: profile.dominantSaboteurs,
        scores: profile.assessmentScores,
        completedAt: profile.assessmentCompletedAt!,
      );
    }
    // Premium, streak, wallet and monster progress are server-owned.
    await state.refresh();
  }

  @override
  Future<void> saveMonsterProgress(
    String uid,
    Map<String, MonsterProgress> progress,
  ) async {}
  @override
  Future<void> saveJournalPinBackup(String uid, JournalPinBackup backup) =>
      state.api.savePin(backup.hash, backup.salt);
  @override
  Future<JournalPinBackup?> getJournalPinBackup(String uid) async {
    try {
      return JournalPinBackup.fromMap(await state.api.pinSalt());
    } on ApiException catch (e) {
      if (e.status == 404) return null;
      rethrow;
    }
  }

  Future<bool> verifyJournalPin(String hash) => state.api.verifyPin(hash);
  @override
  Future<void> deleteCloudData(String uid) => state.api.deleteAccount();
  @override
  Future<void> migrateAnonymousSnapshot({
    required String uid,
    required Wallet wallet,
    required UserProfile profile,
    required Map<String, MonsterProgress> monsterProgress,
  }) async {
    await state.api.link();
    await state.refresh();
  }
}

/// Compatibility boundary for existing UI. Arbitrary earn/spend/progress
/// deltas never reach the backend; only the documented domain operations do.
class ApiWalletFunctionsService implements WalletFunctionsService {
  ApiWalletFunctionsService(this.state);
  final ApiState state;
  String _date(DateTime now) => state.dateFor(now);
  @override
  Future<Wallet> earnCoins({
    required String uid,
    required int amount,
    required String reason,
  }) async {
    final now = DateTime.now();
    final parts = reason.split(':');
    ActivityEvent? event;
    switch (parts.first) {
      case 'daily_checkin':
        event = ActivityEvent(
          ActivityType.checkin,
          occurredAt: now,
          date: _date(now),
        );
      case 'jurnal':
        event = ActivityEvent(
          ActivityType.journalSaved,
          occurredAt: now,
          entryId: parts[1],
        );
      case 'meditasi':
        event = ActivityEvent(
          ActivityType.meditationCompleted,
          occurredAt: now,
          sessionId: parts[1],
        );
      case 'betterme':
        event = ActivityEvent(
          ActivityType.bettermeLessonCompleted,
          occurredAt: now,
          lessonId: parts[1],
        );
      case 'misi_harian':
        event = ActivityEvent(
          ActivityType.missionCompleted,
          occurredAt: now,
          date: _date(now),
          index: int.parse(parts[2]),
        );
      case 'premium_daily':
        await state.api.dailyCoins();
        await state.refresh();
      default:
        throw UnsupportedError('Use a typed server activity for $reason');
    }
    if (event != null) await state.record(event);
    return state.snapshot?.wallet ?? Wallet.zero();
  }

  @override
  Future<Wallet> spendCoins({
    required String uid,
    required int amount,
    required String reason,
  }) async {
    final parts = reason.split(':');
    try {
      switch (parts.first) {
        case 'cosmetic':
          await state.api.purchase('cosmetic', parts[1], amount);
        case 'cosmetic_bundle':
          await state.api.purchase('cosmetic_bundle', parts[1], amount);
        case 'streak_shield':
          await state.api.purchase('streak_shield', 'streak_shield', amount);
        case 'prepaid_focus_sessions':
          await state.api.purchase('focus_pack', 'focus_${parts[1]}', amount);
        default:
          throw UnsupportedError('Use a typed server operation for $reason');
      }
      return (await state.refresh()).wallet;
    } on ApiException catch (e) {
      if (e.code == 'price_changed' || e.code == 'not_found') {
        await ApiConfigStore.instance.load(state.api);
        await state.refresh();
      }
      if (e.code == 'already_owned' || e.code == 'not_owned') {
        await state.refresh();
      }
      if (e.code == 'insufficient_coins') {
        final d = jsonObject(e.details);
        throw InsufficientCoinsException(
          (d['balance'] as num? ?? 0).toInt(),
          amount,
        );
      }
      rethrow;
    }
  }

  @override
  Future<Wallet> dailyCheckin({required String uid}) =>
      earnCoins(uid: uid, amount: 0, reason: 'daily_checkin');
  @override
  Future<MonsterProgress> tameProgress({
    required String uid,
    required String saboteurId,
    required int delta,
  }) async {
    final me = state.snapshot ?? await state.refresh();
    return MonsterProgress.fromMap(
      saboteurId,
      jsonObject(jsonObject(me.raw['monsters'])[saboteurId]),
    );
  }

  @override
  Future<List<CoinTransaction>> getTransactions({
    required String uid,
    int limit = 50,
  }) async {
    final page = await state.api.transactions(limit: limit);
    return (page['items'] as List? ?? page['transactions'] as List? ?? []).map((
      e,
    ) {
      final raw = jsonObject(e);
      return CoinTransaction.fromMap(raw['id'] as String? ?? '', raw);
    }).toList();
  }
}

class ApiContentRepository implements ContentRepository {
  ApiContentRepository(
    this.api, {
    this.locale = 'id',
    ContentRepository? fallback,
  }) : fallback = fallback ?? StubContentRepository();
  final RiungApi api;
  final String locale;
  final ContentRepository fallback;
  final Map<String, List<Map<String, dynamic>>> _cache = {};
  final Map<String, Future<List<Map<String, dynamic>>>> _loading = {};
  Future<List<Map<String, dynamic>>> _content(String kind) =>
      _loading[kind] ??= _load(kind).whenComplete(() {
        _loading.remove(kind);
      });
  Future<List<Map<String, dynamic>>> _load(String kind) async {
    if (_cache.containsKey(kind)) return _cache[kind]!;
    final prefs = await SharedPreferences.getInstance();
    final key = 'api_content_${api.client.baseUri.origin}_${locale}_$kind';
    try {
      final items = await api.content(kind, locale: locale);
      _cache[kind] = items;
      await prefs.setString(key, jsonEncode(items));
      return items;
    } on ApiException catch (e) {
      if (e.status == 426) rethrow;
      final cached = prefs.getString(key);
      return cached == null
          ? []
          : (jsonDecode(cached) as List).map(jsonObject).toList();
    }
  }

  Future<List<PublicContentItem>> getResearchFacts() async =>
      (await _content('research_facts')).map(PublicContentItem.new).toList();
  Future<List<PublicContentItem>> getMeditations() async =>
      (await _content('meditations')).map(PublicContentItem.new).toList();
  Future<List<PublicContentItem>> getSleepStories() async =>
      (await _content('sleep_stories')).map(PublicContentItem.new).toList();
  Future<List<PublicContentItem>> getBetterMeLessons() async =>
      (await _content('betterme_lessons')).map(PublicContentItem.new).toList();
  Future<void> warm() async {
    await Future.wait([
      getResearchFacts(),
      getMeditations(),
      getSleepStories(),
      getBetterMeLessons(),
    ]);
  }

  @override
  Future<List<Saboteur>> getSaboteurs() async {
    final items = await _content('saboteurs');
    return items.isEmpty
        ? fallback.getSaboteurs()
        : items.map(Saboteur.fromMap).toList();
  }

  @override
  Future<List<Affirmation>> getAffirmations() async {
    final items = await _content('affirmations');
    return items.isEmpty
        ? fallback.getAffirmations()
        : items.map(Affirmation.fromMap).toList();
  }
}
