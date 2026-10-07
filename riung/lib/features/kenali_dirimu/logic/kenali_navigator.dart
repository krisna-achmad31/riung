import 'package:flutter/material.dart';

import '../../../core/config/kenali_dirimu_config.dart';
import '../../../core/models/kenali_result.dart';
import '../../../core/models/kenali_test.dart';
import '../../../core/services/kenali_result_repository.dart';
import '../screens/kenali_hasil_screen.dart';
import '../screens/kenali_intro_screen.dart';
import '../screens/kenali_kesehatan_hasil_screen.dart';
import '../../../core/l10n/l10n.dart';
import 'kenali_content.dart';
import 'kenali_scoring.dart';

/// Rute masuk satu tes: sudah ada hasil → layar hasil, belum → intro.
abstract final class KenaliNavigator {
  static Widget resultScreen(KenaliEntry entry, KenaliTest test, KenaliResult result) => entry.section == KenaliSection.kesehatan
      ? KenaliKesehatanHasilScreen(entry: entry, test: test, result: result)
      : KenaliHasilScreen(entry: entry, test: test, result: result);

  static Future<void> open(BuildContext context, KenaliEntry entry, {bool forceIntro = false}) async {
    final navigator = Navigator.of(context);
    final test = await KenaliContent.load(entry, context.s.language);
    final result = KenaliResultRepository.instance.resultOf(entry.id);
    await navigator.push(
      MaterialPageRoute(
        builder: (_) => result == null || forceIntro ? KenaliIntroScreen(entry: entry, test: test) : resultScreen(entry, test, result),
      ),
    );
  }

  static Future<void> openById(BuildContext context, String id) async {
    final entry = KenaliDirimuConfig.byId(id);
    if (entry != null) await open(context, entry);
  }
}

/// Judul hasil dalam bahasa [test] (null → teks kategori yang tersimpan).
String kenaliResultTitle(KenaliTest? test, KenaliResult result) {
  final outcome = test == null ? null : KenaliScoring.outcomeOf(test, result);
  return outcome?.title ?? kenaliCategoryTitle(result.category);
}

/// Judul kategori tanpa alias dalam kurung ("Kecemasan Sedang").
String kenaliCategoryTitle(String category) {
  final i = category.indexOf('(');
  return (i < 0 ? category : category.substring(0, i)).trim();
}
