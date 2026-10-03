/// Semua berkas audio yang dibundel di app (offline-first, CLAUDE.md aturan
/// #5). Sumber & lisensi lengkap: `assets/audio/CREDITS.md`.
///
/// Cerita tidur: rekaman LibriVox (domain publik / CC0), berbahasa Inggris.
/// Suara latar: rekaman Joseph Sardin (La Sonothèque / BigSoundBank), CC0.
abstract final class AudioAssets {
  static const _sleep = 'assets/audio/sleep';
  static const _ambient = 'assets/audio/ambient';

  static const happyPrince = '$_sleep/happy_prince.mp3';
  static const nightingaleRose = '$_sleep/nightingale_rose.mp3';
  static const selfishGiant = '$_sleep/selfish_giant.mp3';
  static const velveteenRabbit = '$_sleep/velveteen_rabbit.mp3';

  static const rain = '$_ambient/rain.mp3';
  static const waves = '$_ambient/waves.mp3';
  static const fan = '$_ambient/fan.mp3';

  /// Nada lembut lama — cadangan kalau berkas lain gagal dimuat.
  static const fallbackTone = 'assets/audio/placeholder_tone.wav';
}
