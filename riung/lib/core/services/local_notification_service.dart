import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../config/economy.dart';
import '../l10n/strings/notif_strings.dart';

/// Wrapper `flutter_local_notifications` + `timezone` — satu-satunya
/// tempat yang tahu soal channel Android & id notifikasi lokal Riung.
/// Singleton (pola sama seperti [MonsterAnchorRegistry]), diinisialisasi
/// sekali di `main.dart` sebelum `runApp`.
///
/// Zona waktu di-hardcode ke Asia/Jakarta (WIB) alih-alih deteksi otomatis
/// (butuh package tambahan `flutter_timezone`) — app ini Indonesia-only
/// (copy Bahasa Indonesia, harga IDR, lihat CLAUDE.md), jadi asumsi ini aman.
class LocalNotificationService {
  LocalNotificationService._();
  static final LocalNotificationService instance = LocalNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const _channelAppBeku = AndroidNotificationDetails(
    'appbeku',
    'Aplikasi Beku',
    channelDescription: 'Pengingat saat batas scroll harianmu tercapai.',
    importance: Importance.high,
    priority: Priority.high,
  );

  static const _channelPengingat = AndroidNotificationDetails(
    'riung_pengingat',
    'Pengingat harian',
    channelDescription: 'Check-in pagi, misi harian, dan pengingat streak.',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
  );

  static const idAppBekuBase = 2000;
  static const idCheckinPagi = 101;
  static const idMisiHarian = 102;
  static const idStreakSaver = 103;
  static const idAfirmasiHarian = 104;

  /// Pengingat tidur: satu id per hari (Senin = base + 0 … Minggu = base + 6).
  static const idTidurBase = 110;

  /// Inisialisasi plugin + channel Android. Kembalikan payload notifikasi
  /// yang menyalakan app dari kondisi mati total (`getNotificationAppLaunchDetails`)
  /// kalau ada — dipakai `main.dart` buat rute cold-start.
  Future<String?> init({required void Function(String? payload) onTap}) async {
    if (_initialized) return null;
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));

    // Nama mipmap ikut `flutter_launcher_icons` config (pubspec.yaml
    // `flutter_launcher_icons.android: "launcher_icon"`) — BUKAN
    // @mipmap/ic_launcher default Flutter, yang sudah tidak ada sejak
    // ikon di-generate ulang (M7 Task 1).
    const androidInit = AndroidInitializationSettings('@mipmap/launcher_icon');
    const initSettings = InitializationSettings(android: androidInit);
    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (response) => onTap(response.payload),
    );

    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        'appbeku',
        'Aplikasi Beku',
        description: 'Pengingat saat batas scroll harianmu tercapai.',
        importance: Importance.high,
      ),
    );
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        'riung_pengingat',
        'Pengingat harian',
        description: 'Check-in pagi, misi harian, dan pengingat streak.',
      ),
    );

    _initialized = true;

    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    return launchDetails?.didNotificationLaunchApp == true ? launchDetails?.notificationResponse?.payload : null;
  }

  /// AppBeku (Fix 2) — sekali tembak saat resume-check mendeteksi limit
  /// baru saja tercapai (lihat `RootShellScreen._cekBatasAppBeku`).
  Future<void> showAppBekuLimitReached({required String packageName, required NotifStrings strings}) async {
    if (!_initialized) return;
    await _plugin.show(
      id: idAppBekuBase + packageName.hashCode.remainder(1000),
      title: strings.appBekuTitle,
      body: strings.appBekuBody,
      notificationDetails: const NotificationDetails(android: _channelAppBeku),
      payload: 'appbeku:$packageName',
    );
  }

  Future<void> scheduleCheckinPagi({required NotifStrings strings}) => _scheduleDaily(
        id: idCheckinPagi,
        title: strings.checkinTitle,
        body: strings.checkinBody(EconomyEarn.checkinHarian),
        time: const TimeOfDay(hour: 7, minute: 0),
      );

  Future<void> scheduleMisiHarian({required NotifStrings strings, required String monsterName}) => _scheduleDaily(
        id: idMisiHarian,
        title: strings.missionTitle,
        body: strings.missionBody(3, monsterName),
        time: const TimeOfDay(hour: 9, minute: 0),
      );

  Future<void> scheduleStreakSaver({required NotifStrings strings, required int streak}) => _scheduleDaily(
        id: idStreakSaver,
        title: strings.streakTitle,
        body: strings.streakBody(streak),
        time: const TimeOfDay(hour: 20, minute: 0),
      );

  /// Afirmasi harian — jam & kalimat ditentukan pemanggil (lihat
  /// `AfirmasiReminder`). Menjadwal ulang dengan id yang sama otomatis
  /// menimpa jadwal lama.
  Future<void> scheduleAfirmasiHarian({
    required NotifStrings strings,
    required TimeOfDay time,
    required String text,
  }) =>
      _scheduleDaily(id: idAfirmasiHarian, title: strings.affirmationTitle, body: text, time: time);

  /// Pengingat tidur mingguan — [days] 0 = Senin … 6 = Minggu. Menjadwal
  /// ulang menimpa jadwal lama; hari yang tidak dipilih dibatalkan.
  Future<void> scheduleTidur({
    required NotifStrings strings,
    required String? userName,
    required TimeOfDay time,
    required Set<int> days,
  }) async {
    if (!_initialized) return;
    for (var d = 0; d < 7; d++) {
      if (!days.contains(d)) {
        await _plugin.cancel(id: idTidurBase + d);
        continue;
      }
      await _plugin.zonedSchedule(
        id: idTidurBase + d,
        title: strings.sleepTitle,
        body: strings.sleepBody(userName),
        scheduledDate: _nextInstanceOfWeekday(DateTime.monday + d, time),
        notificationDetails: const NotificationDetails(android: _channelPengingat),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }
  }

  Future<void> cancelTidur() async {
    if (!_initialized) return;
    for (var d = 0; d < 7; d++) {
      await _plugin.cancel(id: idTidurBase + d);
    }
  }

  tz.TZDateTime _nextInstanceOfWeekday(int weekday, TimeOfDay time) {
    var scheduled = _nextInstanceOfTime(time);
    while (scheduled.weekday != weekday) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  /// Cancel ketiga pengingat harian sekaligus — dipanggil begitu user
  /// check-in hari itu (lihat orkestrasi di `main.dart`).
  Future<void> cancelDailyReminders() async {
    if (!_initialized) return;
    await _plugin.cancel(id: idCheckinPagi);
    await _plugin.cancel(id: idMisiHarian);
    await _plugin.cancel(id: idStreakSaver);
  }

  Future<void> cancel(int id) async {
    if (!_initialized) return;
    await _plugin.cancel(id: id);
  }

  /// No-op kalau [init] belum pernah dipanggil (mis. widget test yang
  /// mem-pump `RiungApp` langsung tanpa lewat `main()`, atau `init()` yang
  /// gagal) — notifikasi bersifat best-effort, jangan sampai bikin app
  /// crash cuma karena timezone/plugin belum siap.
  Future<void> _scheduleDaily({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
  }) async {
    if (!_initialized) return;
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: _nextInstanceOfTime(time),
      notificationDetails: const NotificationDetails(android: _channelPengingat),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  tz.TZDateTime _nextInstanceOfTime(TimeOfDay time) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, time.hour, time.minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
