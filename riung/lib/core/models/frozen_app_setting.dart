/// Pengaturan satu aplikasi yang dibekukan — tersimpan lokal
/// (`LocalPrefsStore.frozenApps`), bukan Firestore (murni preferensi
/// perangkat, tidak perlu sinkron lintas perangkat).
class FrozenAppSetting {
  const FrozenAppSetting({
    required this.packageName,
    required this.dailyLimitMinutes,
    required this.enabled,
    this.name,
  });

  factory FrozenAppSetting.fromMap(String packageName, Map<String, dynamic> map) {
    return FrozenAppSetting(
      packageName: packageName,
      dailyLimitMinutes: map[fLimit] as int? ?? 30,
      enabled: map[fEnabled] as bool? ?? false,
      name: map[fName] as String?,
    );
  }

  static const fLimit = 'limit';
  static const fEnabled = 'enabled';
  static const fName = 'name';

  final String packageName;
  final int dailyLimitMinutes;
  final bool enabled;

  /// Nama tampilan aplikasi di luar katalog; null untuk aplikasi katalog.
  final String? name;

  Map<String, dynamic> toMap() => {fLimit: dailyLimitMinutes, fEnabled: enabled, if (name != null) fName: name};

  FrozenAppSetting copyWith({int? dailyLimitMinutes, bool? enabled}) {
    return FrozenAppSetting(
      packageName: packageName,
      dailyLimitMinutes: dailyLimitMinutes ?? this.dailyLimitMinutes,
      enabled: enabled ?? this.enabled,
      name: name,
    );
  }
}
