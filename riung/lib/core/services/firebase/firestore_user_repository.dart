import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/affirmation.dart';
import '../../models/check_in.dart';
import '../../models/journal_entry.dart';
import '../../models/journal_pin_backup.dart';
import '../../models/monster_progress.dart';
import '../../models/user_profile.dart';
import '../../models/wallet.dart';
import '../local_user_repository.dart';
import '../user_repository.dart';

/// Implementasi [UserRepository] sungguhan lewat Firestore — dipakai sejak
/// M5. Cuma `profile`/`premium`/`streak`/`assessment`/`monsters` (dokumen
/// `/users/{uid}`) yang disinkron ke cloud, supaya progresmu ikut kalau
/// ganti perangkat. Jurnal, riwayat check-in, dan afirmasi favorit/buatan
/// TETAP di perangkat lewat [LocalUserRepository] yang di-compose di sini
/// (CLAUDE.md aturan #5: data pribadi selalu lokal, jurnal tidak pernah
/// meninggalkan HP). Wallet cuma boleh berubah lewat delta yang tervalidasi
/// `firestore.rules` — lihat [firestore.rules] & `docs/setup-firebase.md`
/// untuk batasan keamanannya di Spark plan (tanpa Cloud Functions).
///
/// Poin 4 — SELAMA ANONIM, [isAnonymous] bernilai true dan kelima method
/// profile/wallet/monsters di bawah rute PENUH ke [_local], tidak
/// menyentuh Firestore sama sekali (hemat kuota Spark plan). Begitu user
/// login/link akun, [isAnonymous] jadi false dan method yang sama rute ke
/// Firestore seperti sebelumnya. Migrasi data yang terkumpul selama
/// anonim ditangani terpisah lewat [migrateAnonymousSnapshot] (lihat
/// `AuthNotifier._linkAndMigrate`), BUKAN oleh routing di sini.
class FirestoreUserRepository implements UserRepository {
  FirestoreUserRepository({
    required FirebaseFirestore firestore,
    required LocalUserRepository localDelegate,
    required bool Function() isAnonymous,
  })  : _firestore = firestore,
        _local = localDelegate,
        _isAnonymous = isAnonymous;

