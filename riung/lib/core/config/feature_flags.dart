/// Saklar fitur yang belum siap rilis.
abstract final class FeatureFlags {
  /// Aksesoris monster (syal, bingkai cermin, dll.): disembunyikan sampai
  /// asetnya siap. Set `true` untuk memunculkan lagi section Toko, tombol
  /// Lemari, dan kosmetik yang dipakai monster. Data kepemilikan tidak disentuh.
  static const bool monsterCosmetics = false;

  /// Aksesori, paket, & gaya kartu karakter kepribadian (termasuk klaim
  /// Premium-nya): disembunyikan bersama aksesoris monster.
  static const bool characterAccessories = false;
}
