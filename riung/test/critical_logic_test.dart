import 'package:flutter/material.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:riung/core/config/economy.dart';
import 'package:riung/core/config/input_limits.dart';
import 'package:riung/core/models/models.dart';
import 'package:riung/core/services/services.dart';
import 'package:riung/features/kepribadian/logic/journal_signals.dart';

/// Test logika krusial yang sebelumnya belum punya test langsung:
/// mutasi wallet lokal, router wallet hybrid, enkripsi jurnal, parser
/// model, sanitasi input, dan sinyal metadata jurnal.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocalWalletFunctionsService', () {
    const uid = 'u_wallet';
    late LocalPrefsStore prefs;
    late LocalWalletFunctionsService wallet;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      FlutterSecureStorage.setMockInitialValues({});
      prefs = await LocalPrefsStore.init();
      await prefs.setCoins(0);
      await prefs.setLifetimeEarned(0);
      await prefs.setLifetimeSpent(0);
      await prefs.setMonsterProgressJson({});
      final users = LocalUserRepository(prefs: prefs, db: LocalDatabaseService(), crypto: JournalCryptoService());
      wallet = LocalWalletFunctionsService(prefs: prefs, userRepository: users);
    });

    test('earn lalu spend memperbarui saldo & lifetime, dan dipersist', () async {
      await wallet.earnCoins(uid: uid, amount: 30, reason: 'test');
      final w = await wallet.spendCoins(uid: uid, amount: 12, reason: 'test');
      expect(w.coins, 18);
      expect(w.lifetimeEarned, 30);
      expect(w.lifetimeSpent, 12);
      expect(prefs.coins, 18);
    });

    test('spend melebihi saldo melempar InsufficientCoinsException & saldo utuh', () async {
      await wallet.earnCoins(uid: uid, amount: 10, reason: 'test');
      await expectLater(
        wallet.spendCoins(uid: uid, amount: 11, reason: 'test'),
        throwsA(isA<InsufficientCoinsException>()
            .having((e) => e.balance, 'balance', 10)
            .having((e) => e.requested, 'requested', 11)),
      );
      expect(prefs.coins, 10);
    });

    test('spend tepat sebesar saldo diperbolehkan (batas bawah 0)', () async {
      await wallet.earnCoins(uid: uid, amount: 25, reason: 'test');
      final w = await wallet.spendCoins(uid: uid, amount: 25, reason: 'test');
      expect(w.coins, 0);
    });

    test('jumlah negatif ditolak — spend negatif tidak boleh menambah saldo', () async {
      await wallet.earnCoins(uid: uid, amount: 10, reason: 'test');
      await expectLater(wallet.spendCoins(uid: uid, amount: -100, reason: 'x'), throwsArgumentError);
      await expectLater(wallet.earnCoins(uid: uid, amount: -5, reason: 'x'), throwsArgumentError);
      expect(prefs.coins, 10);
    });

    test('spend 0 koin (sub-langkah bundel Aplikasi Beku) adalah no-op', () async {
      await wallet.earnCoins(uid: uid, amount: 10, reason: 'test');
      final w = await wallet.spendCoins(uid: uid, amount: 0, reason: 'bundle_step');
      expect(w.coins, 10);
    });

    test('dailyCheckin memberi tepat EconomyEarn.checkinHarian', () async {
      final w = await wallet.dailyCheckin(uid: uid);
      expect(w.coins, EconomyEarn.checkinHarian);
    });

    test('tameProgress: wild → taming → tamed, clamp 100, reward jinak sekali saja', () async {
      var p = await wallet.tameProgress(uid: uid, saboteurId: 'kabut', delta: 40);
      expect(p.state, MonsterState.taming);
      expect(p.progress, 40);

      p = await wallet.tameProgress(uid: uid, saboteurId: 'kabut', delta: 90);
      expect(p.progress, 100, reason: 'progres dijepit ke 100');
      expect(p.state, MonsterState.tamed);
      expect(p.tamedAt, isNotNull);
      expect(prefs.coins, EconomyEarn.monsterJinak);

      // Progres lanjutan setelah jinak tidak boleh memberi reward ganda.
      await wallet.tameProgress(uid: uid, saboteurId: 'kabut', delta: 10);
      expect(prefs.coins, EconomyEarn.monsterJinak);
    });

    test('tameProgress tidak pernah turun di bawah 0', () async {
      final p = await wallet.tameProgress(uid: uid, saboteurId: 'waswas', delta: -50);
      expect(p.progress, 0);
      expect(p.state, MonsterState.wild);
    });

    test('progres monster per id terisolasi', () async {
      await wallet.tameProgress(uid: uid, saboteurId: 'a', delta: 20);
      final b = await wallet.tameProgress(uid: uid, saboteurId: 'b', delta: 5);
      expect(b.progress, 5);
      final stored = prefs.monsterProgressJson!;
      expect(stored.keys, containsAll(['a', 'b']));
    });

    test('getTransactions lokal selalu kosong (bukan data karangan)', () async {
      expect(await wallet.getTransactions(uid: uid), isEmpty);
    });
  });

  group('HybridWalletFunctionsService routing', () {
    late _RecordingLocal local;
    late _RecordingCloud cloud;
    late bool anonymous;
    late HybridWalletFunctionsService hybrid;

    setUp(() {
      local = _RecordingLocal();
      cloud = _RecordingCloud();
      anonymous = true;
      hybrid = HybridWalletFunctionsService(local: local, cloud: cloud, isAnonymous: () => anonymous);
    });

    Future<void> callAll() async {
      await hybrid.earnCoins(uid: 'u', amount: 1, reason: 'r');
      await hybrid.spendCoins(uid: 'u', amount: 1, reason: 'r');
      await hybrid.dailyCheckin(uid: 'u');
      await hybrid.tameProgress(uid: 'u', saboteurId: 's', delta: 1);
      await hybrid.getTransactions(uid: 'u');
    }

    test('anonim → semua mutasi ke lokal, tidak menyentuh cloud', () async {
      await callAll();
      expect(local.calls, ['earn', 'spend', 'checkin', 'tame', 'tx']);
      expect(cloud.calls, isEmpty);
    });

    test('login → semua mutasi ke cloud', () async {
      anonymous = false;
      await callAll();
      expect(cloud.calls, ['earn', 'spend', 'checkin', 'tame', 'tx']);
      expect(local.calls, isEmpty);
    });

    test('status auth dibaca ulang per panggilan (link akun di tengah sesi)', () async {
      await hybrid.earnCoins(uid: 'u', amount: 1, reason: 'r');
      anonymous = false;
      await hybrid.earnCoins(uid: 'u', amount: 1, reason: 'r');
      expect(local.calls, ['earn']);
      expect(cloud.calls, ['earn']);
    });
  });

  group('JournalCryptoService', () {
    setUp(() => FlutterSecureStorage.setMockInitialValues({}));

    test('roundtrip teks termasuk emoji & multi-baris', () async {
      final crypto = JournalCryptoService();
      const plain = 'Hari ini aku capek 😮‍💨\nTapi masih bertahan.';
      final cipher = await crypto.encryptText('u', plain);
      expect(cipher, isNot(contains('capek')));
      expect(await crypto.decryptText('u', cipher), plain);
    });

    test('IV acak: teks sama menghasilkan ciphertext berbeda', () async {
      final crypto = JournalCryptoService();
      expect(await crypto.encryptText('u', 'sama'), isNot(await crypto.encryptText('u', 'sama')));
    });

    test('kunci dipakai ulang antar instance (persist di secure storage)', () async {
      final cipher = await JournalCryptoService().encryptText('u', 'rahasia');
      expect(await JournalCryptoService().decryptText('u', cipher), 'rahasia');
    });

    test('format tanpa pemisah ":" → string kosong, bukan crash', () async {
      expect(await JournalCryptoService().decryptText('u', 'rusak'), '');
    });

    test('teks kosong tetap bisa dienkripsi & didekripsi', () async {
      final crypto = JournalCryptoService();
      expect(await crypto.decryptText('u', await crypto.encryptText('u', '')), '');
    });

    test('setelah deleteAllKeys, ciphertext lama tidak bisa dibaca lagi (melempar)', () async {
      final crypto = JournalCryptoService();
      final cipher = await crypto.encryptText('u', 'hapus akun');
      await crypto.deleteAllKeys();
      // BUG-3 di laporan: pemanggil (getJournalEntries) tidak menangkap ini,
      // jadi satu baris rusak menggagalkan seluruh daftar jurnal.
      await expectLater(crypto.decryptText('u', cipher), throwsA(anything));
    });
  
    test('kunci per uid: akun lain tidak bisa membaca jurnal akun A (C-01)', () async {
      final cipher = await JournalCryptoService().encryptText('A', 'rahasia A');
      String? bacaanB;
      try {
        bacaanB = await JournalCryptoService().decryptText('B', cipher);
      } catch (_) {
        // kunci salah → padding rusak (biasanya melempar)
      }
      expect(bacaanB, isNot('rahasia A'));
      expect(await JournalCryptoService().decryptText('A', cipher), 'rahasia A');
    });

    test('kunci lama (seluruh perangkat) diserahkan ke pemiliknya', () async {
      final old = enc.Key.fromSecureRandom(32);
      FlutterSecureStorage.setMockInitialValues({'riung_jurnal_aes_key_v1': old.base64});
      final iv = enc.IV.fromSecureRandom(16);
      final legacyCipher = '${iv.base64}:${enc.Encrypter(enc.AES(old, mode: enc.AESMode.cbc)).encrypt('lama', iv: iv).base64}';
      final crypto = JournalCryptoService();
      await crypto.adoptLegacyKey('A');
      expect(await crypto.decryptText('A', legacyCipher), 'lama');
      expect(await const FlutterSecureStorage().read(key: 'riung_jurnal_aes_key_v1'), isNull);
    });
  });

  group('model_utils', () {
    test('parseDate: DateTime, ISO, Timestamp-map, sampah', () {
      final d = DateTime(2026, 10, 17);
      expect(parseDate(d), d);
      expect(parseDate('2026-10-17T08:00:00.000'), DateTime(2026, 10, 17, 8));
      expect(parseDate({'seconds': 0}), DateTime.fromMillisecondsSinceEpoch(0, isUtc: true));
      expect(parseDate({'_seconds': 60}), DateTime.fromMillisecondsSinceEpoch(60000, isUtc: true));
      expect(parseDate('bukan tanggal'), isNull);
      expect(parseDate(42), isNull);
      expect(parseDate(null), isNull);
    });

    test('parseInt: int, double dibulatkan, string, fallback', () {
      expect(parseInt(7), 7);
      expect(parseInt(2.6), 3);
      expect(parseInt('15'), 15);
      expect(parseInt('abc', fallback: -1), -1);
      expect(parseInt(null, fallback: 9), 9);
      expect(parseInt(true), 0);
    });

    test('parseStringList & parseIntMap toleran terhadap tipe salah', () {
      expect(parseStringList([1, 'a']), ['1', 'a']);
      expect(parseStringList('x'), isEmpty);
      expect(parseIntMap({'a': '3', 'b': 1.4}), {'a': 3, 'b': 1});
      expect(parseIntMap(null), isEmpty);
    });

    test('parseHexColor: 6 & 8 digit, dengan/tanpa #, fallback', () {
      expect(parseHexColor('#FF0000'), const Color(0xFFFF0000));
      expect(parseHexColor('80FF0000'), const Color(0x80FF0000));
      expect(parseHexColor('zzzzzz'), const Color(0xFF7C8CFF));
    });

    test('colorToHex ⇄ parseHexColor roundtrip untuk warna opak', () {
      const c = Color(0xFF12AB9C);
      expect(colorToHex(c), '#12ab9c');
      expect(parseHexColor(colorToHex(c)), c);
    });

    test('enumFromName fallback aman untuk data lama', () {
      expect(enumFromName(MonsterState.values, 'tamed', MonsterState.wild), MonsterState.tamed);
      expect(enumFromName(MonsterState.values, 'hilang', MonsterState.wild), MonsterState.wild);
      expect(enumFromName(MonsterState.values, null, MonsterState.wild), MonsterState.wild);
    });

    test('Wallet.fromMap tahan field hilang / bertipe string', () {
      final w = Wallet.fromMap({'coins': '12', 'lifetimeEarned': 20.0});
      expect(w.coins, 12);
      expect(w.lifetimeEarned, 20);
      expect(w.lifetimeSpent, 0);
      expect(Wallet.fromMap(w.toMap()).coins, 12);
    });
  });

  group('InputLimits.sanitize', () {
    test('membuang karakter kontrol & penanda arah tersembunyi', () {
      final rlo = String.fromCharCode(0x202E), bel = String.fromCharCode(7);
      expect(InputLimits.sanitize('ha${rlo}lo$bel', 40), 'halo');
    });

    test('single-line membuang baris baru, multiline mempertahankannya', () {
      expect(InputLimits.sanitize('a\nb', 40, multiline: false), 'ab');
      expect(InputLimits.sanitize('a\nb', 40), 'a\nb');
    });

    test('memotong ke batas & merapikan spasi tepi', () {
      expect(InputLimits.sanitize('  abcdef  ', 3), 'abc');
      expect(InputLimits.sanitize('x' * 6000, InputLimits.jurnal).length, InputLimits.jurnal);
    });

    test('pemotongan tidak membelah emoji (surrogate pair) di tengah', () {
      final out = InputLimits.sanitize('ab😀😀', 3);
      expect(out, 'ab😀');
    });

    test('input kosong / hanya spasi → string kosong', () {
      expect(InputLimits.sanitize('   ', 10), '');
      expect(InputLimits.sanitize('', 10), '');
    });
  });

  group('JournalSignals', () {
    final now = DateTime(2026, 10, 17, 12);
    JournalEntry entry(DateTime at, {String mood = 'tenang', List<String> tags = const []}) => JournalEntry(
          entryId: at.toIso8601String(),
          promptId: '',
          mood: mood,
          text: 'TIDAK BOLEH DIBACA',
          tags: tags,
          createdAt: at,
        );

    test('periodOf memetakan batas jam dengan tepat', () {
      expect(JournalSignals.periodOf(DateTime(2026, 1, 1, 4, 59)), 'night');
      expect(JournalSignals.periodOf(DateTime(2026, 1, 1, 5)), 'morning');
      expect(JournalSignals.periodOf(DateTime(2026, 1, 1, 11)), 'afternoon');
      expect(JournalSignals.periodOf(DateTime(2026, 1, 1, 15)), 'evening');
      expect(JournalSignals.periodOf(DateTime(2026, 1, 1, 19)), 'night');
    });

    test('kosong → isEmpty, semua top null', () {
      final s = JournalSignals.from(const [], now: now);
      expect(s.isEmpty, isTrue);
      expect(s.topMood, isNull);
      expect(s.topPeriod, isNull);
      expect(s.topTag, isNull);
    });

    test('hanya 30 hari terakhir dihitung; mood kosong diabaikan', () {
      final s = JournalSignals.from([
        entry(now.subtract(const Duration(days: 40)), mood: 'sedih'),
        entry(now.subtract(const Duration(days: 40)), mood: 'sedih'),
        entry(now.subtract(const Duration(days: 2)), mood: 'senang', tags: ['kabut']),
        entry(now.subtract(const Duration(days: 1)), mood: '', tags: ['kabut', 'waswas']),
      ], now: now);
      expect(s.entryCount, 2);
      expect(s.topMood, 'senang');
      expect(s.topTag, 'kabut');
      expect(s.topPeriod, 'afternoon');
    });
  });
}

class _RecordingLocal implements LocalWalletFunctionsService {
  final calls = <String>[];

  @override
  Future<Wallet> earnCoins({required String uid, required int amount, required String reason}) async {
    calls.add('earn');
    return Wallet.zero();
  }

  @override
  Future<Wallet> spendCoins({required String uid, required int amount, required String reason}) async {
    calls.add('spend');
    return Wallet.zero();
  }

  @override
  Future<Wallet> dailyCheckin({required String uid}) async {
    calls.add('checkin');
    return Wallet.zero();
  }

  @override
  Future<MonsterProgress> tameProgress({required String uid, required String saboteurId, required int delta}) async {
    calls.add('tame');
    return MonsterProgress.initial(saboteurId);
  }

  @override
  Future<List<CoinTransaction>> getTransactions({required String uid, int limit = 50}) async {
    calls.add('tx');
    return const [];
  }
}

class _RecordingCloud extends _RecordingLocal implements FirestoreWalletFunctionsService {}
