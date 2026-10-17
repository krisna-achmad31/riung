// Audit kelayakan 2026-10-17 — H-05: hapus akun tidak membatalkan langganan
// Play. Premium aktif → peringatan + tombol "Kelola di Google Play" sebelum
// tombol hapus; non-premium → tidak ada. Tombol hapus tetap tersedia.
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riung/core/l10n/language_scope.dart';
import 'package:riung/core/services/services.dart';
import 'package:riung/core/state/state.dart';
import 'package:riung/features/profil/screens/hapus_akun_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pump(WidgetTester tester, {required bool premium}) async {
  tester.view.physicalSize = const Size(360, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  SharedPreferences.setMockInitialValues({});
  FlutterSecureStorage.setMockInitialValues({});
  final prefs = await LocalPrefsStore.init();
  final repo = LocalUserRepository(prefs: prefs, db: LocalDatabaseService(), crypto: JournalCryptoService());
  final wallet = LocalWalletFunctionsService(prefs: prefs, userRepository: repo);
  final auth = AuthNotifier(StubAuthService(), userRepository: repo);
  await tester.runAsync(() async {
    await auth.ensureProfileLoaded();
    // Selalu tulis eksplisit: prefs bisa terbawa antar test di proses yang sama.
    await auth.updateProfile((p) => p.copyWith(
          premiumActive: premium,
          premiumPlan: 'premium_monthly',
          premiumRenewsAt: DateTime.now().add(const Duration(days: 20)),
        ));
  });
  final language = LanguageNotifier(prefs: prefs);
  await tester.pumpWidget(LanguageScope(notifier: language, child: AppScope(
    auth: auth,
    wallet: WalletNotifier(userRepository: repo, walletFunctions: wallet, prefs: prefs),
    streak: StreakNotifier(userRepository: repo),
    monsterProgress: MonsterProgressNotifier(userRepository: repo, walletFunctions: wallet),
    session: SessionNotifier(),
    appBeku: AppBekuNotifier(prefs: prefs),
    language: language,
    contentRepository: StubContentRepository(),
    userRepository: repo,
    pinService: JurnalPinService(),
    prefs: prefs,
    remoteConfig: RemoteConfigService(),
    billing: BillingService(
      walletFunctions: wallet,
      userRepository: repo,
      currentUid: () => auth.uid ?? '',
      analytics: AnalyticsService(),
      isAnonymous: () => false,
    ),
    analytics: AnalyticsService(),
    child: const MaterialApp(home: HapusAkunScreen()),
  )));
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('H-05: premium aktif → peringatan + tombol Kelola di Google Play sebelum tombol hapus', (tester) async {
    await _pump(tester, premium: true);

    expect(find.text('Langganan Premium-mu masih aktif'), findsOneWidget);
    final kelola = find.text('Kelola di Google Play');
    expect(kelola, findsOneWidget);
    final hapus = find.text('Ya, hapus akunku');
    expect(hapus, findsOneWidget);
    expect(tester.getTopLeft(kelola).dy, lessThan(tester.getTopLeft(hapus).dy));
  });

  testWidgets('H-05: non-premium → tanpa peringatan langganan', (tester) async {
    await _pump(tester, premium: false);

    expect(find.text('Langganan Premium-mu masih aktif'), findsNothing);
    expect(find.text('Kelola di Google Play'), findsNothing);
    expect(find.text('Ya, hapus akunku'), findsOneWidget);
  });
}
