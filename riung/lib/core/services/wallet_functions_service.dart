import '../models/coin_transaction.dart';
import '../models/monster_progress.dart';
import '../models/wallet.dart';

/// Interface mutasi koin & progres — mirror Cloud Functions
/// (`spendCoins`, `earnCoins`, `dailyCheckin`, `tameProgress`, lihat
/// `docs/firebase-architecture.md` §5). Client TIDAK PERNAH menulis saldo
/// langsung (CLAUDE.md aturan #5) — semua mutasi lewat interface ini.
/// Implementasi lokal ([LocalWalletFunctionsService]) mempersist ke
/// perangkat sejak M3; Cloud Functions asli menggantikannya di M5.
abstract class WalletFunctionsService {
  Future<Wallet> earnCoins({required String uid, required int amount, required String reason});

  /// Melempar [InsufficientCoinsException] bila saldo tidak cukup.
  Future<Wallet> spendCoins({required String uid, required int amount, required String reason});

  Future<Wallet> dailyCheckin({required String uid});

  Future<MonsterProgress> tameProgress({
    required String uid,
    required String saboteurId,
    required int delta,
  });

  /// Riwayat mutasi koin, terbaru duluan. Sumber datanya sub-koleksi audit
  /// `coinRequests` yang ditulis tiap [earnCoins]/[spendCoins] (lihat
  /// [FirestoreWalletFunctionsService._writeAudit]) — belum ada di
  /// [LocalWalletFunctionsService] karena implementasi lokal tidak pernah
  /// menyimpan log per-transaksi, cuma saldo akhir.
  Future<List<CoinTransaction>> getTransactions({required String uid, int limit = 50});
}

/// Jumlah mutasi koin tidak boleh negatif — `spendCoins(-100)` akan lolos
/// cek saldo lalu MENAMBAH koin. Nol diizinkan (sub-langkah bundel Aplikasi
/// Beku memotong 0 koin). Dipanggil di awal setiap implementasi.
void checkCoinAmount(int amount) {
  if (amount < 0) throw ArgumentError.value(amount, 'amount', 'Jumlah koin tidak boleh negatif');
}

class InsufficientCoinsException implements Exception {
  InsufficientCoinsException(this.balance, this.requested);
  final int balance;
  final int requested;

  @override
  String toString() => 'Saldo koin tidak cukup: punya $balance, butuh $requested';
}
