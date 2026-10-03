import '../config/economy.dart';
import '../models/coin_transaction.dart';
import '../models/monster_progress.dart';
import '../models/wallet.dart';
import 'local_prefs_store.dart';
import 'user_repository.dart';
import 'wallet_functions_service.dart';

/// Implementasi [WalletFunctionsService] sungguhan sejak M3 — saldo koin
/// dipersist ke [LocalPrefsStore] (shared_preferences), progres monster ke
/// [UserRepository.saveMonsterProgress]. Bertahan setelah app di-restart.
/// Cloud Functions asli menggantikannya di M5 (mekanisme sama, backend beda).
class LocalWalletFunctionsService implements WalletFunctionsService {
  LocalWalletFunctionsService({required LocalPrefsStore prefs, required UserRepository userRepository})
      : _prefs = prefs,
        _userRepository = userRepository;

  final LocalPrefsStore _prefs;
  final UserRepository _userRepository;

  Future<Wallet> _currentWallet(String uid) => _userRepository.getWallet(uid);

  Future<Wallet> _persist(Wallet wallet) async {
    await _prefs.setCoins(wallet.coins);
    await _prefs.setLifetimeEarned(wallet.lifetimeEarned);
    await _prefs.setLifetimeSpent(wallet.lifetimeSpent);
    return wallet;
  }

  @override
  Future<Wallet> earnCoins({required String uid, required int amount, required String reason}) async {
    final wallet = await _currentWallet(uid);
    return _persist(wallet.copyWith(
      coins: wallet.coins + amount,
      lifetimeEarned: wallet.lifetimeEarned + amount,
    ));
  }

  @override
  Future<Wallet> spendCoins({required String uid, required int amount, required String reason}) async {
    final wallet = await _currentWallet(uid);
    if (wallet.coins < amount) {
      throw InsufficientCoinsException(wallet.coins, amount);
    }
    return _persist(wallet.copyWith(
      coins: wallet.coins - amount,
      lifetimeSpent: wallet.lifetimeSpent + amount,
    ));
  }

  @override
  Future<Wallet> dailyCheckin({required String uid}) {
    return earnCoins(uid: uid, amount: EconomyEarn.checkinHarian, reason: 'daily_checkin');
  }

  @override
  Future<MonsterProgress> tameProgress({
    required String uid,
    required String saboteurId,
    required int delta,
  }) async {
    final monsters = Map<String, MonsterProgress>.from(await _userRepository.getMonsterProgress(uid));
    final current = monsters[saboteurId] ?? MonsterProgress.initial(saboteurId);
    final nextProgress = (current.progress + delta).clamp(0, 100);
    final justTamed = nextProgress >= 100 && current.state != MonsterState.tamed;
    final updated = current.copyWith(
      progress: nextProgress,
      state: nextProgress >= 100
          ? MonsterState.tamed
          : (nextProgress > 0 ? MonsterState.taming : MonsterState.wild),
      tamedAt: justTamed ? DateTime.now() : current.tamedAt,
    );
    monsters[saboteurId] = updated;
    await _userRepository.saveMonsterProgress(uid, monsters);
    if (justTamed) {
      await earnCoins(uid: uid, amount: EconomyEarn.monsterJinak, reason: 'monster_tamed:$saboteurId');
    }
    return updated;
  }

  /// Implementasi lokal tidak pernah menyimpan log per-transaksi (cuma
  /// saldo akhir di [LocalPrefsStore]) — kembalikan list kosong, layar
  /// riwayat lalu menampilkan empty state alih-alih data karangan.
  @override
  Future<List<CoinTransaction>> getTransactions({required String uid, int limit = 50}) async => const [];
}
