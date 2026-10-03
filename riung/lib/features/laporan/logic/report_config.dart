/// Ambang & pemetaan laporan refleksi. Semua angka di sini (bukan tersebar di
/// mesin/layar), supaya setiap kalimat di laporan bisa ditelusuri ke aturan
/// yang jelas dan mudah disetel.
abstract final class ReportConfig {
  /// Skala mood 1..5 dari id mood check-in/jurnal. Id tak dikenal diabaikan.
  static const Map<String, int> moodValue = {
    'berat': 1,
    'agak_berat': 2,
    'datar': 3,
    'cukup_baik': 4,
    'senang': 5,
  };

  /// Jendela laporan (hari). Mingguan gratis, bulanan Premium.
  static const int weekDays = 7;
  static const int monthDays = 28;

  /// Hari aktif minimum (ada check-in) supaya laporan menampilkan angka.
  /// Di bawah ini layar hanya mengajak, tanpa menyimpulkan apa pun.
  static const int minActiveDays = 3;

  /// Perubahan rata-rata mood (skala 1..5) yang dianggap naik/turun; di
  /// antaranya dianggap stabil.
  static const double trendDelta = 0.4;

  /// Selisih mood hari terbaik dan terberat minimal agar keduanya disebut.
  static const double bestHardGap = 1.0;

  /// Faktor/monster baru disebut kalau muncul sekurang-kurangnya sekian kali.
  static const int minMentions = 2;

  /// Pola faktor ↔ mood (Premium): minimal hari dengan dan tanpa faktor itu,
  /// serta selisih rata-rata mood minimal.
  static const int minFactorDays = 2;
  static const double factorMoodGap = 0.6;

  /// Mood ≤ ini dihitung "berat".
  static const int lowMood = 2;

  /// Sekian hari berat berturut-turut → tawarkan dukungan (bukan diagnosis).
  static const int lowMoodStreakDays = 3;

  /// Data tidur (Health Connect): di bawah ini dianggap tidur singkat, di
  /// atas/sama dengan ini cukup istirahat. Pola tidur ↔ mood butuh sekurang-
  /// kurangnya [minFactorDays] hari di tiap kelompok.
  static const int shortSleepMinutes = 6 * 60;
  static const int restedSleepMinutes = 7 * 60;

  /// Faktor yang tidak informatif dan diabaikan dari pola.
  static const Set<String> ignoredFactors = {'lainnya'};
}
