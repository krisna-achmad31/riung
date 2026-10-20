import 'model_utils.dart';

/// Mirror `/users/{uid}.wallet` — HANYA ditulis oleh Cloud Functions
/// (lihat CLAUDE.md aturan #5). Client memakai model ini untuk membaca &
/// menampilkan saldo, tidak pernah menulis langsung ke field koin.
class Wallet {
  const Wallet({
    required this.coins,
    required this.lifetimeEarned,
    required this.lifetimeSpent,
    this.earnedCoins = 0,
    this.purchasedCoins = 0,
    this.debtCoins = 0,
  });

  factory Wallet.zero() =>
      const Wallet(coins: 0, lifetimeEarned: 0, lifetimeSpent: 0);

  factory Wallet.fromMap(Map<String, dynamic> map) {
    return Wallet(
      coins: parseInt(map[fCoins]),
      lifetimeEarned: parseInt(map[fLifetimeEarned]),
      lifetimeSpent: parseInt(map[fLifetimeSpent]),
      earnedCoins: parseInt(map['earnedCoins']),
      purchasedCoins: parseInt(map['purchasedCoins']),
      debtCoins: parseInt(map['debtCoins']),
    );
  }

  static const fCoins = 'coins';
  static const fLifetimeEarned = 'lifetimeEarned';
  static const fLifetimeSpent = 'lifetimeSpent';

  final int coins;
  final int lifetimeEarned;
  final int lifetimeSpent;
  final int earnedCoins;
  final int purchasedCoins;
  final int debtCoins;

  Map<String, dynamic> toMap() => {
        fCoins: coins,
        fLifetimeEarned: lifetimeEarned,
        fLifetimeSpent: lifetimeSpent,
        'earnedCoins': earnedCoins,
        'purchasedCoins': purchasedCoins,
        'debtCoins': debtCoins,
      };

  Wallet copyWith({int? coins, int? lifetimeEarned, int? lifetimeSpent}) {
    return Wallet(
      coins: coins ?? this.coins,
      lifetimeEarned: lifetimeEarned ?? this.lifetimeEarned,
      lifetimeSpent: lifetimeSpent ?? this.lifetimeSpent,
      earnedCoins: earnedCoins,
      purchasedCoins: purchasedCoins,
      debtCoins: debtCoins,
    );
  }
}
