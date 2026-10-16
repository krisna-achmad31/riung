import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:riung/core/config/kenali_dirimu_config.dart';
import 'package:riung/core/l10n/app_language.dart';
import 'package:riung/features/kenali_dirimu/logic/kenali_content.dart';

/// `KenaliContent.load` jatuh ke teks asli (hanya debugPrint) kalau file
/// terjemahan hilang/rusak. Test ini memastikan fallback itu tidak pernah
/// terjadi di build: setiap tes punya terjemahan valid untuk tiap bahasa.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final language in AppLanguage.values.where((l) => l != AppLanguage.defaultLanguage)) {
    test('setiap tes Kenali Dirimu punya terjemahan ${language.code} yang valid', () async {
      for (final entry in KenaliDirimuConfig.entries) {
        final file = File(entry.translationAsset(language.code));
        expect(file.existsSync(), isTrue, reason: file.path);
        expect(() => jsonDecode(file.readAsStringSync()), returnsNormally, reason: file.path);
        final translated = await KenaliContent.load(entry, language);
        final original = await KenaliContent.load(entry, AppLanguage.defaultLanguage);
        expect(translated.questions.length, original.questions.length, reason: entry.id);
      }
    });
  }
}
