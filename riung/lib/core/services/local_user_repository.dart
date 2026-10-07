import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../models/affirmation.dart';
import '../models/check_in.dart';
import '../models/journal_entry.dart';
import '../models/journal_pin_backup.dart';
import '../models/monster_progress.dart';
import '../models/user_profile.dart';
import '../models/wallet.dart';
import 'dummy_data_loader.dart';
import 'journal_crypto_service.dart';
import 'local_database_service.dart';
import 'local_prefs_store.dart';
import 'user_repository.dart';
import 'kenali_result_repository.dart';

/// Implementasi [UserRepository] sungguhan sejak M3 — profil/wallet/streak/
/// progres monster di [LocalPrefsStore] (shared_preferences), jurnal &
/// check-in di [LocalDatabaseService] (sqflite, teks jurnal terenkripsi AES
/// lewat [JournalCryptoService]). Data seed pertama kali diambil dari
/// `docs/dummy-data-seed.json` (user `u_001`) supaya first-run tidak
/// kosong, lalu setiap perubahan persisten sungguhan — bertahan setelah
/// app di-restart.
class LocalUserRepository implements UserRepository {
  LocalUserRepository({
    required LocalPrefsStore prefs,
    required LocalDatabaseService db,
    required JournalCryptoService crypto,
    DummyDataLoader? dummyLoader,
  })  : _prefs = prefs,
        _db = db,
        _crypto = crypto,
        _dummyLoader = dummyLoader ?? DummyDataLoader.instance;

  final LocalPrefsStore _prefs;
  final LocalDatabaseService _db;
  final JournalCryptoService _crypto;
  final DummyDataLoader _dummyLoader;
  static const _uuid = Uuid();

  Future<Map<String, dynamic>> _findDummyUser(String uid) async {
    final data = await _dummyLoader.load();
    final users = (data['users_sample'] as List).cast<Map<String, dynamic>>();
    return users.firstWhere((u) => u['uid'] == uid, orElse: () => users.first);
  }

  @override
  Future<UserProfile> getUserProfile(String uid) async {
    final stored = _prefs.userProfileJson;
    if (stored != null) return UserProfile.fromMap(uid, stored);

    // First run: seed dari dummy data, lalu persist supaya konsisten
    // setelah ini.
    final user = await _findDummyUser(uid);
    final seeded = UserProfile.fromMap(uid, {
      UserProfile.kProfile: user['profile'],
      UserProfile.kPremium: user['premium'],
      UserProfile.kStreak: user['streak'],
      UserProfile.kAssessment: user['assessment'],
    });
    await saveUserProfile(seeded);
    return seeded;
  }

  @override
  Future<void> saveUserProfile(UserProfile profile) async {
    await _prefs.setUserProfileJson(profile.toMap());
    await _prefs.setUserId(profile.uid);
    await _prefs.setOnboardingDone(profile.onboardingDone);
    await _prefs.setStreakCurrent(profile.streakCurrent);
    await _prefs.setStreakLongest(profile.streakLongest);
    final lastCheckin = profile.lastCheckinDate;
    if (lastCheckin != null) await _prefs.setLastCheckInDate(lastCheckin);
  }

  @override
  Future<Wallet> getWallet(String uid) async {
    final coins = _prefs.coins;
    if (coins != null) {
      return Wallet(
        coins: coins,
        lifetimeEarned: _prefs.lifetimeEarned,
        lifetimeSpent: _prefs.lifetimeSpent,
      );
    }
    final user = await _findDummyUser(uid);
    final walletRaw = (user['wallet'] as Map?)?.cast<String, dynamic>();
    final seeded = walletRaw == null ? Wallet.zero() : Wallet.fromMap(walletRaw);
    await _prefs.setCoins(seeded.coins);
    await _prefs.setLifetimeEarned(seeded.lifetimeEarned);
    await _prefs.setLifetimeSpent(seeded.lifetimeSpent);
    return seeded;
  }

  @override
  Future<Map<String, MonsterProgress>> getMonsterProgress(String uid) async {
    final stored = _prefs.monsterProgressJson;
    if (stored != null) {
      return stored.map(
        (id, raw) => MapEntry(id, MonsterProgress.fromMap(id, (raw as Map).cast<String, dynamic>())),
      );
    }
    final user = await _findDummyUser(uid);
    final monstersRaw = (user['monsters'] as Map?)?.cast<String, dynamic>() ?? const {};
    final seeded = monstersRaw.map(
      (id, raw) => MapEntry(id, MonsterProgress.fromMap(id, (raw as Map).cast<String, dynamic>())),
    );
    await saveMonsterProgress(uid, seeded);
    return seeded;
  }

  @override
  Future<void> saveMonsterProgress(String uid, Map<String, MonsterProgress> progress) {
    return _prefs.setMonsterProgressJson(progress.map((id, p) => MapEntry(id, p.toMap())));
  }

