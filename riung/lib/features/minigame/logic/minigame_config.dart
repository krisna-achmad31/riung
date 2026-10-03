/// Konfigurasi mini-game pecahkan balok — durasi, nyawa, dan ambang menang
/// bersumber di satu tempat (CLAUDE.md §3), tidak ditulis lepas di layar.
/// Angka ekonomi (koin, progres) tetap di `economy.dart`.
abstract final class MinigameConfig {
  static const int sessionSeconds = 60;

  /// Bola yang jatuh melewati papan mengurangi satu nyawa.
  static const int lives = 3;

  /// HP bos turun sekian persen tiap balok "vonis" pecah, dan tiap kali bola
  /// mengenai tubuh bos langsung. HP 0 sebelum waktu habis = menang.
  static const double hpPerBlockPercent = 5;
  static const double hpPerBodyHitPercent = 3;

  /// Poin (tampilan saja) — desain: "+120 pts" per balok.
  static const int pointsPerBlock = 120;
  static const int pointsPerBodyHit = 40;

  static const double ballSpeedStart = 230;
  static const double ballSpeedPerBlock = 6;
  static const double ballSpeedMax = 330;
}
