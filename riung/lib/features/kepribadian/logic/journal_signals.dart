import '../../../core/models/journal_entry.dart';

/// Pola halus dari METADATA jurnal 30 hari terakhir: suasana hati, jam
/// menulis, tema monster dari panduan CBT. TIDAK membaca isi tulisan sama
/// sekali (lihat `KepribadianStrings.signalsNote`), dan dihitung penuh di
/// perangkat. Bukan alat penilaian kepribadian — hanya pelengkap refleks.
class JournalSignals {
  const JournalSignals({required this.entryCount, this.topMood, this.topPeriod, this.topTag});

  final int entryCount;
  final String? topMood;

  /// morning (05–11), afternoon (11–15), evening (15–19), night (19–05).
  final String? topPeriod;
  final String? topTag;

  bool get isEmpty => entryCount == 0;

  static String periodOf(DateTime time) {
    final h = time.hour;
    if (h >= 5 && h < 11) return 'morning';
    if (h >= 11 && h < 15) return 'afternoon';
    if (h >= 15 && h < 19) return 'evening';
    return 'night';
  }

  static JournalSignals from(List<JournalEntry> entries, {DateTime? now, int days = 30}) {
    final today = now ?? DateTime.now();
    final cutoff = today.subtract(Duration(days: days));
    final recent = entries.where((e) => e.createdAt.isAfter(cutoff)).toList();
    String? top(Iterable<String> values) {
      final counts = <String, int>{};
      for (final v in values) {
        if (v.isEmpty) continue;
        counts[v] = (counts[v] ?? 0) + 1;
      }
      if (counts.isEmpty) return null;
      return (counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).first.key;
    }

    return JournalSignals(
      entryCount: recent.length,
      topMood: top(recent.map((e) => e.mood)),
      topPeriod: top(recent.map((e) => periodOf(e.createdAt))),
      topTag: top(recent.expand((e) => e.tags)),
    );
  }
}
