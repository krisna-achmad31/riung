import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:riung/core/config/economy.dart';
import 'package:riung/core/services/services.dart';
import 'package:riung/core/state/state.dart';

/// Pengaman etis buka-waktu Aplikasi Beku & sesi Fokus gratis (CLAUDE.md
/// aturan #4): tidak ada jalur uang → progres/buka-waktu tanpa batas.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late LocalPrefsStore prefs;
  late WalletNotifier wallet;
  late AppBekuNotifier appBeku;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    // LocalPrefsStore adalah singleton; hapus cache lewat store baru per test.
    prefs = await LocalPrefsStore.init();
    // Store-nya singleton (state bertahan antar test) — reset yang relevan
    // SEBELUM wallet.load membacanya.
    await prefs.setPurchasedCoinsReserve(0);
    await prefs.setFreeFocusDate('');
    await prefs.setFreeFocusUsed(0);
    await prefs.setPremiumDailyClaimDate('');
    final users = LocalUserRepository(prefs: prefs, db: LocalDatabaseService(), crypto: JournalCryptoService());
    wallet = WalletNotifier(
      userRepository: users,
      walletFunctions: LocalWalletFunctionsService(prefs: prefs, userRepository: users),
      prefs: prefs,
    );
    await wallet.load('u1');
    appBeku = AppBekuNotifier(prefs: prefs);
  });

  test('harga buka-waktu naik bertingkat dan dibatasi per hari', () async {
    await wallet.earn(amount: 500, reason: 'test');
    expect(appBeku.effectiveUnlockPrice(15), 15);
    final prices = <int>[];
    for (var i = 0; i < EconomyScroll.maxPaidUnlocksPerDay; i++) {
      final before = wallet.coins;
      final r = await appBeku.unlockMinutes(wallet: wallet, packageName: 'com.instagram.android', minutes: 10, price: 15);
      expect(r, UnlockResult.ok);
      prices.add(before - wallet.coins);
    }
    expect(prices, [15, 25, 35]);
    expect(appBeku.paidUnlockCapReached, isTrue);
    final over = await appBeku.unlockMinutes(wallet: wallet, packageName: 'com.instagram.android', minutes: 10, price: 15);
    expect(over, UnlockResult.dailyCapReached);
  });

  test('koin beli tidak bisa dipakai buka-waktu, koin hasil latihan bisa', () async {
    // Anggap SELURUH saldo sekarang berasal dari pembelian.
    await wallet.recordPurchasedCoins(wallet.coins);
    final saldo = wallet.coins;
    expect(wallet.earnedCoins, 0);
    final blocked = await appBeku.unlockMinutes(wallet: wallet, packageName: 'com.instagram.android', minutes: 10, price: 15);
    expect(blocked, UnlockResult.notEnoughEarnedCoins);
    expect(wallet.coins, saldo, reason: 'saldo tidak terpotong');

    await wallet.earn(amount: 20, reason: 'jurnal:test'); // koin hasil latihan
    expect(wallet.earnedCoins, 20);
    final ok = await appBeku.unlockMinutes(wallet: wallet, packageName: 'com.instagram.android', minutes: 10, price: 15);
    expect(ok, UnlockResult.ok);
  });

  test('belanja biasa memakai koin beli lebih dulu', () async {
    await wallet.recordPurchasedCoins(wallet.coins); // saldo awal = koin beli
    await wallet.earn(amount: 50, reason: 'x'); // + 50 koin latihan
    final saldo = wallet.coins;
    expect(wallet.earnedCoins, 50);
    await wallet.spend(amount: 60, reason: 'skin');
    expect(wallet.coins, saldo - 60);
    expect(wallet.earnedCoins, 50, reason: 'koin beli terpakai duluan, koin latihan utuh');
  });

  test('satu sesi Fokus gratis per hari', () async {
    expect(wallet.freeFocusAvailable(), isTrue);
    expect(await wallet.consumeFreeFocusSession(), isTrue);
    expect(wallet.freeFocusAvailable(), isFalse);
    expect(await wallet.consumeFreeFocusSession(), isFalse);
  });

  test('Premium: tiga sesi Fokus gratis per hari, non-Premium satu', () async {
    expect(wallet.freeFocusRemaining(premium: true), EconomyPremium.fokusGratisPerHari);
    for (var i = 0; i < EconomyPremium.fokusGratisPerHari; i++) {
      expect(await wallet.consumeFreeFocusSession(premium: true), isTrue);
    }
    expect(await wallet.consumeFreeFocusSession(premium: true), isFalse);
    // Jatah non-Premium tetap 1: habis di hari yang sama.
    expect(wallet.freeFocusAvailable(), isFalse);
  });

  test('koin harian tahunan: sekali sehari, dan tidak bisa dipakai buka-waktu', () async {
    final earnedBefore = wallet.earnedCoins;
    final saldoBefore = wallet.coins;
    expect(wallet.premiumDailyClaimable, isTrue);
    expect(await wallet.claimPremiumDaily(), isTrue);
    expect(wallet.coins, saldoBefore + EconomyPremium.koinHarianTahunan);
    expect(wallet.earnedCoins, earnedBefore, reason: 'masuk cadangan koin-beli, bukan koin latihan');
    expect(await wallet.claimPremiumDaily(), isFalse, reason: 'hanya sekali per hari');
  });

  test('harga tahunan = bayar 10 bulan', () {
    expect(EconomyPremium.hargaTahunanIdr, EconomyPremium.hargaBulananIdr * 10);
    expect(EconomyPremium.bulanDibayarPerTahun + EconomyPremium.bulanGratisPerTahun, 12);
  });
}
