import 'package:health/health.dart';

import '../models/sleep_night.dart';

/// Kondisi akses ke data tidur di perangkat.
enum SleepAccess {
  /// Perangkat/Android tidak mendukung Health Connect.
  unsupported,

  /// Aplikasi Health Connect belum terpasang / perlu diperbarui.
  needsInstall,

  /// Tersedia, tetapi izin baca tidur belum diberikan.
  notGranted,

  granted,
}

/// Membaca data tidur dari jam tangan lewat Health Connect (aplikasi jam
/// menulis ke sana). Baca-saja, izin diminta hanya setelah pengguna setuju,
/// dan hasilnya tidak disimpan.
abstract class SleepDataService {
  Future<SleepAccess> access();
  Future<bool> requestAccess();
  Future<List<SleepNight>> readNights({required int days});
  Future<void> openInstall();
  Future<void> revoke();
}

class HealthConnectSleepService implements SleepDataService {
  HealthConnectSleepService({Health? health}) : _health = health ?? Health();

  final Health _health;
  bool _configured = false;

  static const _types = [HealthDataType.SLEEP_SESSION];
  static const _permissions = [HealthDataAccess.READ];

  Future<void> _ensureConfigured() async {
    if (_configured) return;
    await _health.configure();
    _configured = true;
  }

  @override
  Future<SleepAccess> access() async {
    try {
      await _ensureConfigured();
      final status = await _health.getHealthConnectSdkStatus();
      if (status == HealthConnectSdkStatus.sdkUnavailable) return SleepAccess.unsupported;
      if (status != HealthConnectSdkStatus.sdkAvailable) return SleepAccess.needsInstall;
      final granted = await _health.hasPermissions(_types, permissions: _permissions) ?? false;
      return granted ? SleepAccess.granted : SleepAccess.notGranted;
    } catch (_) {
      return SleepAccess.unsupported;
    }
  }

  @override
  Future<bool> requestAccess() async {
    try {
      await _ensureConfigured();
      return await _health.requestAuthorization(_types, permissions: _permissions);
    } catch (_) {
      return false;
    }
  }

  @override
  Future<List<SleepNight>> readNights({required int days}) async {
    try {
      await _ensureConfigured();
      final now = DateTime.now();
      final points = await _health.getHealthDataFromTypes(
        types: _types,
        startTime: now.subtract(Duration(days: days + 1)),
        endTime: now,
      );
      return SleepNight.fromSessions([for (final p in points) (from: p.dateFrom, to: p.dateTo)]);
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<void> openInstall() async {
    try {
      await _ensureConfigured();
      await _health.installHealthConnect();
    } catch (_) {}
  }

  @override
  Future<void> revoke() async {
    try {
      await _ensureConfigured();
      await _health.revokePermissions();
    } catch (_) {}
  }
}
