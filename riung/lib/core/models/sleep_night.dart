/// Satu malam tidur (perkiraan) dari Health Connect. Hanya dibaca di perangkat
/// untuk laporan refleksi; tidak disimpan dan tidak dikirim ke server.
class SleepNight {
  const SleepNight({required this.wakeDate, required this.minutes});

  /// Tanggal bangun (tanpa jam) — malam ini dipasangkan dengan mood hari itu.
  final DateTime wakeDate;
  final int minutes;

  /// Gabungkan sesi tidur mentah jadi satu malam per tanggal bangun. Sesi
  /// terpanjang dianggap tidur utama (tidur siang & sesi ganda dari dua
  /// sumber tidak menggandakan durasi). Sesi < [minSessionMinutes] diabaikan.
  static List<SleepNight> fromSessions(Iterable<({DateTime from, DateTime to})> sessions, {int minSessionMinutes = 120}) {
    final longest = <DateTime, int>{};
    for (final s in sessions) {
      final minutes = s.to.difference(s.from).inMinutes;
      if (minutes < minSessionMinutes) continue;
      final day = DateTime(s.to.year, s.to.month, s.to.day);
      if (minutes > (longest[day] ?? 0)) longest[day] = minutes;
    }
    final nights = [for (final e in longest.entries) SleepNight(wakeDate: e.key, minutes: e.value)];
    nights.sort((a, b) => a.wakeDate.compareTo(b.wakeDate));
    return nights;
  }
}
