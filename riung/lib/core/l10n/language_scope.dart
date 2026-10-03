import 'package:flutter/widgets.dart';

import '../state/language_notifier.dart';
import 'app_strings.dart';

/// Membagikan [LanguageNotifier] ke seluruh widget tree DAN mendaftarkan
/// widget pembacanya sebagai dependen — begitu bahasa berubah, hanya widget
/// yang memanggil `context.s` di `build()` yang rebuild. Navigator tidak
/// dibuat ulang, jadi user tidak terlempar dari layar tempat dia mengganti
/// bahasa.
class LanguageScope extends InheritedNotifier<LanguageNotifier> {
  const LanguageScope({super.key, required LanguageNotifier notifier, required super.child})
      : super(notifier: notifier);

  static LanguageNotifier of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<LanguageScope>();
    assert(scope != null, 'LanguageScope tidak ditemukan di widget tree');
    return scope!.notifier!;
  }
}

extension AppStringsContext on BuildContext {
  /// Teks UI dalam bahasa aktif. Panggil di `build()` (bukan `initState`) supaya
  /// widget ikut rebuild saat bahasa diganti.
  AppStrings get s => LanguageScope.of(this).strings;
}
