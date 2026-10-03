import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:riung/core/dev/component_gallery_screen.dart';
import 'package:riung/core/l10n/l10n.dart';
import 'package:riung/core/state/state.dart';
import 'package:riung/core/services/services.dart';
import 'package:riung/core/theme/theme.dart';
import 'package:riung/main.dart';

/// Galeri dev memakai komponen bersama yang membaca `context.s`, jadi butuh
/// [LanguageScope] di atasnya seperti di app sungguhan.
Future<Widget> _galleryApp() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await LocalPrefsStore.init();
  return LanguageScope(
    notifier: LanguageNotifier(prefs: prefs),
    child: MaterialApp(theme: AppTheme.dark, home: const ComponentGalleryScreen()),
  );
}

void main() {
  testWidgets('RiungApp boot ke Splash lalu auto-navigate tanpa error', (WidgetTester tester) async {
    // shared_preferences butuh mock store di lingkungan test — tanpa ini
    // getInstance() menunggu platform channel yang tidak ada di flutter test.
    SharedPreferences.setMockInitialValues({});
    final prefs = await LocalPrefsStore.init();
    // Suntik Stub/Local, bukan Firebase — test ini tidak memanggil
    // `Firebase.initializeApp()` sungguhan (lihat RiungApp.authService dkk).
    final userRepository = LocalUserRepository(
      prefs: prefs,
      db: LocalDatabaseService(),
      crypto: JournalCryptoService(),
    );
    await tester.pumpWidget(RiungApp(
      prefs: prefs,
      remoteConfig: RemoteConfigService(),
      authService: StubAuthService(),
      userRepository: userRepository,
      contentRepository: StubContentRepository(),
      walletFunctions: LocalWalletFunctionsService(prefs: prefs, userRepository: userRepository),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Riung'), findsOneWidget);

    // Splash menunggu ~2 detik (animasi dot berulang tanpa henti, jadi
    // sengaja pakai pump(duration) — bukan pumpAndSettle yang tidak akan
    // pernah "diam" selama animasi itu masih berjalan) lalu auto-navigate
    // ke Onboarding (user dummy belum onboardingDone).
    await tester.pump(const Duration(seconds: 3));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(find.text('Riung'), findsNothing);
    expect(find.text('Mulai kenalan (2 menit)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Galeri komponen render tanpa error', (WidgetTester tester) async {
    await tester.pumpWidget(await _galleryApp());
    await tester.pumpAndSettle();

    expect(find.text('Galeri Komponen Riung'), findsOneWidget);
    expect(find.text('01 · Warna'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Mulai sekarang'), 300);
    expect(find.text('Mulai sekarang'), findsOneWidget);
  });

  testWidgets('Galeri monster tidak overflow di layar 360dp', (WidgetTester tester) async {
    // Lebar minimum yang wajib lolos per CLAUDE.md ("lolos di layar 360dp").
    tester.view.physicalSize = const Size(360, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(await _galleryApp());
    await tester.pumpAndSettle();

    // Gulir sampai kartu Si Hakim (kartu monster terakhir sebelum §07) —
    // ini yang paling rawan overflow karena bossScale 1.4×.
    await tester.scrollUntilVisible(find.text('Si Hakim'), 400);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
