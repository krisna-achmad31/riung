import 'report_config.dart';

/// Satu entri mentah untuk laporan: hanya tanggal, mood, dan penanda —
/// TIDAK PERNAH isi tulisan jurnal.
class ReportEntry {
  const ReportEntry({required this.date, required this.mood, this.factors = const [], this.monsterId, this.isJournal = false});

  final DateTime date;

  /// Id mood ('berat' .. 'senang').
  final String mood;
  final List<String> factors;

  /// Monster dari panduan jurnal CBT (kalau ada).
  final String? monsterId;
  final bool isJournal;
}

enum InsightKind {
  /// Rata-rata mood dibanding periode sebelumnya. `direction` -1/0/1.
  moodTrend,

  /// Hari (weekday 1=Senin..7=Minggu) dengan mood tertinggi.
  bestDay,

  /// Hari dengan mood paling berat.
  hardDay,

  /// Faktor yang paling sering dipilih di check-in. `id` = id faktor.
  topFactor,

  /// Monster yang paling sering muncul di jurnal. `id` = id monster.
  topMonster,

  /// Pola faktor ↔ mood (Premium). `id` = faktor, `direction` = -1 (mood lebih rendah) / 1.
  factorMood,

  /// Rata-rata durasi tidur dari jam tangan. `count` = menit.
  sleepAverage,

  /// Pola tidur ↔ mood (Premium): mood cenderung lebih baik setelah tidur cukup. `direction` = 1.
  sleepMood,
}

class ReportInsight {
  const ReportInsight({required this.kind, this.id, this.weekday, this.direction = 0, this.count = 0, this.premium = false});

  final InsightKind kind;
  final String? id;
  final int? weekday;
  final int direction;
  final int count;

  /// Hanya tampil untuk pelanggan Premium (yang lain melihat kunci lembut).
  final bool premium;
}

/// Rata-rata mood satu hari (null = tidak ada data hari itu).
class ReportDay {
  const ReportDay({required this.date, this.mood});

  final DateTime date;
  final double? mood;
}

class Report {
  const Report({
    required this.days,
    required this.windowDays,
    required this.activeDays,
    required this.checkInCount,
    required this.journalCount,
    required this.averageMood,
    required this.previousAverageMood,
    required this.insights,
    required this.needsSupport,
  });

  final List<ReportDay> days;
  final int windowDays;

  /// Hari yang punya check-in atau jurnal.
  final int activeDays;
  final int checkInCount;
  final int journalCount;
  final double? averageMood;
  final double? previousAverageMood;
  final List<ReportInsight> insights;

  /// Beberapa hari berat berturut-turut → layar menawarkan dukungan.
  final bool needsSupport;

  /// Cukup data untuk menyimpulkan sesuatu.
  bool get hasEnoughData => activeDays >= ReportConfig.minActiveDays && averageMood != null;
}
