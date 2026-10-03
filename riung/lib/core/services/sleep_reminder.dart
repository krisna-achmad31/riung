import 'package:flutter/material.dart' show TimeOfDay;

import '../l10n/strings/notif_strings.dart';
import '../models/sleep_reminder_settings.dart';
import 'local_notification_service.dart';
import 'local_prefs_store.dart';

/// Menjadwalkan (atau membatalkan) pengingat tidur mingguan sesuai
/// [SleepReminderSettings]. Dipanggil dari `main.dart` (app dibuka / bahasa
/// berganti) dan dari layar Pengingat tidur begitu user menyimpan.
abstract final class SleepReminder {
  static Future<void> refresh({
    required LocalPrefsStore prefs,
    required NotifStrings strings,
    required String? userName,
  }) async {
    final settings = prefs.sleepReminder;
    final service = LocalNotificationService.instance;
    if (!settings.enabled || settings.days.isEmpty) {
      await service.cancelTidur();
      return;
    }
    final notify = settings.notifyMinutes;
    await service.scheduleTidur(
      strings: strings,
      userName: userName,
      time: TimeOfDay(hour: notify ~/ 60, minute: notify % 60),
      days: settings.days,
    );
  }
}