  @override
  Future<List<CheckIn>> getCheckIns(String uid) async {
    final rows = await _db.allCheckIns();
    return rows.map(_checkInFromRow).toList();
  }

  @override
  Future<CheckIn> saveCheckIn(String uid, CheckIn checkIn) async {
    await _db.insertCheckIn({
      'id': _uuid.v4(),
      'date': checkIn.toMap()[CheckIn.fDate],
      'mood': checkIn.mood,
      'energy': checkIn.energy,
      'sleep_quality': checkIn.sleepQuality,
      'factors': jsonEncode(checkIn.factors),
      'intention': checkIn.intention,
      'created_at': DateTime.now().toIso8601String(),
    });
    return checkIn;
  }

  @override
  Future<bool> hasCheckedInToday(String uid) async {
    final todayIso = DateTime.now().toIso8601String().split('T').first;
    final rows = await _db.allCheckIns();
    return rows.any((r) => r['date'] == todayIso);
  }

  CheckIn _checkInFromRow(Map<String, Object?> row) {
    final factorsRaw = row['factors'] as String?;
    return CheckIn(
      date: DateTime.parse(row['date'] as String),
      mood: row['mood'] as String? ?? '',
      energy: (row['energy'] as int?) ?? 0,
      sleepQuality: (row['sleep_quality'] as int?) ?? 0,
      factors: factorsRaw == null ? const [] : (jsonDecode(factorsRaw) as List).cast<String>(),
      intention: row['intention'] as String? ?? '',
    );
  }

  @override
  Future<List<JournalEntry>> getJournalEntries(String uid) async {
    final rows = await _db.allJournalEntries();
    final entries = <JournalEntry>[];
    for (final row in rows) {
      entries.add(await _journalEntryFromRow(row));
    }
    return entries;
  }

  Future<JournalEntry> _journalEntryFromRow(Map<String, Object?> row) async {
    final encryptedText = row['text_encrypted'] as String;
    final text = await _crypto.decryptText(encryptedText);
    final tagsRaw = row['tags'] as String?;
    return JournalEntry(
      entryId: row['id'] as String,
      promptId: row['prompt_id'] as String? ?? '',
      mood: row['mood'] as String? ?? '',
      text: text,
      tags: tagsRaw == null ? const [] : (jsonDecode(tagsRaw) as List).cast<String>(),
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }

  @override
  Future<JournalEntry> saveJournalEntry(String uid, JournalEntry entry) async {
    final encryptedText = await _crypto.encryptText(entry.text);
    await _db.insertJournalEntry({
      'id': entry.entryId,
      'date': entry.createdAt.toIso8601String().split('T').first,
      'prompt_id': entry.promptId,
      'text_encrypted': encryptedText,
      'mood': entry.mood,
      'tags': jsonEncode(entry.tags),
      'created_at': entry.createdAt.toIso8601String(),
    });
    return entry;
  }

  @override
  Future<int> journalEntryCountForDate(String uid, DateTime date) {
    final iso = date.toIso8601String().split('T').first;
    return _db.journalEntryCountForDate(iso);
  }

  @override
  Future<Set<String>> getFavoriteAffirmationIds(String uid) async {
    return _prefs.favoriteAffirmationIds.toSet();
  }

  @override
  Future<void> setFavoriteAffirmationIds(String uid, Set<String> ids) {
    return _prefs.setFavoriteAffirmationIds(ids.toList());
  }

  @override
  Future<List<Affirmation>> getCustomAffirmations(String uid) async {
    return _prefs.customAffirmations.map(Affirmation.fromMap).toList();
  }

  @override
  Future<Affirmation> saveCustomAffirmation(String uid, Affirmation affirmation) async {
    final existing = _prefs.customAffirmations;
    await _prefs.setCustomAffirmations([...existing, affirmation.toMap()]);
    return affirmation;
  }

  /// Implementasi lokal murni tidak punya "device lain" untuk dipulihkan
  /// ke — no-op/null, backup beneran cuma lewat [FirestoreUserRepository]
  /// untuk user yang sudah login.
  @override
  Future<void> saveJournalPinBackup(String uid, JournalPinBackup backup) async {}

  @override
  Future<JournalPinBackup?> getJournalPinBackup(String uid) async => null;

  @override
  Future<void> deleteCloudData(String uid) async {}

  @override
  Future<void> deleteAllLocalData() async {
    await _db.deleteAll();
    await _crypto.deleteKey();
    await _prefs.clearAll();
    KenaliResultRepository.instance.clearCache();
  }

  /// Migrasi anon→cloud cuma relevan buat implementasi Firestore — no-op
  /// di sini (lihat [FirestoreUserRepository.migrateAnonymousSnapshot]).
  @override
  Future<void> migrateAnonymousSnapshot({
    required String uid,
    required Wallet wallet,
    required UserProfile profile,
    required Map<String, MonsterProgress> monsterProgress,
  }) async {}
}
