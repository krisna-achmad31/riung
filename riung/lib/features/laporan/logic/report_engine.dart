import '../../../core/models/check_in.dart';
import '../../../core/models/journal_entry.dart';
import '../../jurnal/logic/journal_prompts.dart';
import 'report_config.dart';
import 'report_models.dart';

/// Mesin laporan refleksi: kode murni, jalan di perangkat, tanpa AI dan tanpa
/// jaringan. Setiap insight dihitung dari data check-in/jurnal lewat aturan di
/// [ReportConfig], jadi bisa dihitung ulang dari data yang sama (lihat
/// `test/report_engine_test.dart`). Isi tulisan jurnal tidak pernah dibaca.
abstract final class ReportEngine {
  /// Ubah check-in & jurnal jadi entri laporan (tanpa teks jurnal).
  static List<ReportEntry> entriesFrom(List<CheckIn> checkIns, List<JournalEntry> journals) {
    final monsterByPrompt = {for (final p in journalPrompts) p.id: p.monsterId};
    return [
      for (final c in checkIns) ReportEntry(date: c.date, mood: c.mood, factors: c.factors),
      for (final j in journals) ReportEntry(date: j.createdAt, mood: j.mood, monsterId: monsterByPrompt[j.promptId], isJournal: true),
    ];
  }

  /// [sleepMinutes]: menit tidur per tanggal bangun (opsional, dari Health Connect).
  static Report build(
    List<ReportEntry> entries, {
    required DateTime now,
    int windowDays = ReportConfig.weekDays,
    Map<DateTime, int> sleepMinutes = const {},
  }) {
    final today = _day(now);
    final start = today.subtract(Duration(days: windowDays - 1));
    final prevStart = start.subtract(Duration(days: windowDays));
    final prevEnd = start.subtract(const Duration(days: 1));

    final current = [for (final e in entries) if (!_day(e.date).isBefore(start) && !_day(e.date).isAfter(today)) e];
    final previous = [for (final e in entries) if (!_day(e.date).isBefore(prevStart) && !_day(e.date).isAfter(prevEnd)) e];

    final byDay = _dayAverages(current);
    final days = [
      for (var i = 0; i < windowDays; i++) ReportDay(date: start.add(Duration(days: i)), mood: byDay[start.add(Duration(days: i))]),
    ];
    final previousByDay = _dayAverages(previous);

    final insights = <ReportInsight>[
      ..._trend(byDay, previousByDay),
      ..._bestHard(byDay),
      ..._topFactor(current),
      ..._topMonster(current),
      ..._factorMood(current),
      ..._sleep(byDay, sleepMinutes, start, today),
    ];

    return Report(
      days: days,
      windowDays: windowDays,
      activeDays: {for (final e in current) _day(e.date)}.length,
      checkInCount: current.where((e) => !e.isJournal).length,
      journalCount: current.where((e) => e.isJournal).length,
      averageMood: _mean(byDay.values),
      previousAverageMood: _mean(previousByDay.values),
      insights: insights,
      needsSupport: _needsSupport(byDay, today),
    );
  }

  // ── insight ──

  static List<ReportInsight> _trend(Map<DateTime, double> now, Map<DateTime, double> before) {
    if (now.length < ReportConfig.minActiveDays || before.length < ReportConfig.minActiveDays) return const [];
    final delta = _mean(now.values)! - _mean(before.values)!;
    final direction = delta >= ReportConfig.trendDelta ? 1 : (delta <= -ReportConfig.trendDelta ? -1 : 0);
    return [ReportInsight(kind: InsightKind.moodTrend, direction: direction)];
  }

  static List<ReportInsight> _bestHard(Map<DateTime, double> byDay) {
    if (byDay.length < ReportConfig.minActiveDays) return const [];
    final byWeekday = <int, List<double>>{};
    byDay.forEach((d, v) => byWeekday.putIfAbsent(d.weekday, () => []).add(v));
    if (byWeekday.length < 2) return const [];
    final avg = {for (final e in byWeekday.entries) e.key: _mean(e.value)!};
    final ordered = avg.keys.toList()..sort();
    var best = ordered.first;
    var hard = ordered.first;
    for (final w in ordered) {
      if (avg[w]! > avg[best]!) best = w;
      if (avg[w]! < avg[hard]!) hard = w;
    }
    if (avg[best]! - avg[hard]! < ReportConfig.bestHardGap) return const [];
    return [
      ReportInsight(kind: InsightKind.bestDay, weekday: best),
      ReportInsight(kind: InsightKind.hardDay, weekday: hard),
    ];
  }

  static List<ReportInsight> _topFactor(List<ReportEntry> entries) {
    final counts = <String, int>{};
    for (final e in entries.where((e) => !e.isJournal)) {
      for (final f in e.factors.toSet()) {
        if (!ReportConfig.ignoredFactors.contains(f)) counts[f] = (counts[f] ?? 0) + 1;
      }
    }
    final top = _top(counts);
    if (top == null || counts[top]! < ReportConfig.minMentions) return const [];
    return [ReportInsight(kind: InsightKind.topFactor, id: top, count: counts[top]!)];
  }

