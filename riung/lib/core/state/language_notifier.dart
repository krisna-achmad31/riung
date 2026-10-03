import 'package:flutter/foundation.dart';

import '../l10n/app_language.dart';
import '../l10n/app_strings.dart';
import '../services/local_prefs_store.dart';

/// Notifier global bahasa app — notifier ke-7 (setelah [AppBekuNotifier]).
///
/// Justifikasi (CLAUDE.md §State management): bahasa dipakai SEMUA layar dan
/// harus membuat seluruh UI ikut berganti seketika tanpa memulai ulang app
/// atau merusak stack navigasi; itu domain lintas layar sungguhan, bukan
/// state satu layar. Pilihan disimpan lewat [LocalPrefsStore] supaya bertahan
/// antar sesi. Widget membacanya lewat `context.s` (lihat `LanguageScope`),
/// yang otomatis rebuild widget pembacanya saat bahasa berubah.
class LanguageNotifier extends ChangeNotifier {
  LanguageNotifier({required LocalPrefsStore prefs})
      : _prefs = prefs,
        _language = AppLanguage.fromCode(prefs.languageCode);

  final LocalPrefsStore _prefs;
  AppLanguage _language;

  AppLanguage get language => _language;

  AppStrings get strings => AppStrings.of(_language);

  Future<void> setLanguage(AppLanguage language) async {
    if (language == _language) return;
    _language = language;
    notifyListeners();
    await _prefs.setLanguageCode(language.code);
  }
}
