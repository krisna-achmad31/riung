import 'package:flutter/material.dart' show TimeOfDay;

import '../l10n/strings/afirmasi_strings.dart';
import '../l10n/strings/notif_strings.dart';
import 'content_repository.dart';
import 'local_notification_service.dart';
import 'local_prefs_store.dart';
import 'user_repository.dart';

/// Menjadwalkan (atau membatalkan) notifikasi afirmasi harian sesuai
/// pengaturan user. Sumber kebenaran ON/OFF = toggle "Afirmasi harian" di
/// `NotifikasiScreen` (`notifSettingsJson['afirmasi_harian']`); jamnya dari
/// `LocalPrefsStore.afirmasiReminderTime` (diatur di layar Pengingat
/// afirmasi). Dipanggil dari `main.dart` (app dibuka / bahasa berganti) dan
/// dari kedua layar pengaturan itu begitu user menyimpan perubahan.
abstract final class AfirmasiReminder {
  static Future<void> refresh({
    required LocalPrefsStore prefs,
    required ContentRepository content,
    required UserRepository users,
    required String? uid,
    required NotifStrings strings,
    required AfirmasiStrings afirmasi,
  }) async {
    final service = LocalNotificationService.instance;
    final enabled = prefs.notifSettingsJson['afirmasi_harian'] as bool? ?? true;
    if (!enabled) {
      await service.cancel(LocalNotificationService.idAfirmasiHarian);
      return;
    }

    final text = await _pickText(content: content, users: users, uid: uid, afirmasi: afirmasi);
    if (text == null) {
      await service.cancel(LocalNotificationService.idAfirmasiHarian);
      return;
    }
    await service.scheduleAfirmasiHarian(strings: strings, time: parseTime(prefs.afirmasiReminderTime), text: text);
  }

  /// Format "HH:mm" → [TimeOfDay]; nilai rusak jatuh ke 07:00.
  static TimeOfDay parseTime(String value) {
    final parts = value.split(':');
    final hour = parts.length == 2 ? int.tryParse(parts[0]) : null;
    final minute = parts.length == 2 ? int.tryParse(parts[1]) : null;
    if (hour == null || minute == null || hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      return const TimeOfDay(hour: 7, minute: 0);
    }
    return TimeOfDay(hour: hour, minute: minute);
  }

  /// Pilih satu kalimat untuk hari ini. Kalimat buatan sendiri & favorit
  /// dimasukkan dua kali ke kolam supaya lebih sering muncul ("Kalimat
  /// buatanmu sendiri muncul lebih sering"); pilihan berganti tiap hari
  /// (indeks = hari ke-berapa dalam tahun), bukan acak tiap kali dijadwal.
  static Future<String?> _pickText({
    required ContentRepository content,
    required UserRepository users,
    required String? uid,
    required AfirmasiStrings afirmasi,
  }) async {
    final seeded = await content.getAffirmations();
    final custom = uid == null ? const [] : await users.getCustomAffirmations(uid);
    final favoriteIds = uid == null ? const <String>{} : await users.getFavoriteAffirmationIds(uid);
    final pool = [
      ...seeded,
      ...seeded.where((a) => favoriteIds.contains(a.id)),
      ...custom,
      ...custom,
    ];
    if (pool.isEmpty) return null;
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year)).inDays;
    return afirmasi.textOf(pool[dayOfYear % pool.length]);
  }
}
