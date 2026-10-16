import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:riung/core/l10n/language_scope.dart';
import 'package:riung/core/services/services.dart';
import 'package:riung/core/state/language_notifier.dart';
import 'package:riung/core/theme/theme.dart';
import 'package:riung/core/widgets/koin_chip.dart';
import 'package:riung/core/widgets/riung_button.dart';
import 'package:riung/core/widgets/streak_chip.dart';
import 'package:riung/core/widgets/tahukah_kamu_card.dart';
import 'package:riung/core/widgets/tiket_chip.dart';
import 'package:riung/features/jurnal/widgets/pin_pad.dart';

Future<Widget> wrapWithLanguage(Widget child) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await LocalPrefsStore.init();
  return LanguageScope(
    notifier: LanguageNotifier(prefs: prefs),
    child: MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

void main() {
  testWidgets('PinDots render jumlah titik terisi dan kosong dengan benar', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: const Scaffold(
        body: Center(
          child: PinDots(length: 6, filled: 3),
        ),
      ),
    ));

    expect(find.byType(PinDots), findsOneWidget);
    expect(find.byType(AnimatedContainer), findsNWidgets(6));
  });

  testWidgets('PinNumpad merespons tap digit dan backspace', (tester) async {
    final pressedDigits = <String>[];
    var backspaceCount = 0;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: PinNumpad(
            onDigit: (d) => pressedDigits.add(d),
            onBackspace: () => backspaceCount++,
          ),
        ),
      ),
    ));

    expect(find.text('1'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
    expect(find.byIcon(Icons.backspace_outlined), findsOneWidget);

    await tester.tap(find.text('1'));
    await tester.tap(find.text('9'));
    await tester.tap(find.text('0'));
    await tester.tap(find.byIcon(Icons.backspace_outlined));

    expect(pressedDigits, ['1', '9', '0']);
    expect(backspaceCount, 1);
  });

  testWidgets('RiungButton render label dan aksi tap', (tester) async {
    var tapped = false;

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: Center(
          child: RiungButton(
            label: 'Mulai Sekarang',
            onPressed: () => tapped = true,
          ),
        ),
      ),
    ));

    expect(find.text('Mulai Sekarang'), findsOneWidget);
    await tester.tap(find.text('Mulai Sekarang'));
    expect(tapped, isTrue);
  });

  testWidgets('RiungButton dalam keadaan nonaktif (onPressed null) tidak memicu aksi', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: const Scaffold(
        body: Center(
          child: RiungButton(
            label: 'Lanjut',
            onPressed: null,
          ),
        ),
      ),
    ));

    expect(find.text('Lanjut'), findsOneWidget);
  });

  testWidgets('KoinChip, StreakChip, dan TiketChip render nilai dengan benar', (tester) async {
    final app = await wrapWithLanguage(
      const Column(
        children: [
          KoinChip(balance: 250),
          StreakChip(days: 7, compact: false),
          TiketChip(count: 3),
        ],
      ),
    );

    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    expect(find.text('250'), findsOneWidget);
    expect(find.textContaining('7'), findsOneWidget);
    expect(find.textContaining('3'), findsOneWidget);
  });

  testWidgets('TahukahKamuCard render fakta riset dan sumber', (tester) async {
    final app = await wrapWithLanguage(
      const TahukahKamuCard(
        text: 'Napas 4-7-8 mengaktifkan sistem saraf parasimpatis.',
        source: 'Dr. Andrew Weil, Harvard Health',
      ),
    );

    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    expect(find.textContaining('TAHUKAH KAMU'), findsOneWidget);
    expect(find.text('Napas 4-7-8 mengaktifkan sistem saraf parasimpatis.'), findsOneWidget);
    expect(find.text('Dr. Andrew Weil, Harvard Health'), findsOneWidget);
  });
}
