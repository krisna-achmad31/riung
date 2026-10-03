import 'package:flutter/material.dart';

/// Global navigator key — dibutuhkan buat mendorong layar dari luar widget
/// tree (mis. saat notifikasi lokal ditap sementara app di background,
/// lihat `LocalNotificationService` & wiring di `main.dart`), karena
/// callback tap notifikasi tidak punya `BuildContext` sendiri.
class AppNavigator {
  AppNavigator._();
  static final key = GlobalKey<NavigatorState>();
}
