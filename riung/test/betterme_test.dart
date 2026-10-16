import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:riung/core/services/services.dart';
import 'package:riung/features/betterme/data/betterme_content.dart';
import 'package:riung/features/betterme/logic/betterme_progress.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Better Me Content & Struktur', () {
    test('3 level dengan total 22 sesi', () {
      expect(betterMeLevels.length, 3);
      expect(betterMeLevels[0].number, 1);
      expect(betterMeLevels[1].number, 2);
      expect(betterMeLevels[2].number, 3);

      final totalSessions = betterMeLevels.fold<int>(0, (sum, l) => sum + l.sessions.length);
      expect(totalSessions, 22);

      for (final level in betterMeLevels) {
        expect(level.sessions, isNotEmpty);
        for (final s in level.sessions) {
          expect(s.id, startsWith('l${level.number}_'));
          expect(s.level, level.number);
          expect(s.estimasiMenit, greaterThan(0));
          expect(s.tipe, isNotNull);
        }
      }
    });
  });

  group('BetterMeProgress', () {
    late LocalPrefsStore prefs;
    late BetterMeProgress progress;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await LocalPrefsStore.init();
      await prefs.setBetterMeCompleted({});
      await prefs.setBetterMeReflectionsJson({});
      progress = BetterMeProgress(prefs);
    });

    test('Level 1 selalu terbuka, Level 2 & 3 terkunci jika bukan Premium', () {
      expect(progress.isLevelUnlocked(1, premiumActive: false), isTrue);
      expect(progress.isLevelUnlocked(1, premiumActive: true), isTrue);

      expect(progress.isLevelUnlocked(2, premiumActive: false), isFalse);
      expect(progress.isLevelUnlocked(3, premiumActive: false), isFalse);
    });

    test('Level 2 & 3 butuh level sebelumnya selesai DAN Premium aktif', () async {
      // Premium aktif tapi Level 1 belum selesai
      expect(progress.isLevelUnlocked(2, premiumActive: true), isFalse);

      // Selesaikan semua sesi di Level 1
      final level1 = betterMeLevels.firstWhere((l) => l.number == 1);
      for (final s in level1.sessions) {
        await progress.markCompleted(s.id);
      }

      expect(progress.isLevelComplete(1), isTrue);
      expect(progress.completedInLevel(1), level1.sessions.length);

      // Setelah Level 1 selesai: jika bukan premium tetap terkunci
      expect(progress.isLevelUnlocked(2, premiumActive: false), isFalse);

      // Jika premium aktif: Level 2 terbuka!
      expect(progress.isLevelUnlocked(2, premiumActive: true), isTrue);
      // Level 3 tetap terkunci sampai Level 2 selesai
      expect(progress.isLevelUnlocked(3, premiumActive: true), isFalse);

      // Selesaikan Level 2
      final level2 = betterMeLevels.firstWhere((l) => l.number == 2);
      for (final s in level2.sessions) {
        await progress.markCompleted(s.id);
      }
      expect(progress.isLevelComplete(2), isTrue);
      expect(progress.isLevelUnlocked(3, premiumActive: true), isTrue);
    });

    test('Penyimpanan dan pembacaan refleksi sesi', () async {
      expect(progress.reflectionFor('l1_s1'), isNull);

      await progress.saveReflection('l1_s1', 'Hari ini aku belajar mengenali pola pikir.');
      expect(progress.reflectionFor('l1_s1'), 'Hari ini aku belajar mengenali pola pikir.');

      await progress.saveReflection('l1_s1', 'Refleksi diedit.');
      expect(progress.reflectionFor('l1_s1'), 'Refleksi diedit.');
    });

    test('totalCompleted dan isCompleted menghitung dengan benar', () async {
      expect(progress.totalCompleted, 0);
      expect(progress.isCompleted('l1_s1'), isFalse);

      await progress.markCompleted('l1_s1');
      expect(progress.isCompleted('l1_s1'), isTrue);
      expect(progress.totalCompleted, 1);

      await progress.markCompleted('l1_s2');
      expect(progress.totalCompleted, 2);
    });
  });
}
