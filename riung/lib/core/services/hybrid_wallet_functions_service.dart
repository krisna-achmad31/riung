import '../models/coin_transaction.dart';
import '../models/monster_progress.dart';
import '../models/wallet.dart';
import 'firebase/firestore_wallet_functions_service.dart';
import 'local_wallet_functions_service.dart';
import 'wallet_functions_service.dart';

/// Router murni antara [LocalWalletFunctionsService] dan
/// [FirestoreWalletFunctionsService] berdasarkan status auth saat ini
/// (Poin 4 — "lokal-dulu, cloud-setelah-login"). SELAMA ANONIM, wallet
/// & progres monster sepenuhnya lokal (tidak menyentuh Firestore sama
/// sekali, hemat kuota Spark plan); begitu user login/link akun,
/// semuanya rute ke cloud. Tidak ada logic tambahan di sini selain
/// routing — supaya gampang di-test dan gampang dilacak kalau ada bug
/// "kenapa ini nulis ke Firestore padahal masih anonim".
class HybridWalletFunctionsService implements WalletFunctionsService {
  HybridWalletFunctionsService({
    required LocalWalletFunctionsService local,
    required FirestoreWalletFunctionsService cloud,
    required bool Function() isAnonymous,
  })  : _local = local,
        _cloud = cloud,
        _isAnonymous = isAnonymous;

  final LocalWalletFunctionsService _local;
  final FirestoreWalletFunctionsService _cloud;
  final bool Function() _isAnonymous;

  @override
  Future<Wallet> earnCoins({required String uid, required int amount, required String reason}) {
    return _isAnonymous()
        ? _local.earnCoins(uid: uid, amount: amount, reason: reason)
        : _cloud.earnCoins(uid: uid, amount: amount, reason: reason);
  }

  @override
  Future<Wallet> spendCoins({required String uid, required int amount, required String reason}) {
    return _isAnonymous()
        ? _local.spendCoins(uid: uid, amount: amount, reason: reason)
        : _cloud.spendCoins(uid: uid, amount: amount, reason: reason);
  }

  @override
  Future<Wallet> dailyCheckin({required String uid}) {
    return _isAnonymous() ? _local.dailyCheckin(uid: uid) : _cloud.dailyCheckin(uid: uid);
  }

  @override
  Future<MonsterProgress> tameProgress({required String uid, required String saboteurId, required int delta}) {
    return _isAnonymous()
        ? _local.tameProgress(uid: uid, saboteurId: saboteurId, delta: delta)
        : _cloud.tameProgress(uid: uid, saboteurId: saboteurId, delta: delta);
  }

  @override
  Future<List<CoinTransaction>> getTransactions({required String uid, int limit = 50}) {
    return _isAnonymous()
        ? _local.getTransactions(uid: uid, limit: limit)
        : _cloud.getTransactions(uid: uid, limit: limit);
  }
}
