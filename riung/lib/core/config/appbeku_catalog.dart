import 'package:flutter/material.dart';

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
    required this.icon,
    this.tileColorEnd,
    this.avgMinutesPerDay,
  });

  final String packageName;
  final String name;
  final String tile;
  final Color tileColor;

  /// Ujung gradien tile (Instagram); null = warna rata.
  final Color? tileColorEnd;

  /// Ikon garis putih di tile kaca (frame `App …`).
  final IconData icon;

  List<Color> get tileColors => [tileColor, tileColorEnd ?? tileColor];

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
    tileColor: AppColors.appInstagramAwal,
    tileColorEnd: AppColors.appInstagramAkhir,
    icon: Icons.camera_alt_outlined,
    avgMinutesPerDay: 126,
  );

  static const tiktok = AppBekuCatalogEntry(
    packageName: 'com.zhiliaoapp.musically',
    name: 'TikTok',
    tile: 'TT',
    tileColor: AppColors.appTiktok,
    icon: Icons.music_note_rounded,
    avgMinutesPerDay: 84,
  );

  static const youtube = AppBekuCatalogEntry(
    packageName: 'com.google.android.youtube',
    name: 'YouTube',
    tile: 'YT',
    tileColor: AppColors.appYoutube,
    icon: Icons.play_arrow_rounded,
    avgMinutesPerDay: 56,
  );

  static const x = AppBekuCatalogEntry(
    packageName: 'com.twitter.android',
    name: 'X',
    tile: 'X',
    tileColor: AppColors.appX,
    icon: Icons.alternate_email_rounded,
    avgMinutesPerDay: 31,
  );

  static const mobileLegends = AppBekuCatalogEntry(
    packageName: 'com.mobile.legends',
    name: 'Mobile Legends',
    tile: 'ML',
    tileColor: AppColors.aksenHangat,
    icon: Icons.sports_esports_outlined,
    avgMinutesPerDay: 48,
  );

  /// Dikeluarkan default (bukan disembunyikan) — jalur komunikasi tetap
  /// terbuka, lihat `design/AppBeku.dc.html` catatan WhatsApp.
  static const whatsapp = AppBekuCatalogEntry(
    packageName: 'com.whatsapp',
    name: 'WhatsApp',
    tile: 'WA',
    tileColor: AppColors.appWhatsapp,
    icon: Icons.chat_bubble_outline_rounded,
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
