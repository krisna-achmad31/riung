/// Pengaturan pengingat tidur — tersimpan lokal
/// (`LocalPrefsStore.sleepReminder`), murni preferensi perangkat.
class SleepReminderSettings {
  const SleepReminderSettings({
    required this.enabled,
    required this.targetMinutes,
    required this.days,
  });

  factory SleepReminderSettings.fromMap(Map<String, dynamic> map) {
    final rawDays = map[fDays];
    return SleepReminderSettings(
      enabled: map[fEnabled] as bool? ?? false,
      targetMinutes: (map[fTargetMinutes] as num?)?.toInt() ?? defaults.targetMinutes,
      days: rawDays is List ? {for (final d in rawDays) if (d is num && d >= 0 && d <= 6) d.toInt()} : defaults.days,
    );
  }

  static const fEnabled = 'enabled';
  static const fTargetMinutes = 'target_minutes';
  static const fDays = 'days';

  /// Tampilan awal layar (persis desain: 22:30, Senin–Jumat). `enabled`
  /// false karena belum ada yang dijadwalkan sebelum user menyimpan.
  static const defaults = SleepReminderSettings(enabled: false, targetMinutes: 22 * 60 + 30, days: {0, 1, 2, 3, 4});

  /// Pengingat dikirim sekian menit sebelum target mulai tidur.
  static const leadMinutes = 30;

  final bool enabled;

  /// Target mulai tidur, menit sejak 00:00.
  final int targetMinutes;

  /// Hari aktif, 0 = Senin … 6 = Minggu.
  final Set<int> days;

  int get targetHour => targetMinutes ~/ 60;
  int get targetMinute => targetMinutes % 60;

  /// Menit sejak 00:00 saat notifikasi dikirim ([leadMinutes] sebelum target).
  int get notifyMinutes => (targetMinutes - leadMinutes + 1440) % 1440;

  Map<String, dynamic> toMap() => {
        fEnabled: enabled,
        fTargetMinutes: targetMinutes,
        fDays: (days.toList()..sort()),
      };

  SleepReminderSettings copyWith({bool? enabled, int? targetMinutes, Set<int>? days}) {
    return SleepReminderSettings(
      enabled: enabled ?? this.enabled,
      targetMinutes: targetMinutes ?? this.targetMinutes,
      days: days ?? this.days,
    );
  }
}
