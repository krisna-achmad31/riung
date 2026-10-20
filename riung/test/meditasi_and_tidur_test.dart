import 'package:flutter_test/flutter_test.dart';

import 'package:riung/core/models/sleep_night.dart';
import 'package:riung/features/meditasi/logic/meditation_catalog.dart';
import 'package:riung/features/tidur/logic/sleep_catalog.dart';

void main() {
  group('MeditationCatalog', () {
    test('6 sesi meditasi lengkap dengan durasi dan target monster', () {
      expect(MeditationCatalog.all.length, 6);
      for (final s in MeditationCatalog.all) {
        expect(s.id, isNotEmpty);
        expect(s.category, isNotEmpty);
        expect(s.durations, isNotEmpty);
        expect(s.defaultDuration, greaterThan(0));
        expect(s.targetMonsterId, isNotEmpty);
        expect(s.ambientAsset, isNotEmpty);
      }
    });

    test('3 sesi pertama gratis (EconomyFreeTier.meditasi), sisanya premium', () {
      expect(MeditationCatalog.isFree(0), isTrue);
      expect(MeditationCatalog.isFree(1), isTrue);
      expect(MeditationCatalog.isFree(2), isTrue);
      expect(MeditationCatalog.isFree(3), isFalse);
      expect(MeditationCatalog.isFree(4), isFalse);
      expect(MeditationCatalog.isFree(5), isFalse);

      expect(MeditationCatalog.isSessionFree('jeda_kerja'), isTrue);
      expect(MeditationCatalog.isSessionFree('napas_4_7_8'), isTrue);
      expect(MeditationCatalog.isSessionFree('tenang_ujian'), isTrue);
      expect(MeditationCatalog.isSessionFree('body_scan'), isFalse);
      expect(MeditationCatalog.isSessionFree('menonton_pikiran'), isFalse);
      expect(MeditationCatalog.isSessionFree('berhenti_membandingkan'), isFalse);
      expect(MeditationCatalog.isSessionFree('tidak_ada'), isFalse);
    });

    test('byId menemukan sesi yang sesuai', () {
      final s = MeditationCatalog.byId('napas_4_7_8');
      expect(s.id, 'napas_4_7_8');
      expect(s.category, 'cemas');
    });
  });

  group('SleepCatalog', () {
    test('4 cerita tidur LibriVox dengan target monster & durasi', () {
      expect(SleepCatalog.stories.length, 4);
      for (final s in SleepCatalog.stories) {
        expect(s.id, isNotEmpty);
        expect(s.reader, isNotEmpty);
        expect(s.durationMinutes, greaterThan(0));
        expect(s.assetPath, isNotEmpty);
      }
    });

    test('2 cerita pertama gratis (EconomyFreeTier.ceritaTidur), sisanya premium', () {
      expect(SleepCatalog.isFree(0), isTrue);
      expect(SleepCatalog.isFree(1), isTrue);
      expect(SleepCatalog.isFree(2), isFalse);
      expect(SleepCatalog.isFree(3), isFalse);

      expect(SleepCatalog.isStoryFree('happy_prince'), isTrue);
      expect(SleepCatalog.isStoryFree('selfish_giant'), isTrue);
      expect(SleepCatalog.isStoryFree('nightingale_rose'), isFalse);
      expect(SleepCatalog.isStoryFree('velveteen_rabbit'), isFalse);
      expect(SleepCatalog.isStoryFree('nonexistent'), isFalse);
    });

    test('Suasana suara & preset timer tidur', () {
      expect(soundscapes.length, 3);
      final soundIds = soundscapes.map((s) => s.id).toList();
      expect(soundIds, containsAll(['hujan', 'ombak', 'kipas']));

      expect(sleepTimerPresets, [30, 45, 60]);
    });
  });

  group('SleepNight Model (Health Connect aggregator)', () {
    test('Menggabungkan sesi tidur mentah per tanggal bangun', () {
      final day1Wake = DateTime(2026, 10, 10, 7, 0);
      final day1Sleep = DateTime(2026, 10, 9, 23, 0); // 8 jam = 480 menit

      final day1NapWake = DateTime(2026, 10, 10, 14, 0);
      final day1NapSleep = DateTime(2026, 10, 10, 13, 0); // 60 menit (tidur siang < 120 menit)

      final day2Wake = DateTime(2026, 10, 11, 6, 30);
      final day2Sleep = DateTime(2026, 10, 10, 23, 30); // 7 jam = 420 menit

      final sessions = [
        (from: day2Sleep, to: day2Wake),
        (from: day1Sleep, to: day1Wake),
        (from: day1NapSleep, to: day1NapWake), // harus diabaikan (< 120 mnt)
      ];

      final nights = SleepNight.fromSessions(sessions);
      expect(nights.length, 2);

      // Terurut kronologis
      expect(nights[0].wakeDate, DateTime(2026, 10, 10));
      expect(nights[0].minutes, 480);

      expect(nights[1].wakeDate, DateTime(2026, 10, 11));
      expect(nights[1].minutes, 420);
    });

    test('Dua sesi panjang di tanggal yang sama mengambil sesi terpanjang', () {
      final wake1 = DateTime(2026, 10, 12, 6, 0);
      final sleep1 = DateTime(2026, 10, 11, 23, 0); // 420 mnt

      final wake2 = DateTime(2026, 10, 12, 8, 0);
      final sleep2 = DateTime(2026, 10, 11, 23, 30); // 510 mnt

      final nights = SleepNight.fromSessions([
        (from: sleep1, to: wake1),
        (from: sleep2, to: wake2),
      ]);

      expect(nights.length, 1);
      expect(nights[0].minutes, 510);
    });
  });
}
