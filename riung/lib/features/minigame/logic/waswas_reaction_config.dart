/// Konfigurasi mini-game "Lepaskan Pikiran" (Si Waswas) — kecepatan &
/// jeda kemunculan gelembung khawatir, bukan angka ekonomi (itu tetap di
/// `economy.dart`, CLAUDE.md §3). Durasi sesi & nyawa memakai
/// [MinigameConfig] yang sama supaya konsisten dengan mini-game lain.
///
/// Kesulitan naik saat Si Waswas masih liar (progres rendah) dan turun
/// begitu sering dilatih — bukan dari pembelian (CLAUDE.md aturan #4).
/// Lihat `WaswasReactionEngine(intensity: ...)`, dihitung dari
/// `100 - MonsterProgress.progress`.
abstract final class WaswasReactionConfig {
  /// Jeda antar kemunculan gelembung (detik) di intensitas termudah/tersulit.
  static const double spawnIntervalEasy = 2.2;
  static const double spawnIntervalHard = 0.9;

  /// Kecepatan naik gelembung (unit dunia/detik) di intensitas termudah/tersulit.
  static const double riseSpeedEasy = 70;
  static const double riseSpeedHard = 150;

  /// Radius sentuh gelembung (unit dunia).
  static const double bubbleRadius = 34;

  static const int pointsPerPop = 90;
}
