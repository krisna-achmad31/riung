import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:riung/core/config/appbeku_catalog.dart';
import 'package:riung/core/config/economy.dart';
import 'package:riung/core/services/services.dart';
import 'package:riung/core/state/appbeku_notifier.dart';
import 'package:riung/core/state/wallet_notifier.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppBekuCatalog', () {
    test('Katalog aplikasi beku memiliki entri utama yang valid', () {
      expect(AppBekuCatalog.instagram.packageName, 'com.instagram.android');
      expect(AppBekuCatalog.tiktok.packageName, 'com.zhiliaoapp.musically');
      expect(AppBekuCatalog.youtube.packageName, 'com.google.android.youtube');
      expect(AppBekuCatalog.x.packageName, 'com.twitter.android');
      expect(AppBekuCatalog.mobileLegends.packageName, 'com.mobile.legends');
      expect(AppBekuCatalog.whatsapp.packageName, 'com.whatsapp');

      expect(AppBekuCatalog.semua.length, 5);
      expect(AppBekuCatalog.sosmed.length, 4);

      for (final app in AppBekuCatalog.semua) {
        expect(app.packageName, isNotEmpty);
        expect(app.name, isNotEmpty);
        expect(app.tile, isNotEmpty);
        expect(app.tileColors, isNotEmpty);
      }

      expect(AppBekuCatalog.byPackage('com.instagram.android'), isNotNull);
      expect(AppBekuCatalog.byPackage('com.unknown.app'), isNull);
    });

    test('Aturan etis Buka Waktu Scroll (EconomyScroll)', () {
      expect(EconomyScroll.unlock10Menit, 15);
      expect(EconomyScroll.unlock20Menit, 25);
      expect(EconomyScroll.unlock30Menit, 35);
      expect(EconomyScroll.unlock60Menit, 60);
      expect(EconomyScroll.bundleSantai, 35);
      expect(EconomyScroll.bundleSosmed, 75);

      // Pengaman etis
      expect(EconomyScroll.maxPaidUnlocksPerDay, 3);
      expect(EconomyScroll.escalationPerUnlock, 10);
      expect(EconomyScroll.unlockCooldownSeconds, 60);
    });
  });

  group('AppBekuNotifier', () {
    late LocalPrefsStore prefs;
    late LocalUserRepository userRepo;
    late LocalWalletFunctionsService walletFunctions;
    late WalletNotifier wallet;
    late AppBekuNotifier appBeku;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await LocalPrefsStore.init();
      await prefs.setCoins(0);
      await prefs.setLifetimeEarned(0);
      await prefs.setLifetimeSpent(0);
      await prefs.setPurchasedCoinsReserve(0);
      await prefs.setFrozenAppsJson({});
      await prefs.setAppBekuDailyJson({});

      userRepo = LocalUserRepository(
        prefs: prefs,
        db: LocalDatabaseService(),
        crypto: JournalCryptoService(),
      );
      walletFunctions = LocalWalletFunctionsService(prefs: prefs, userRepository: userRepo);
      wallet = WalletNotifier(
        userRepository: userRepo,
        walletFunctions: walletFunctions,
        prefs: prefs,
      );
      await wallet.load('user_appbeku_test');

      appBeku = AppBekuNotifier(prefs: prefs);
      await appBeku.load();
    });

    test('Konfigurasi batas waktu & penambahan aplikasi beku', () async {
      expect(appBeku.frozenApps, isEmpty);
      expect(appBeku.enabledFrozenApps, isEmpty);

      await appBeku.setFrozenApp(
        AppBekuCatalog.instagram,
        limitMinutes: 30,
        enabled: true,
      );

      expect(appBeku.frozenApps.length, 1);
      expect(appBeku.enabledFrozenApps.length, 1);
      expect(appBeku.effectiveLimitOf(AppBekuCatalog.instagram.packageName), 30);
    });

    test('Pernapasan dicatat (recordBreath)', () async {
      expect(appBeku.breathTakenToday, 0);
      await appBeku.recordBreath();
      expect(appBeku.breathTakenToday, 1);
      await appBeku.recordBreath();
      expect(appBeku.breathTakenToday, 2);
    });

    test('Kenaikan harga bertingkat (effectiveUnlockPrice)', () {
      expect(appBeku.paidUnlocksToday, 0);
      expect(appBeku.effectiveUnlockPrice(15), 15);
    });

    test('Pengaman etis: unlockMinutes gagal jika koin latihan kurang', () async {
      // Saldo koin beli: 100, koin latihan: 0
      await wallet.earn(amount: 100, reason: 'beli');
      await wallet.recordPurchasedCoins(100);
      expect(wallet.earnedCoins, 0);

      final res = await appBeku.unlockMinutes(
        wallet: wallet,
        packageName: AppBekuCatalog.instagram.packageName,
        minutes: 10,
        price: 15,
      );
      expect(res, UnlockResult.notEnoughEarnedCoins);
    });

    test('Pengaman etis: unlockMinutes berhasil dengan koin latihan dan berhenti di maks 3x/hari', () async {
      // Beri user 500 koin hasil latihan
      await wallet.earn(amount: 500, reason: 'latihan');
      expect(wallet.earnedCoins, 500);

      await appBeku.setFrozenApp(
        AppBekuCatalog.instagram,
        limitMinutes: 30,
        enabled: true,
      );

      // Unlock #1: biaya dasar 15 (0 kenaikan)
      expect(appBeku.effectiveUnlockPrice(15), 15);
      final r1 = await appBeku.unlockMinutes(
        wallet: wallet,
        packageName: AppBekuCatalog.instagram.packageName,
        minutes: 10,
        price: 15,
      );
      expect(r1, UnlockResult.ok);
      expect(appBeku.paidUnlocksToday, 1);
      expect(appBeku.extraUnlockedOf(AppBekuCatalog.instagram.packageName), 10);
      expect(appBeku.effectiveLimitOf(AppBekuCatalog.instagram.packageName), 40);

      // Unlock #2: biaya naik jadi 15 + 10 = 25
      expect(appBeku.effectiveUnlockPrice(15), 25);
      final r2 = await appBeku.unlockMinutes(
        wallet: wallet,
        packageName: AppBekuCatalog.instagram.packageName,
        minutes: 10,
        price: 15,
      );
      expect(r2, UnlockResult.ok);
      expect(appBeku.paidUnlocksToday, 2);
      expect(appBeku.effectiveLimitOf(AppBekuCatalog.instagram.packageName), 50);

      // Unlock #3: biaya naik jadi 15 + 20 = 35
      expect(appBeku.effectiveUnlockPrice(15), 35);
      final r3 = await appBeku.unlockMinutes(
        wallet: wallet,
        packageName: AppBekuCatalog.instagram.packageName,
        minutes: 10,
        price: 15,
      );
      expect(r3, UnlockResult.ok);
      expect(appBeku.paidUnlocksToday, 3);
      expect(appBeku.paidUnlockCapReached, isTrue);

      // Unlock #4: harus ditolak oleh pengaman etis (dailyCapReached)
      final r4 = await appBeku.unlockMinutes(
        wallet: wallet,
        packageName: AppBekuCatalog.instagram.packageName,
        minutes: 10,
        price: 15,
      );
      expect(r4, UnlockResult.dailyCapReached);
      expect(appBeku.paidUnlocksToday, 3);
    });
  });
}
