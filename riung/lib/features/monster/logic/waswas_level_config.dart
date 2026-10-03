/// Struktur "level" (unit ala Duolingo) untuk latihan Si Waswas — uji coba
/// per-monster sebelum direplikasi ke saboteur lain. Level TIDAK disimpan
/// sebagai field baru: dihitung dari `MonsterProgress.progress` yang sudah
/// ada, sama seperti `intensity` di `WaswasReactionEngine`.
///
/// Tiap level = 2 step latihan kecil + 1 bos. Bos level awal memakai Block
/// Breaker (mekanik yang sudah ada, ditala makin cepat lewat [WaswasBossType.speedBonus]);
/// bos level terakhir baru memakai mekanik baru "Lepaskan Pikiran" —
/// escalating difficulty & mekanik ala Meat Boy, bukan cuma angka.
enum WaswasStepType { napas, jurnal, afirmasi }

enum WaswasBossType {
  blockBreakerEasy,
  blockBreakerMedium,
  blockBreakerHard,
  reaction;

  /// Bonus kecepatan awal bola Block Breaker (lihat `BlockBreakerEngine`).
  /// 0 untuk [reaction] karena tidak dipakai di sana.
  double get speedBonus => switch (this) {
        WaswasBossType.blockBreakerEasy => 0,
        WaswasBossType.blockBreakerMedium => 30,
        WaswasBossType.blockBreakerHard => 60,
        WaswasBossType.reaction => 0,
      };
}

class WaswasLevelDef {
  const WaswasLevelDef({required this.level, required this.minProgress, required this.steps, required this.boss});

  final int level;
  final int minProgress;
  final List<WaswasStepType> steps;
  final WaswasBossType boss;
}

const waswasLevels = [
  WaswasLevelDef(level: 1, minProgress: 0, steps: [WaswasStepType.napas, WaswasStepType.afirmasi], boss: WaswasBossType.blockBreakerEasy),
  WaswasLevelDef(level: 2, minProgress: 20, steps: [WaswasStepType.jurnal, WaswasStepType.napas], boss: WaswasBossType.blockBreakerEasy),
  WaswasLevelDef(level: 3, minProgress: 40, steps: [WaswasStepType.afirmasi, WaswasStepType.jurnal], boss: WaswasBossType.blockBreakerMedium),
  WaswasLevelDef(level: 4, minProgress: 60, steps: [WaswasStepType.napas, WaswasStepType.afirmasi], boss: WaswasBossType.blockBreakerHard),
  WaswasLevelDef(level: 5, minProgress: 80, steps: [WaswasStepType.jurnal, WaswasStepType.afirmasi], boss: WaswasBossType.reaction),
];

/// Level tertinggi yang ambang `minProgress`-nya sudah terlampaui.
WaswasLevelDef waswasLevelForProgress(int progress) =>
    waswasLevels.lastWhere((l) => progress >= l.minProgress, orElse: () => waswasLevels.first);
