import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../../../core/config/kenali_dirimu_config.dart';
import '../../../core/l10n/app_language.dart';
import '../../../core/models/kenali_test.dart';

/// Memuat isi tes dari `assets/data/know_yourself/` (bundel, offline) dan
/// meng-cache-nya per bahasa selama app hidup. JSON utama berbahasa
/// Indonesia; bahasa lain menimpa TEKS-nya dari `<kode bahasa>/<file>`
/// (lihat [KenaliTest.withTranslation]) — angka skor selalu dari JSON utama.
abstract final class KenaliContent {
  static final Map<String, KenaliTest> _cache = {};

  static String _key(String id, AppLanguage language) => '${language.code}/$id';

  static KenaliTest? cached(String id, AppLanguage language) => _cache[_key(id, language)];

  static Future<KenaliTest> load(KenaliEntry entry, AppLanguage language) async {
    final key = _key(entry.id, language);
    final hit = _cache[key];
    if (hit != null) return hit;
    var test = KenaliTest.fromMap(jsonDecode(await rootBundle.loadString(entry.asset)) as Map<String, dynamic>);
    if (language != AppLanguage.defaultLanguage) {
      try {
        final raw = await rootBundle.loadString(entry.translationAsset(language.code));
        test = test.withTranslation(jsonDecode(raw) as Map<String, dynamic>);
      } catch (e) {
        // Terjemahan belum ada: tampilkan teks asli daripada gagal total.
        debugPrint('KenaliContent: terjemahan ${language.code} untuk ${entry.id} tidak ada ($e)');
      }
    }
    _cache[key] = test;
    return test;
  }

  /// Semua tes di katalog (untuk jumlah soal & menit di hub).
  static Future<Map<String, KenaliTest>> loadAll(AppLanguage language) async {
    final tests = await Future.wait(KenaliDirimuConfig.entries.map((e) => load(e, language)));
    return {for (final t in tests) t.id: t};
  }
}
