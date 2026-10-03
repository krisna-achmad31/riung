/// Pengaturan satu aplikasi yang dibekukan — tersimpan lokal
/// (`LocalPrefsStore.frozenApps`), bukan Firestore (murni preferensi
/// perangkat, tidak perlu sinkron lintas perangkat).
class FrozenAppSetting {
  const FrozenAppSetting({
    required this.packageName,
    required this.dailyLimitMinutes,
    required this.enabled,
  });

  factory FrozenAppSetting.fromMap(String packageName, Map<String, dynamic> map) {
    return FrozenAppSetting(
      packageName: packageName,
      dailyLimitMinutes: map[fLimit] as int? ?? 30,
      enabled: map[fEnabled] as bool? ?? false,
    );
  }

  static const fLimit = 'limit';
  static const fEnabled = 'enabled';

  final String packageName;
  final int dailyLimitMinutes;
  final bool enabled;

  Map<String, dynamic> toMap() => {fLimit: dailyLimitMinutes, fEnabled: enabled};

  FrozenAppSetting copyWith({int? dailyLimitMinutes, bool? enabled}) {
    return FrozenAppSetting(
      packageName: packageName,
      dailyLimitMinutes: dailyLimitMinutes ?? this.dailyLimitMinutes,
      enabled: enabled ?? this.enabled,
    );
  }
}
