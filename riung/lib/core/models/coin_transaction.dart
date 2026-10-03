import 'model_utils.dart';

/// Mirror `/users/{uid}/coinRequests/{id}` — jejak audit tiap mutasi koin,
/// ditulis oleh [FirestoreWalletFunctionsService] sejak M5. Dipakai
/// read-only oleh [KoinHistoriScreen] untuk menampilkan riwayat transaksi.
class CoinTransaction {
  const CoinTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.reason,
    required this.balanceAfter,
    required this.createdAt,
  });

  factory CoinTransaction.fromMap(String id, Map<String, dynamic> map) {
    return CoinTransaction(
      id: id,
      type: (map[fType] as String?) ?? 'earn',
      amount: parseInt(map[fAmount]),
      reason: (map[fReason] as String?) ?? '',
      balanceAfter: parseInt(map[fBalanceAfter]),
      createdAt: parseDate(map[fCreatedAt]) ?? DateTime.now(),
    );
  }

  static const fType = 'type';
  static const fAmount = 'amount';
  static const fReason = 'reason';
  static const fBalanceAfter = 'balanceAfter';
  static const fCreatedAt = 'createdAt';

  final String id;
  final String type;
  final int amount;
  final String reason;
  final int balanceAfter;
  final DateTime createdAt;

  bool get isEarn => type == 'earn';
}
