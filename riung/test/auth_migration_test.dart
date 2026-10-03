import 'package:flutter_test/flutter_test.dart';
import 'package:riung/core/models/models.dart';
import 'package:riung/core/services/auth_service.dart';
import 'package:riung/core/services/user_repository.dart';
import 'package:riung/core/state/auth_notifier.dart';

/// Verifikasi Poin 4d (migrasi anon→cloud) TANPA Firebase sungguhan — dua
/// hal krusial yang tidak bisa diuji lewat device/emulator di sesi ini
/// (Email/Password provider disabled & Google Sign-In butuh serverClientId
/// di project Firebase saat ini, lihat laporan): (1) urutan baca-sebelum-link
/// tulis-sesudah-link, dan (2) migrationWarning tidak pernah membuat
/// linking dianggap gagal.
class _FakeAuthService implements AuthService {
  _FakeAuthService({this.linkShouldFail = false});

  final bool linkShouldFail;
  bool _anonymous = true;
  final String _uid = 'anon-uid-1';

  @override
  String? get currentUid => _uid;

  @override
  String? get currentEmail => _anonymous ? null : 'test@example.com';

  @override
  bool get isAnonymous => _anonymous;

  @override
  Stream<String?> get uidChanges => const Stream.empty();

  @override
  Future<String> signInAnonymously() async => _uid;

  @override
  Future<void> signOut() async {}

  @override
  Future<String> linkEmailPassword({required String email, required String password}) async {
    if (linkShouldFail) throw const AuthServiceException(AuthError.unknown);
    // Meniru Firebase linkWithCredential: uid TETAP SAMA, cuma isAnonymous
    // yang berubah — persis skenario yang bikin Poin 4d rawan salah urutan.
    _anonymous = false;
    return _uid;
  }

  @override
  Future<String> signInWithEmailPassword({required String email, required String password}) async => _uid;

  @override
  Future<String> linkGoogle() async {
    if (linkShouldFail) throw const AuthServiceException(AuthError.unknown);
    _anonymous = false;
    return _uid;
  }

  @override
  Future<String> signInWithGoogle() async => _uid;

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<void> deleteAccount() async {}
}

class _FakeUserRepository implements UserRepository {
  _FakeUserRepository({this.migrateShouldFail = false});

  @override
  Future<void> deleteAllLocalData() async {}

  @override
  Future<void> deleteCloudData(String uid) async {}

  final bool migrateShouldFail;
  final List<String> callLog = [];
  Map<String, dynamic>? migratedSnapshot;

  final _wallet = const Wallet(coins: 145, lifetimeEarned: 150, lifetimeSpent: 5);
  final _profile = UserProfile.kosong('anon-uid-1').copyWith(
    displayName: 'TestMigrasi',
    streakCurrent: 12,
    onboardingDone: true,
  );
  final _monsters = <String, MonsterProgress>{
    'hakim': MonsterProgress(saboteurId: 'hakim', state: MonsterState.taming, progress: 23),
  };

  @override
  Future<UserProfile> getUserProfile(String uid) async {
    callLog.add('getUserProfile');
    return _profile;
  }

  @override
  Future<Wallet> getWallet(String uid) async {
    callLog.add('getWallet');
    return _wallet;
  }

  @override
  Future<Map<String, MonsterProgress>> getMonsterProgress(String uid) async {
    callLog.add('getMonsterProgress');
    return _monsters;
  }

  @override
  Future<void> migrateAnonymousSnapshot({
    required String uid,
    required Wallet wallet,
    required UserProfile profile,
    required Map<String, MonsterProgress> monsterProgress,
  }) async {
    callLog.add('migrateAnonymousSnapshot');
    if (migrateShouldFail) throw Exception('network error simulasi');
    migratedSnapshot = {
      'uid': uid,
      'wallet': wallet,
      'profile': profile,
      'monsterProgress': monsterProgress,
    };
  }

