import 'package:flutter/services.dart';

/// Jembatan ke `AppUsageMethodChannel.kt` — baca menit pemakaian aplikasi
/// lain hari ini lewat UsageStatsManager Android, dan cek/buka izin
/// "Akses data penggunaan". Lihat CLAUDE.md M6 Task 1 & catatan keamanan di
/// `AppUsageMethodChannel.kt`: data ini nggak pernah meninggalkan
/// perangkat, cuma dipakai untuk gerbang lokal Aplikasi Beku.
class AppUsageService {
  static const _channel = MethodChannel('com.riung.riung/app_usage');

  Future<bool> hasUsageAccess() async {
    try {
      return await _channel.invokeMethod<bool>('hasUsageAccess') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<void> openUsageAccessSettings() async {
    try {
      await _channel.invokeMethod('openUsageAccessSettings');
    } on PlatformException {
      // Diam-diam gagal — layar pemanggil tetap menampilkan tombol,
      // user bisa coba lagi atau buka manual dari Pengaturan Android.
    } on MissingPluginException {
      // no-op
    }
  }

  Future<bool> hasAccessibilityAccess() async {
    try {
      return await _channel.invokeMethod<bool>('hasAccessibilityAccess') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<void> openAccessibilitySettings() async {
    try {
      await _channel.invokeMethod('openAccessibilitySettings');
    } on PlatformException {
      // Sama seperti openUsageAccessSettings: gagal diam-diam.
    } on MissingPluginException {
      // no-op
    }
  }

  /// Dorong konfigurasi kunci ke service pemantau native. [entries] berisi
  /// batas dasar & menit ekstra hari ini per package; native mematikan
  /// dirinya sendiri kalau [enabled] false / izin belum ada.
  Future<void> syncLockConfig({
    required bool enabled,
    required String date,
    required List<({String package, int base, int extra})> entries,
    required String notifTitle,
    required String notifBody,
  }) async {
    try {
      await _channel.invokeMethod('syncLockConfig', {
        'enabled': enabled,
        'date': date,
        'notifTitle': notifTitle,
        'notifBody': notifBody,
        'entries': [
          for (final e in entries) {'package': e.package, 'base': e.base, 'extra': e.extra},
        ],
      });
    } on PlatformException {
      // Best-effort — kunci tidak aktif kalau native gagal, app tetap jalan.
    } on MissingPluginException {
      // no-op (mis. widget test)
    }
  }

  /// Package yang barusan dikunci service native (dibaca sekali lalu dihapus),
  /// atau null.
  Future<String?> consumeLockPackage() async {
    try {
      return await _channel.invokeMethod<String>('consumeLockPackage');
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  /// Ke layar utama Android (launcher).
  Future<void> goHome() async {
    try {
      await _channel.invokeMethod('goHome');
    } on PlatformException {
      // no-op
    } on MissingPluginException {
      // no-op
    }
  }

  /// Kirim Riung ke belakang — user kembali ke aplikasi sebelumnya.
  Future<void> moveToBack() async {
    try {
      await _channel.invokeMethod('moveToBack');
    } on PlatformException {
      // no-op
    } on MissingPluginException {
      // no-op
    }
  }

  /// Menit pemakaian tiap package hari ini, sejak tengah malam waktu
  /// perangkat. Kosong (semua 0) kalau izin belum diberikan.
  Future<Map<String, int>> getUsageMinutesToday(List<String> packageNames) async {
    if (packageNames.isEmpty) return {};
    try {
      final raw = await _channel.invokeMethod<Map<Object?, Object?>>(
        'getUsageMinutesToday',
        {'packageNames': packageNames},
      );
      if (raw == null) return {for (final p in packageNames) p: 0};
      return raw.map((key, value) => MapEntry(key as String, value as int));
    } on PlatformException {
      return {for (final p in packageNames) p: 0};
    } on MissingPluginException {
      return {for (final p in packageNames) p: 0};
    }
  }
}
