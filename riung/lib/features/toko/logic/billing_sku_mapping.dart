import '../../../core/config/economy.dart';
import '../../../core/services/billing_service.dart';

/// Cocokkan [CoinPack] (sumber angka koin/harga, `economy.dart`) ke SKU
/// Play Billing yang benar (sumber id produk, `billing_service.dart`) lewat
/// total koin — keduanya harus selalu sinkron (80/330/820).
CoinPackSku billingSkuFor(CoinPack pack) {
  return CoinPackSku.values.firstWhere((s) => s.totalCoins == pack.totalCoins);
}