  // Method di bawah ini tidak relevan buat migrasi — stub kosong saja.
  @override
  Future<void> saveUserProfile(UserProfile profile) async {}
  @override
  Future<void> saveMonsterProgress(String uid, Map<String, MonsterProgress> progress) async {}
  @override
  Future<List<CheckIn>> getCheckIns(String uid) async => const [];
  @override
  Future<CheckIn> saveCheckIn(String uid, CheckIn checkIn) async => checkIn;
  @override
  Future<bool> hasCheckedInToday(String uid) async => false;
  @override
  Future<List<JournalEntry>> getJournalEntries(String uid) async => const [];
  @override
  Future<JournalEntry> saveJournalEntry(String uid, JournalEntry entry) async => entry;
  @override
  Future<int> journalEntryCountForDate(String uid, DateTime date) async => 0;
  @override
  Future<Set<String>> getFavoriteAffirmationIds(String uid) async => const {};
  @override
  Future<void> setFavoriteAffirmationIds(String uid, Set<String> ids) async {}
  @override
  Future<List<Affirmation>> getCustomAffirmations(String uid) async => const [];
  @override
  Future<Affirmation> saveCustomAffirmation(String uid, Affirmation affirmation) async => affirmation;
  @override
  Future<void> saveJournalPinBackup(String uid, JournalPinBackup backup) async {}
  @override
  Future<JournalPinBackup?> getJournalPinBackup(String uid) async => null;
}

void main() {
  group('AuthNotifier._linkAndMigrate (Poin 4d)', () {
    test('baca snapshot SEBELUM link, tulis migrateAnonymousSnapshot SESUDAH link sukses', () async {
      final userRepo = _FakeUserRepository();
      final auth = AuthNotifier(_FakeAuthService(), userRepository: userRepo);

      final uid = await auth.daftarGoogle();

      expect(uid, 'anon-uid-1');
      // Urutan panggilan HARUS: baca dulu (getWallet/getUserProfile/
      // getMonsterProgress), baru migrateAnonymousSnapshot — kalau
      // urutannya kebalik atau migrate dipanggil sebelum baca, ini gagal.
      expect(
        userRepo.callLog,
        containsAllInOrder(['getWallet', 'getUserProfile', 'getMonsterProgress', 'migrateAnonymousSnapshot']),
      );
      expect(userRepo.callLog.where((c) => c == 'migrateAnonymousSnapshot'), hasLength(1));

      final snapshot = userRepo.migratedSnapshot!;
      expect(snapshot['uid'], 'anon-uid-1');
      expect((snapshot['wallet'] as Wallet).coins, 145);
      expect((snapshot['profile'] as UserProfile).displayName, 'TestMigrasi');
      expect((snapshot['profile'] as UserProfile).streakCurrent, 12);
      expect((snapshot['monsterProgress'] as Map<String, MonsterProgress>)['hakim']!.progress, 23);
      expect(auth.migrationWarning, isFalse);
    });

    test('link gagal (mis. provider disabled) → snapshot TIDAK ditulis, exception tetap dilempar', () async {
      final userRepo = _FakeUserRepository();
      final auth = AuthNotifier(_FakeAuthService(linkShouldFail: true), userRepository: userRepo);

      await expectLater(
        () => auth.daftarEmailPassword(email: 'x@example.com', password: 'password1'),
        throwsA(isA<AuthServiceException>()),
      );

      expect(userRepo.callLog, isNot(contains('migrateAnonymousSnapshot')));
      expect(auth.migrationWarning, isFalse);
    });

    test('link sukses tapi migrateAnonymousSnapshot gagal → migrationWarning terisi, TIDAK melempar exception', () async {
      final userRepo = _FakeUserRepository(migrateShouldFail: true);
      final auth = AuthNotifier(_FakeAuthService(), userRepository: userRepo);

      // Tidak boleh throw — akun tetap valid, cuma progresnya belum tersalin.
      final uid = await auth.daftarGoogle();

      expect(uid, 'anon-uid-1');
      expect(auth.migrationWarning, isTrue);
    });

    test('masukEmailPassword/masukGoogle (bukan daftar) TIDAK memicu migrasi sama sekali', () async {
      final userRepo = _FakeUserRepository();
      final auth = AuthNotifier(_FakeAuthService(), userRepository: userRepo);

      await auth.masukEmailPassword(email: 'x@example.com', password: 'password1');

      expect(userRepo.callLog, isEmpty);
      expect(auth.migrationWarning, isFalse);
    });
  });
}
