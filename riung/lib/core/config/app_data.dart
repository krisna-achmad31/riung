import 'package:flutter/foundation.dart';

enum AppMode { live, dev }

/// Mode dan alamat backend. Pilih dev saat build:
/// `--dart-define=RIUNG_APP_MODE=dev`. Build rilis selalu live.
abstract final class AppData {
  static const baseUrlProd = 'https://riung.e55techlab.com';

  /// Backend lokal lewat emulator Android. HP fisik memakai
  /// `--dart-define=RIUNG_API_BASE_URL=http://<ip-laptop>:8080`.
  static const baseUrlDev = 'http://10.0.2.2:8080';

  static const _modeOverride = String.fromEnvironment('RIUNG_APP_MODE');
  static const _baseUrlOverride = String.fromEnvironment('RIUNG_API_BASE_URL');

  static AppMode get appMode => resolveMode(modeOverride: _modeOverride, isRelease: kReleaseMode);

  static String get baseUrl {
    if (_baseUrlOverride.isNotEmpty) return _baseUrlOverride;
    return appMode == AppMode.live ? baseUrlProd : baseUrlDev;
  }

  static AppMode resolveMode({required String modeOverride, required bool isRelease}) =>
      !isRelease && modeOverride == 'dev' ? AppMode.dev : AppMode.live;
}
