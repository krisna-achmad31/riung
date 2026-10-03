import 'package:flutter/widgets.dart';

import '../theme/theme.dart';

/// Satu aplikasi yang bisa dibekukan — katalog tetap di kode (bukan
/// Firestore/Remote Config) karena package name & tile adalah detail
/// visual/teknis, bukan angka ekonomi. Mirror `design/AppBeku.dc.html`
/// § freezeApps (Instagram jadi contoh default aktif di mockup, di sini
/// semua mulai nonaktif — user yang pilih sendiri di AppBekuSetupScreen).
class AppBekuCatalogEntry {
  const AppBekuCatalogEntry({
    required this.packageName,
    required this.name,
    required this.tile,
    required this.tileColor,
    this.avgMinutesPerDay,
  });

  final String packageName;
  final String name;
  final String tile;
  final Color tileColor;

  /// Rata-rata pemakaian nasional (menit/hari) — cuma konteks di kartu, bukan
  /// data user; kalimatnya per bahasa (`AppbekuStrings.appUsageAverage`).
  /// Null untuk aplikasi yang tidak dibekukan (WhatsApp).
  final int? avgMinutesPerDay;
}

abstract final class AppBekuCatalog {
  static const instagram = AppBekuCatalogEntry(
    packageName: 'com.instagram.android',
    name: 'Instagram',
    tile: 'Ig',
    tileColor: AppColors.error,
    avgMinutesPerDay: 126,
  );

  static const tiktok = AppBekuCatalogEntry(
    packageName: 'com.zhiliaoapp.musically',
    name: 'TikTok',
    tile: 'TT',
    tileColor: AppColors.sekunder,
    avgMinutesPerDay: 84,
  );

  static const youtube = AppBekuCatalogEntry(
    packageName: 'com.google.android.youtube',
    name: 'YouTube',
    tile: 'YT',
    tileColor: AppColors.error,
    avgMinutesPerDay: 56,
  );

  static const x = AppBekuCatalogEntry(
    packageName: 'com.twitter.android',
    name: 'X',
    tile: 'X',
    tileColor: AppColors.teksSekunder,
    avgMinutesPerDay: 31,
  );

  static const mobileLegends = AppBekuCatalogEntry(
    packageName: 'com.mobile.legends',
    name: 'Mobile Legends',
    tile: 'ML',
    tileColor: AppColors.aksenHangat,
    avgMinutesPerDay: 48,
  );

  /// Dikeluarkan default (bukan disembunyikan) — jalur komunikasi tetap
  /// terbuka, lihat `design/AppBeku.dc.html` catatan WhatsApp.
  static const whatsapp = AppBekuCatalogEntry(
    packageName: 'com.whatsapp',
    name: 'WhatsApp',
    tile: 'WA',
    tileColor: AppColors.sukses,
  );

  /// Sosmed (dipakai bundel "Semua sosmed" di Toko).
  static const List<AppBekuCatalogEntry> sosmed = [instagram, tiktok, youtube, x];

  static const List<AppBekuCatalogEntry> semua = [instagram, tiktok, youtube, x, mobileLegends];

  static AppBekuCatalogEntry? byPackage(String packageName) {
    for (final entry in semua) {
      if (entry.packageName == packageName) return entry;
    }
    return null;
  }
}
