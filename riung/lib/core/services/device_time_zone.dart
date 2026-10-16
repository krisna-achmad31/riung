import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Zona waktu IANA perangkat, tanpa package tambahan: dicocokkan dari
/// offset UTC (+ singkatan zona) yang dilaporkan sistem. Tiga zona
/// Indonesia (WIB/WITA/WIT) diprioritaskan; di luar itu dicari lokasi IANA
/// yang offset & singkatannya sama, lalu jatuh ke `Etc/GMT±N`.
///
/// Dipakai notifikasi lokal (jam pengingat ikut jam HP) dan sebagai
/// fallback tanggal harian bila profil server belum punya `tz`.
class DeviceTimeZone {
  DeviceTimeZone._();

  static bool _ready = false;

  static void ensureInitialized() {
    if (_ready) return;
    tz_data.initializeTimeZones();
    _ready = true;
  }

  static const _indonesia = {
    7 * 60: 'Asia/Jakarta',
    8 * 60: 'Asia/Makassar',
    9 * 60: 'Asia/Jayapura',
  };

  /// [now] bisa disuntik untuk test.
  static String detect({DateTime? now}) {
    ensureInitialized();
    final local = now ?? DateTime.now();
    final offsetMinutes = local.timeZoneOffset.inMinutes;
    final indonesian = _indonesia[offsetMinutes];
    if (indonesian != null) return indonesian;

    final utcMillis = local.toUtc().millisecondsSinceEpoch;
    String? byOffset;
    for (final entry in tz.timeZoneDatabase.locations.entries) {
      final zone = entry.value.timeZone(utcMillis);
      if (zone.offset.inMinutes != offsetMinutes) continue;
      if (zone.abbreviation == local.timeZoneName) return entry.key;
      byOffset ??= entry.key;
    }
    if (byOffset != null) return byOffset;
    if (offsetMinutes % 60 == 0) {
      final hours = offsetMinutes ~/ 60;
      // Tanda Etc/GMT terbalik: Etc/GMT-7 = UTC+7.
      return hours == 0 ? 'UTC' : 'Etc/GMT${hours > 0 ? '-' : '+'}${hours.abs()}';
    }
    return 'UTC';
  }

  static tz.Location location({DateTime? now}) {
    ensureInitialized();
    return tz.getLocation(detect(now: now));
  }
}