  final FirebaseFirestore _firestore;
  final LocalUserRepository _local;
  final bool Function() _isAnonymous;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) => _firestore.collection('users').doc(uid);

  @override
  Future<UserProfile> getUserProfile(String uid) async {
    if (_isAnonymous()) return _local.getUserProfile(uid);
    final snap = await _userDoc(uid).get();
    final data = snap.data();
    if (data == null) {
      final fresh = UserProfile.kosong(uid);
      await saveUserProfile(fresh);
      return fresh;
    }
    return UserProfile.fromMap(uid, data);
  }

  @override
  Future<void> saveUserProfile(UserProfile profile) async {
    if (_isAnonymous()) return _local.saveUserProfile(profile);
    await _userDoc(profile.uid).set(profile.toMap(), SetOptions(merge: true));
  }

  @override
  Future<Wallet> getWallet(String uid) async {
    if (_isAnonymous()) return _local.getWallet(uid);
    final snap = await _userDoc(uid).get();
    final walletRaw = (snap.data()?['wallet'] as Map?)?.cast<String, dynamic>();
    if (walletRaw == null) {
      final fresh = Wallet.zero();
      await _userDoc(uid).set({'wallet': fresh.toMap()}, SetOptions(merge: true));
      return fresh;
    }
    return Wallet.fromMap(walletRaw);
  }

  @override
  Future<Map<String, MonsterProgress>> getMonsterProgress(String uid) async {
    if (_isAnonymous()) return _local.getMonsterProgress(uid);
    final snap = await _userDoc(uid).get();
    final monstersRaw = (snap.data()?['monsters'] as Map?)?.cast<String, dynamic>() ?? const {};
    return monstersRaw.map(
      (id, raw) => MapEntry(id, MonsterProgress.fromMap(id, (raw as Map).cast<String, dynamic>())),
    );
  }

  @override
  Future<void> saveMonsterProgress(String uid, Map<String, MonsterProgress> progress) async {
    if (_isAnonymous()) return _local.saveMonsterProgress(uid, progress);
    await _userDoc(uid).set(
      {'monsters': progress.map((id, p) => MapEntry(id, p.toMap()))},
      SetOptions(merge: true),
    );
  }

  @override
  Future<void> deleteAllLocalData() => _local.deleteAllLocalData();

  /// Hapus dokumen `/users/{uid}` beserta subkoleksi `coinRequests`. Akun
  /// anonim tidak punya salinan cloud (semua lokal), jadi dilewati.
  @override
  Future<void> deleteCloudData(String uid) async {
    if (_isAnonymous()) return;
    final requests = await _userDoc(uid).collection('coinRequests').get();
    for (var i = 0; i < requests.docs.length; i += 400) {
      final batch = _firestore.batch();
      for (final doc in requests.docs.skip(i).take(400)) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
    await _userDoc(uid).delete();
  }

  // Data pribadi berikut TIDAK PERNAH ke Firestore — selalu lewat
  // LocalUserRepository (sqflite/shared_preferences di perangkat).
  @override
  Future<List<CheckIn>> getCheckIns(String uid) => _local.getCheckIns(uid);

  @override
  Future<CheckIn> saveCheckIn(String uid, CheckIn checkIn) => _local.saveCheckIn(uid, checkIn);

  @override
  Future<bool> hasCheckedInToday(String uid) => _local.hasCheckedInToday(uid);

  @override
  Future<List<JournalEntry>> getJournalEntries(String uid) => _local.getJournalEntries(uid);

  @override
  Future<JournalEntry> saveJournalEntry(String uid, JournalEntry entry) => _local.saveJournalEntry(uid, entry);

  @override
  Future<int> journalEntryCountForDate(String uid, DateTime date) => _local.journalEntryCountForDate(uid, date);

  @override
  Future<Set<String>> getFavoriteAffirmationIds(String uid) => _local.getFavoriteAffirmationIds(uid);

  @override
  Future<void> setFavoriteAffirmationIds(String uid, Set<String> ids) => _local.setFavoriteAffirmationIds(uid, ids);

  @override
  Future<List<Affirmation>> getCustomAffirmations(String uid) => _local.getCustomAffirmations(uid);

  @override
  Future<Affirmation> saveCustomAffirmation(String uid, Affirmation affirmation) =>
      _local.saveCustomAffirmation(uid, affirmation);

  @override
  Future<void> saveJournalPinBackup(String uid, JournalPinBackup backup) async {
    await _userDoc(uid).set({'journalPinBackup': backup.toMap()}, SetOptions(merge: true));
  }

  @override
  Future<JournalPinBackup?> getJournalPinBackup(String uid) async {
    final snap = await _userDoc(uid).get();
    final raw = (snap.data()?['journalPinBackup'] as Map?)?.cast<String, dynamic>();
    return raw == null ? null : JournalPinBackup.fromMap(raw);
  }

  /// SENGAJA tidak cek [_isAnonymous] — dipanggil tepat setelah link
  /// sukses (uid sudah permanen), jadi harus selalu menulis ke Firestore
  /// terlepas dari urutan pemanggilan. Full `.set()` (bukan merge) karena
  /// ini penulisan PERTAMA kali ke dokumen ini (baru dibuat saat migrasi,
  /// bukan lagi saat anonim pertama kali — lihat firestore.rules
  /// isValidNewUserDoc()).
  @override
  Future<void> migrateAnonymousSnapshot({
    required String uid,
    required Wallet wallet,
    required UserProfile profile,
    required Map<String, MonsterProgress> monsterProgress,
  }) async {
    final payload = <String, dynamic>{
      ...profile.toMap(),
      'wallet': wallet.toMap(),
      'monsters': monsterProgress.map((id, p) => MapEntry(id, p.toMap())),
    };
    await _userDoc(uid).set(payload);
  }
}
