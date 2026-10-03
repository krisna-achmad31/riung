import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:riung/core/l10n/language_scope.dart';
import 'package:riung/core/services/services.dart';
import 'package:riung/core/state/language_notifier.dart';
import 'package:riung/core/theme/theme.dart';
import 'package:riung/features/laporan/logic/report_engine.dart';
import 'package:riung/features/laporan/logic/report_models.dart';
import 'package:riung/features/laporan/widgets/report_body.dart';

/// Layar laporan: keadaan kosong, lengkap (non-Premium vs Premium), dan
/// dukungan — semuanya di lebar 360dp tanpa overflow.
void main() {
  final now = DateTime(2026, 9, 27);
  ReportEntry c(int daysAgo, String mood, {List<String> factors = const []}) =>
      ReportEntry(date: now.subtract(Duration(days: daysAgo)), mood: mood, factors: factors);

  Future<void> pumpBody(WidgetTester tester, Report report, {required bool premium}) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await LocalPrefsStore.init();
    tester.view.physicalSize = const Size(360, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(LanguageScope(
      notifier: LanguageNotifier(prefs: prefs),
      child: MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(body: SingleChildScrollView(padding: const EdgeInsets.all(20), child: ReportBody(report: report, premium: premium))),
      ),
    ));
  }

  final full = ReportEngine.build([
    for (var i = 0; i < 7; i++) c(i, i < 3 ? 'agak_berat' : 'cukup_baik', factors: i < 3 ? ['kurang_tidur', 'kerjaan'] : ['kerjaan']),
    for (var i = 7; i < 12; i++) c(i, 'datar'),
  ], now: now);

  testWidgets('data kurang → ajakan lembut, tanpa angka', (tester) async {
    await pumpBody(tester, ReportEngine.build([c(0, 'datar')], now: now), premium: false);
    expect(find.text('Laporanmu belum cukup terisi'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('laporan lengkap non-Premium: insight dasar + kunci Premium', (tester) async {
    await pumpBody(tester, full, premium: false);
    expect(find.text('Kamu hadir 7 dari 7 hari'), findsOneWidget);
    expect(find.text('Pola yang lebih dalam'), findsOneWidget, reason: 'kunci Premium tampil');
    expect(find.textContaining('cenderung lebih rendah'), findsNothing, reason: 'pola faktor tidak bocor ke non-Premium');
    expect(tester.takeException(), isNull);
  });

  testWidgets('laporan lengkap Premium: pola faktor tampil, tanpa kunci', (tester) async {
    await pumpBody(tester, full, premium: true);
    expect(find.text('Pola yang lebih dalam'), findsNothing);
    expect(find.textContaining('cenderung'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('hari berat berturut-turut → kartu dukungan', (tester) async {
    final r = ReportEngine.build([c(0, 'berat'), c(1, 'agak_berat'), c(2, 'berat'), c(3, 'datar')], now: now);
    await pumpBody(tester, r, premium: false);
    expect(find.text('Kamu nggak sendirian'), findsOneWidget);
    expect(find.text('Lihat bantuan'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
