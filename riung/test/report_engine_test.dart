import 'package:flutter_test/flutter_test.dart';

import 'package:riung/core/models/sleep_night.dart';
import 'package:riung/features/laporan/logic/report_config.dart';
import 'package:riung/features/laporan/logic/report_engine.dart';
import 'package:riung/features/laporan/logic/report_models.dart';

/// Laporan refleksi: setiap insight bisa dihitung ulang dari data, dan tidak
/// ada kesimpulan kalau data kurang.
void main() {
  final now = DateTime(2026, 9, 27); // Minggu

  ReportEntry c(int daysAgo, String mood, {List<String> factors = const []}) =>
      ReportEntry(date: now.subtract(Duration(days: daysAgo)), mood: mood, factors: factors);
  ReportEntry j(int daysAgo, String mood, String monster) =>
      ReportEntry(date: now.subtract(Duration(days: daysAgo)), mood: mood, monsterId: monster, isJournal: true);

  ReportInsight? find(Report r, InsightKind k) {
    for (final i in r.insights) {
      if (i.kind == k) return i;
    }
    return null;
  }

  test('data kurang dari ambang: tanpa kesimpulan', () {
    final r = ReportEngine.build([c(0, 'senang'), c(1, 'berat')], now: now);
    expect(r.hasEnoughData, isFalse);
    expect(r.insights, isEmpty);
    expect(r.activeDays, 2);
  });

  test('tanpa data sama sekali', () {
    final r = ReportEngine.build(const [], now: now);
    expect(r.averageMood, isNull);
    expect(r.days.length, ReportConfig.weekDays);
    expect(r.needsSupport, isFalse);
  });

  test('rata-rata per hari: dua entri sehari dirata-rata dulu', () {
    final r = ReportEngine.build([c(0, 'senang'), j(0, 'datar', 'hakim'), c(1, 'cukup_baik'), c(2, 'cukup_baik')], now: now);
    // hari ini (5+3)/2=4, kemarin 4, 2 hari lalu 4
    expect(r.averageMood, 4.0);
    expect(r.checkInCount, 3);
    expect(r.journalCount, 1);
    expect(r.days.last.mood, 4.0);
  });

  test('tren naik, turun, stabil dibanding periode sebelumnya', () {
    List<ReportEntry> week(int offset, String mood) => [for (var i = 0; i < 3; i++) c(offset + i, mood)];
    final naik = ReportEngine.build([...week(0, 'cukup_baik'), ...week(7, 'datar')], now: now);
    expect(find(naik, InsightKind.moodTrend)!.direction, 1);
    final turun = ReportEngine.build([...week(0, 'agak_berat'), ...week(7, 'cukup_baik')], now: now);
    expect(find(turun, InsightKind.moodTrend)!.direction, -1);
    final stabil = ReportEngine.build([...week(0, 'datar'), ...week(7, 'datar')], now: now);
    expect(find(stabil, InsightKind.moodTrend)!.direction, 0);
    // Periode sebelumnya terlalu sedikit → tidak membandingkan.
    final tanpaBanding = ReportEngine.build([...week(0, 'datar'), c(8, 'senang')], now: now);
    expect(find(tanpaBanding, InsightKind.moodTrend), isNull);
  });

  test('hari terbaik dan terberat butuh selisih cukup', () {
    // 27 Sep = Minggu(7), 26 = Sabtu(6), 25 = Jumat(5)
    final r = ReportEngine.build([c(0, 'senang'), c(1, 'datar'), c(2, 'berat')], now: now);
    expect(find(r, InsightKind.bestDay)!.weekday, DateTime.sunday);
    expect(find(r, InsightKind.hardDay)!.weekday, DateTime.friday);
    // Hari ini 3.5 (dua entri), lainnya 4: selisih 0.5 < 1 poin.
    final tipis = ReportEngine.build([c(0, 'cukup_baik'), j(0, 'datar', 'hakim'), c(1, 'cukup_baik'), c(2, 'cukup_baik')], now: now);
    expect(find(tipis, InsightKind.bestDay), isNull, reason: 'selisih terlalu tipis untuk disebut');
  });

  test('faktor terbanyak butuh minimal dua kali muncul dan mengabaikan "lainnya"', () {
    final r = ReportEngine.build([
      c(0, 'datar', factors: ['kerjaan', 'lainnya']),
      c(1, 'datar', factors: ['kerjaan', 'lainnya']),
      c(2, 'datar', factors: ['uang', 'lainnya']),
    ], now: now);
    final top = find(r, InsightKind.topFactor)!;
    expect(top.id, 'kerjaan');
    expect(top.count, 2);
    final sekali = ReportEngine.build([c(0, 'datar', factors: ['uang']), c(1, 'datar', factors: ['kerjaan']), c(2, 'datar')], now: now);
    expect(find(sekali, InsightKind.topFactor), isNull);
  });

  test('monster jurnal terbanyak', () {
    final r = ReportEngine.build([c(0, 'datar'), c(1, 'datar'), c(2, 'datar'), j(0, 'datar', 'kabut'), j(1, 'datar', 'kabut'), j(2, 'datar', 'hakim')], now: now);
    final top = find(r, InsightKind.topMonster)!;
    expect(top.id, 'kabut');
    expect(top.count, 2);
  });

  test('pola faktor ↔ mood: Premium, arah negatif, butuh cukup hari dengan dan tanpa', () {
    final r = ReportEngine.build([
      c(0, 'agak_berat', factors: ['kurang_tidur']),
      c(1, 'berat', factors: ['kurang_tidur']),
      c(2, 'cukup_baik'),
      c(3, 'senang'),
    ], now: now);
    final i = find(r, InsightKind.factorMood)!;
    expect(i.id, 'kurang_tidur');
    expect(i.direction, -1);
    expect(i.premium, isTrue);
    // Hanya satu hari dengan faktor: tidak cukup.
    final sedikit = ReportEngine.build([c(0, 'berat', factors: ['uang']), c(1, 'senang'), c(2, 'cukup_baik'), c(3, 'senang')], now: now);
    expect(find(sedikit, InsightKind.factorMood), isNull);
  });

  test('tiga hari berat berturut-turut hingga hari ini → tawarkan dukungan', () {
    expect(ReportEngine.build([c(0, 'berat'), c(1, 'agak_berat'), c(2, 'berat')], now: now).needsSupport, isTrue);
    // Ada hari biasa di tengah → bukan rangkaian.
    expect(ReportEngine.build([c(0, 'berat'), c(1, 'datar'), c(2, 'berat')], now: now).needsSupport, isFalse);
    // Rangkaian sudah lama lewat.
    expect(ReportEngine.build([c(4, 'berat'), c(5, 'berat'), c(6, 'berat')], now: now).needsSupport, isFalse);
    // Berakhir kemarin masih dihitung.
    expect(ReportEngine.build([c(1, 'berat'), c(2, 'berat'), c(3, 'berat')], now: now).needsSupport, isTrue);
  });

  test('jendela bulanan mengumpulkan 28 hari', () {
    final r = ReportEngine.build([c(0, 'senang'), c(15, 'senang'), c(27, 'senang'), c(28, 'berat')], now: now, windowDays: ReportConfig.monthDays);
    expect(r.days.length, 28);
    expect(r.activeDays, 3, reason: 'hari ke-28 sudah di luar jendela');
  });

  test('mood tak dikenal diabaikan, tidak membuat error', () {
    final r = ReportEngine.build([c(0, ''), c(1, 'aneh'), c(2, 'datar')], now: now);
    expect(r.averageMood, 3.0);
  });

  group('data tidur', () {
    DateTime d(int daysAgo) => now.subtract(Duration(days: daysAgo));

    test('rata-rata tidur butuh cukup malam', () {
      final entries = [c(0, 'datar'), c(1, 'datar'), c(2, 'datar')];
      final sedikit = ReportEngine.build(entries, now: now, sleepMinutes: {d(0): 400, d(1): 420});
      expect(find(sedikit, InsightKind.sleepAverage), isNull);
      final cukup = ReportEngine.build(entries, now: now, sleepMinutes: {d(0): 360, d(1): 420, d(2): 480});
      expect(find(cukup, InsightKind.sleepAverage)!.count, 420);
    });

    test('pola tidur cukup ↔ mood lebih baik: Premium, butuh dua hari per kelompok', () {
      final entries = [c(0, 'agak_berat'), c(1, 'berat'), c(2, 'cukup_baik'), c(3, 'senang')];
      final sleep = {d(0): 300, d(1): 330, d(2): 450, d(3): 480};
      final i = find(ReportEngine.build(entries, now: now, sleepMinutes: sleep), InsightKind.sleepMood)!;
      expect(i.premium, isTrue);
      expect(i.direction, 1);
      // Hanya satu hari tidur singkat: tidak cukup untuk membandingkan.
      final tipis = ReportEngine.build(entries, now: now, sleepMinutes: {d(0): 300, d(1): 430, d(2): 450, d(3): 480});
      expect(find(tipis, InsightKind.sleepMood), isNull);
    });

    test('tidur lebih singkat tetapi mood tidak lebih rendah → tidak disebut', () {
      final entries = [c(0, 'senang'), c(1, 'senang'), c(2, 'datar'), c(3, 'datar')];
      final sleep = {d(0): 300, d(1): 330, d(2): 450, d(3): 480};
      expect(find(ReportEngine.build(entries, now: now, sleepMinutes: sleep), InsightKind.sleepMood), isNull);
    });

    test('sesi mentah → satu malam per tanggal bangun, sesi terpanjang, tidur siang diabaikan', () {
      DateTime t(int day, int h, int m) => DateTime(2026, 9, day, h, m);
      final nights = SleepNight.fromSessions([
        (from: t(25, 23, 0), to: t(26, 6, 30)), // 450 menit
        (from: t(25, 23, 10), to: t(26, 6, 20)), // sumber ganda, lebih pendek
        (from: t(26, 13, 0), to: t(26, 13, 40)), // tidur siang 40 menit
        (from: t(26, 23, 30), to: t(27, 5, 30)), // 360 menit
      ]);
      expect(nights.map((n) => n.minutes), [450, 360]);
      expect(nights.first.wakeDate, DateTime(2026, 9, 26));
    });
  });
}