  static List<ReportInsight> _topMonster(List<ReportEntry> entries) {
    final counts = <String, int>{};
    for (final e in entries) {
      final m = e.monsterId;
      if (e.isJournal && m != null) counts[m] = (counts[m] ?? 0) + 1;
    }
    final top = _top(counts);
    if (top == null || counts[top]! < ReportConfig.minMentions) return const [];
    return [ReportInsight(kind: InsightKind.topMonster, id: top, count: counts[top]!)];
  }

  /// Pola faktor ↔ mood: bandingkan rata-rata mood pada hari yang memuat faktor
  /// itu dengan hari lain. Hanya korelasi ("cenderung"), tidak pernah sebab-akibat.
  static List<ReportInsight> _factorMood(List<ReportEntry> entries) {
    final byDay = _dayAverages(entries);
    final daysWithFactor = <String, Set<DateTime>>{};
    for (final e in entries.where((e) => !e.isJournal)) {
      for (final f in e.factors.toSet()) {
        if (!ReportConfig.ignoredFactors.contains(f)) daysWithFactor.putIfAbsent(f, () => {}).add(_day(e.date));
      }
    }
    String? bestFactor;
    var bestDiff = 0.0;
    final factors = daysWithFactor.keys.toList()..sort();
    for (final f in factors) {
      final withDays = daysWithFactor[f]!.where(byDay.containsKey).toList();
      final withoutDays = byDay.keys.where((d) => !daysWithFactor[f]!.contains(d)).toList();
      if (withDays.length < ReportConfig.minFactorDays || withoutDays.length < ReportConfig.minFactorDays) continue;
      final diff = _mean(withDays.map((d) => byDay[d]!))! - _mean(withoutDays.map((d) => byDay[d]!))!;
      if (diff.abs() >= ReportConfig.factorMoodGap && diff.abs() > bestDiff.abs()) {
        bestFactor = f;
        bestDiff = diff;
      }
    }
    if (bestFactor == null) return const [];
    return [ReportInsight(kind: InsightKind.factorMood, id: bestFactor, direction: bestDiff < 0 ? -1 : 1, count: daysWithFactor[bestFactor]!.length, premium: true)];
  }

  /// Rata-rata tidur (gratis) dan pola tidur cukup ↔ mood (Premium). Malam
  /// dipasangkan dengan mood pada tanggal bangunnya.
  static List<ReportInsight> _sleep(Map<DateTime, double> moodByDay, Map<DateTime, int> sleep, DateTime start, DateTime today) {
    final nights = {
      for (final e in sleep.entries)
        if (!_day(e.key).isBefore(start) && !_day(e.key).isAfter(today)) _day(e.key): e.value,
    };
    if (nights.length < ReportConfig.minActiveDays) return const [];
    final insights = [
      ReportInsight(kind: InsightKind.sleepAverage, count: _mean(nights.values)!.round()),
    ];
    final short = <double>[];
    final rested = <double>[];
    nights.forEach((day, minutes) {
      final mood = moodByDay[day];
      if (mood == null) return;
      if (minutes < ReportConfig.shortSleepMinutes) short.add(mood);
      if (minutes >= ReportConfig.restedSleepMinutes) rested.add(mood);
    });
    if (short.length >= ReportConfig.minFactorDays && rested.length >= ReportConfig.minFactorDays) {
      final diff = _mean(rested)! - _mean(short)!;
      if (diff >= ReportConfig.factorMoodGap) {
        insights.add(ReportInsight(kind: InsightKind.sleepMood, direction: 1, count: short.length, premium: true));
      }
    }
    return insights;
  }

  /// Hari berat berturut-turut yang berakhir hari ini/kemarin.
  static bool _needsSupport(Map<DateTime, double> byDay, DateTime today) {
    var cursor = byDay.containsKey(today) ? today : today.subtract(const Duration(days: 1));
    var run = 0;
    while (byDay[cursor] != null && byDay[cursor]! <= ReportConfig.lowMood) {
      run++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return run >= ReportConfig.lowMoodStreakDays;
  }

  // ── util ──

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  static Map<DateTime, double> _dayAverages(List<ReportEntry> entries) {
    final sums = <DateTime, List<int>>{};
    for (final e in entries) {
      final v = ReportConfig.moodValue[e.mood];
      if (v != null) sums.putIfAbsent(_day(e.date), () => []).add(v);
    }
    return {for (final e in sums.entries) e.key: _mean(e.value)!};
  }

  static double? _mean(Iterable<num> values) {
    if (values.isEmpty) return null;
    return values.fold<double>(0, (a, b) => a + b) / values.length;
  }

  /// Kunci terbanyak; seri dipecah alfabetis supaya hasilnya deterministik.
  static String? _top(Map<String, int> counts) {
    if (counts.isEmpty) return null;
    final keys = counts.keys.toList()..sort();
    var best = keys.first;
    for (final k in keys) {
      if (counts[k]! > counts[best]!) best = k;
    }
    return best;
  }
}
