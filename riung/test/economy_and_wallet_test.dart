import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:riung/core/config/economy.dart';
import 'package:riung/core/models/models.dart';
import 'package:riung/core/services/services.dart';
import 'package:riung/core/state/monster_progress_notifier.dart';
import 'package:riung/core/state/session_notifier.dart';
import 'package:riung/core/state/streak_notifier.dart';
import 'package:riung/core/state/wallet_notifier.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Konfigurasi Ekonomi Riung (economy.dart)', () {
    test('Reward Earn sesuai aturan CLAUDE.md §3', () {
      expect(EconomyEarn.checkinHarian, 5);
      expect(EconomyEarn.jurnal, 4);
      expect(EconomyEarn.meditasi, 3);
      expect(EconomyEarn.misiHarian, 3);
      expect(EconomyEarn.menangGame, 8);
      expect(EconomyEarn.monsterJinak, 50);
      expect(EconomyEarn.betterMeLesson, 10);
      expect(EconomyEarn.streak7Hari, 20);
      expect(EconomyEarn.streak30Hari, 100);

      // Progres fokus & mini-game
      expect(EconomyEarn.fokusProgressPercent, 4);
      expect(EconomyEarn.minigameWinProgressPercent, 5);
      expect(EconomyEarn.minigameLoseProgressPercent, 2);
    });

    test('Biaya Spend sesuai aturan CLAUDE.md §3', () {
      expect(EconomySpend.fokus25Menit, 25);
      expect(EconomySpend.fokus45Menit, 40);
      expect(EconomySpend.fokus60Menit, 50);
      expect(EconomySpend.pelindungStreak, 20);
      expect(EconomySpend.tiketTambahan, 30);
      expect(EconomySpend.aksesorisKecil, 60);
      expect(EconomySpend.skinCommon, 100);
      expect(EconomySpend.skinEpic, 300);
      expect(EconomySpend.skinLegendary, 500);
      expect(EconomySpend.skinKhas, EconomySpend.skinEpic);
      expect(EconomySpend.scrollUnlockMulai, 15);
      expect(EconomySpend.fokusBundle5Sesi, 100);
      expect(EconomySpend.aksesorisBundelDiskonPersen, 20);
      expect(EconomySpend.aksesorisBundelPembulatan, 5);
    });

    test('Aturan Tiket & Free Tier', () {
      expect(EconomyTiket.gratisPerHari, 1);
      expect(EconomyTiket.maxDariLatihanPerHari, 3);
      expect(EconomyTiket.maxFightPerHari, 4);
      expect(EconomyTiket.tiketDijual, isFalse, reason: 'Tiket tidak boleh dijual langsung dengan uang');

      expect(EconomyFreeTier.meditasi, 3);
      expect(EconomyFreeTier.ceritaTidur, 2);
      expect(EconomyFreeTier.jurnalPerHari, 1);
      expect(EconomyFreeTier.minigamePerHari, 1);
      expect(EconomyFreeTier.fokusPerHari, 1);
    });

    test('Coin Packs & Paket Premium', () {
      expect(EconomyCoinPacks.all.length, 3);
      expect(EconomyCoinPacks.kantong.totalCoins, 80);
      expect(EconomyCoinPacks.kantong.priceIdr, 15000);
      expect(EconomyCoinPacks.peti.totalCoins, 330);
      expect(EconomyCoinPacks.peti.priceIdr, 49000);
      expect(EconomyCoinPacks.brankas.totalCoins, 820);
      expect(EconomyCoinPacks.brankas.priceIdr, 99000);

      expect(EconomyPremium.hargaBulananIdr, 59000);
      expect(EconomyPremium.bulanDibayarPerTahun, 10);
      expect(EconomyPremium.hargaTahunanIdr, 590000);
      expect(EconomyPremium.trialHari, 7);
      expect(EconomyPremium.fokusGratisPerHari, 3);
      expect(EconomyPremium.koinHarianTahunan, 2);
    });
  });

  group('WalletNotifier', () {
    late LocalPrefsStore prefs;
    late LocalUserRepository userRepo;
    late LocalWalletFunctionsService walletFunctions;
    late WalletNotifier wallet;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await LocalPrefsStore.init();
      await prefs.setCoins(0);
      await prefs.setLifetimeEarned(0);
      await prefs.setLifetimeSpent(0);
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
      await wallet.load('user_test_123');
    });

    test('Inisialisasi saldo & tiket', () {
      expect(wallet.coins, 0);
      expect(wallet.earnedCoins, 0);
      expect(wallet.tickets, 1, reason: 'Tiket harian gratis 1 diberikan saat init');
      expect(wallet.fightsRemainingToday, EconomyTiket.maxFightPerHari);
      expect(wallet.dailyFightCapReached, isFalse);
    });

    test('Earn koin menambah saldo dan earnedCoins', () async {
      await wallet.earn(amount: 10, reason: 'latihan');
      expect(wallet.coins, 10);
      expect(wallet.earnedCoins, 10);
    });

    test('Spend koin berhasil jika saldo cukup dan gagal jika saldo kurang', () async {
      await wallet.earn(amount: 15, reason: 'latihan');
      final fail = await wallet.spend(amount: 20, reason: 'test_fail');
      expect(fail, isFalse);
      expect(wallet.coins, 15);

      final pass = await wallet.spend(amount: 10, reason: 'test_pass');
      expect(pass, isTrue);
      expect(wallet.coins, 5);
      expect(wallet.earnedCoins, 5);
    });

    test('Pembelian koin dicatat ke cadangan koin-beli (purchasedReserve)', () async {
      await wallet.earn(amount: 50, reason: 'beli_pack');
      await wallet.recordPurchasedCoins(50);
      expect(wallet.coins, 50);
      expect(wallet.earnedCoins, 0, reason: 'Koin beli tidak boleh dihitung sebagai earnedCoins untuk buka aplikasi');

      // earn latihan lagi
      await wallet.earn(amount: 15, reason: 'latihan');
      expect(wallet.coins, 65);
      expect(wallet.earnedCoins, 15);
    });

    test('Pengambilan koin harian Premium tahunan hanya sekali sehari', () async {
      expect(wallet.premiumDailyClaimable, isTrue);
      final claimed1 = await wallet.claimPremiumDaily();
      expect(claimed1, isTrue);
      expect(wallet.coins, EconomyPremium.koinHarianTahunan);
      expect(wallet.premiumDailyClaimable, isFalse);

      final claimed2 = await wallet.claimPremiumDaily();
      expect(claimed2, isFalse);
    });

    test('Konsumsi tiket serangan & batas maksimum harian', () async {
      expect(wallet.tickets, 1);
      final fight1 = await wallet.useTicket();
      expect(fight1, isTrue);
      expect(wallet.tickets, 0);

      // Tiket habis, useTicket gagal
      final fightFail = await wallet.useTicket();
      expect(fightFail, isFalse);

      // Tambah tiket dari latihan (maks 3)
      await wallet.addTickets(1);
      expect(wallet.tickets, 1);
      await wallet.addTickets(2);
      expect(wallet.tickets, 3);
      await wallet.addTickets(1); // melebihi batas 3 dari latihan
      expect(wallet.tickets, 3);

      expect(await wallet.useTicket(), isTrue); // total 2 fights
      expect(await wallet.useTicket(), isTrue); // total 3 fights
      expect(await wallet.useTicket(), isTrue); // total 4 fights

      expect(wallet.dailyFightCapReached, isTrue);
      expect(wallet.fightsRemainingToday, 0);
      expect(await wallet.useTicket(), isFalse);
    });

    test('Sesi Fokus gratis per hari (Free vs Premium)', () async {
      expect(WalletNotifier.freeFocusLimit(premium: false), 1);
      expect(WalletNotifier.freeFocusLimit(premium: true), 3);

      expect(wallet.freeFocusAvailable(premium: false), isTrue);
      expect(wallet.freeFocusRemaining(premium: false), 1);

      final consumed = await wallet.consumeFreeFocusSession(premium: false);
      expect(consumed, isTrue);
      expect(wallet.freeFocusRemaining(premium: false), 0);
      expect(wallet.freeFocusAvailable(premium: false), isFalse);

      // Jika user beralih ke Premium, jatah masih tersisa 2
      expect(wallet.freeFocusRemaining(premium: true), 2);
      expect(wallet.freeFocusAvailable(premium: true), isTrue);
    });

    test('Manajemen kosmetik dan pembelian bundel', () async {
      await wallet.earn(amount: 500, reason: 'saldo_cukup');
      expect(wallet.ownsCosmetic('topi_rajut'), isFalse);

      final buySuccess = await wallet.buyCosmetic(id: 'topi_rajut', price: 60);
      expect(buySuccess, isTrue);
      expect(wallet.ownsCosmetic('topi_rajut'), isTrue);
      expect(wallet.coins, 500 - 60);

      // Beli bundle kosmetik
      final bundleSuccess = await wallet.buyCosmeticBundle(
        bundleId: 'bundle_1',
        ids: ['topi_rajut', 'syal_hangat'],
        price: 80,
      );
      expect(bundleSuccess, isTrue);
      expect(wallet.ownsCosmetic('syal_hangat'), isTrue);
    });

    test('Prepaid focus sessions & pelindung streak', () async {
      await wallet.earn(amount: 200, reason: 'saldo');
      expect(wallet.prepaidFocusSessions, 0);

      final buyFocus = await wallet.buyPrepaidFocusSessions(count: 5, price: 100);
      expect(buyFocus, isTrue);
      expect(wallet.prepaidFocusSessions, 5);

      final useFocus = await wallet.consumePrepaidFocusSession();
      expect(useFocus, isTrue);
      expect(wallet.prepaidFocusSessions, 4);

      expect(wallet.streakShieldBalance, 0);
      final buyShield = await wallet.buyStreakShield(price: 20);
      expect(buyShield, isTrue);
      expect(wallet.streakShieldBalance, 1);
    });
  });

  group('StreakNotifier', () {
    test('checkInHariIni menaikkan streak dan longest', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await LocalPrefsStore.init();
      await prefs.setUserProfileJson(UserProfile.kosong('user_streak_1').toMap());
      final userRepo = LocalUserRepository(
        prefs: prefs,
        db: LocalDatabaseService(),
        crypto: JournalCryptoService(),
      );
      final streak = StreakNotifier(userRepository: userRepo);
      await streak.load('user_streak_1');

      expect(streak.current, 0);
      expect(streak.longest, 0);
      expect(streak.sudahCheckinHariIni, isFalse);

      streak.checkInHariIni();
      expect(streak.current, 1);
      expect(streak.longest, 1);
      expect(streak.sudahCheckinHariIni, isTrue);

      // Checkin kedua di hari yang sama diabaikan
      streak.checkInHariIni();
      expect(streak.current, 1);
    });
  });

  group('SessionNotifier (Mode Fokus)', () {
    test('start, pause, resume, complete, cancel', () {
      final session = SessionNotifier();
      expect(session.isActive, isFalse);
      expect(session.isPaused, isFalse);
      expect(session.endReason, SessionEndReason.none);

      session.start(const Duration(minutes: 25));
      expect(session.isActive, isTrue);
      expect(session.isPaused, isFalse);
      expect(session.remaining.inMinutes, 25);

      session.pause();
      expect(session.isPaused, isTrue);

      session.resume();
      expect(session.isPaused, isFalse);

      session.complete();
      expect(session.isActive, isFalse);
      expect(session.endReason, SessionEndReason.completed);

      session.start(const Duration(minutes: 10));
      session.cancel();
      expect(session.isActive, isFalse);
      expect(session.endReason, SessionEndReason.cancelled);
    });
  });

  group('MonsterProgressNotifier', () {
    test('ensureAllSaboteurs & tambahProgres', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await LocalPrefsStore.init();
      await prefs.setMonsterProgressJson({});
      final userRepo = LocalUserRepository(
        prefs: prefs,
        db: LocalDatabaseService(),
        crypto: JournalCryptoService(),
      );
      final walletFunctions = LocalWalletFunctionsService(prefs: prefs, userRepository: userRepo);
      final mp = MonsterProgressNotifier(
        userRepository: userRepo,
        walletFunctions: walletFunctions,
      );
      await mp.load('user_mp_1');

      expect(mp.all, isEmpty);

      mp.ensureAllSaboteurs(['waswas', 'hakim', 'kabut']);
      expect(mp.all.length, 3);
      expect(mp.progressOf('waswas')?.progress, 0);
      expect(mp.progressOf('waswas')?.state, MonsterState.wild);

      await mp.tambahProgres(saboteurId: 'waswas', delta: 20);
      expect(mp.progressOf('waswas')?.progress, 20);
      expect(mp.progressOf('waswas')?.state, MonsterState.taming);

      await mp.tambahProgres(saboteurId: 'waswas', delta: 80);
      expect(mp.progressOf('waswas')?.progress, 100);
      expect(mp.progressOf('waswas')?.state, MonsterState.tamed);
    });
  });
}
