import '../../../core/config/economy.dart';

/// Katalog kosmetik Toko § "Buat monstermu". Id & `canonicalWearer` HARUS
/// sama persis dengan `assets/monsters/anchors.json` § cosmetics supaya
/// [RiungMonster] bisa merender overlay-nya (CLAUDE.md aturan #7).
class TokoCosmetic {
  const TokoCosmetic({required this.id, required this.monsterId, required this.price});

  /// Nama tampil per bahasa: `TokoStrings.cosmeticName(id)`.
  final String id;
  final String monsterId;
  final int price;
}

const tokoCosmetics = [
  TokoCosmetic(id: 'topi_rajut', monsterId: 'kabut', price: EconomySpend.skinCommon),
  TokoCosmetic(id: 'syal_hangat', monsterId: 'waswas', price: EconomySpend.skinCommon),
  TokoCosmetic(id: 'bantal_mini', monsterId: 'meronta', price: EconomySpend.skinEpic),
  TokoCosmetic(id: 'bingkai_emas', monsterId: 'cermin', price: EconomySpend.skinLegendary),
];

/// 1 sesi vs paket 5 sesi Mode Fokus prabayar (Toko § "Beli sesi fokus") —
/// harga paket sengaja < 5× harga satuan ("HEMAT 20%" di desain).
abstract final class TokoFocusBundle {
  static const int hargaSatuSesi = EconomySpend.fokus25Menit;
  static const int jumlahPaket = 5;
  static const int hargaPaket = EconomySpend.fokusBundle5Sesi;
}
