import 'package:flutter/painting.dart';

import '../../../core/config/economy.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/theme.dart';

/// Katalog kosmetik Toko § "Buat monstermu". Id & `canonicalWearer` HARUS
/// sama persis dengan `assets/monsters/anchors.json` § cosmetics supaya
/// [RiungMonster] bisa merender overlay-nya (CLAUDE.md aturan #7).
class TokoCosmetic {
  const TokoCosmetic({required this.id, required this.monsterId, required this.price, required this.slot, this.exclusive = false, this.khas = false});

  /// Nama tampil per bahasa: `TokoStrings.cosmeticName(id)`.
  final String id;
  final String monsterId;
  final int price;
  final CosmeticSlot slot;

  /// Hanya bisa dipakai [monsterId] (mis. bingkai emas = khusus Si Cermin).
  final bool exclusive;

  /// Kosmetik khas satu monster: hanya tampil di Lemari monster itu (tidak
  /// di etalase Toko & Lemari monster lain). Selalu [exclusive].
  final bool khas;

  bool wearableBy(String monster) => !exclusive || monster == monsterId;

  /// Tampil di Lemari [monster]: kosmetik umum, atau khas miliknya sendiri.
  bool listedFor(String monster) => !khas || monster == monsterId;

  static TokoCosmetic? byId(String id) {
    for (final c in tokoCosmetics) {
      if (c.id == id) return c;
    }
    return null;
  }

  /// Art 3D item lepas (tanpa monster) untuk kartu Toko.
  String get artAsset => 'assets/monsters/3d/$id.webp';

  TokoRarity get rarity => TokoRarity.ofPrice(price);
}

/// Slot pakai kosmetik, sama dengan `slot` di `assets/monsters/anchors.json`.
enum CosmeticSlot {
  head,
  neck,
  base,

  /// Benda kecil berdiri di lantai, di depan kanan monster (kosmetik khas).
  side,
  none;

  String label(TokoStrings t) => switch (this) {
        head => t.slotHead,
        neck => t.slotNeck,
        base => t.slotBase,
        side => t.slotSide,
        none => t.slotFrame,
      };
}

/// Tingkat kelangkaan kosmetik dari harganya (frame `Rarity`).
enum TokoRarity {
  common,
  epic,
  legendary;

  static TokoRarity ofPrice(int price) {
    if (price >= EconomySpend.skinLegendary) return legendary;
    if (price >= EconomySpend.skinEpic) return epic;
    return common;
  }

  String label(TokoStrings t) => switch (this) {
        common => t.rarityCommon,
        epic => t.rarityEpic,
        legendary => t.rarityLegendary,
      };

  Color get background => switch (this) {
        common => AppColors.permukaan,
        epic => AppColors.sekunderLembut,
        legendary => AppColors.emasLembut,
      };

  Color get foreground => switch (this) {
        common => AppColors.teksSekunder,
        epic => AppColors.sekunder,
        legendary => AppColors.emasGelap,
      };
}

const tokoCosmetics = [
  TokoCosmetic(id: 'topi_rajut', monsterId: 'kabut', price: EconomySpend.skinCommon, slot: CosmeticSlot.head),
  TokoCosmetic(id: 'syal_hangat', monsterId: 'waswas', price: EconomySpend.skinCommon, slot: CosmeticSlot.neck),
  TokoCosmetic(id: 'bantal_mini', monsterId: 'meronta', price: EconomySpend.skinEpic, slot: CosmeticSlot.base),
  TokoCosmetic(id: 'bingkai_emas', monsterId: 'cermin', price: EconomySpend.skinLegendary, slot: CosmeticSlot.none, exclusive: true),
  // Kosmetik khas — satu per monster, dijual di Lemari monster itu saja.
  TokoCosmetic(id: 'batu_tenang', monsterId: 'waswas', price: EconomySpend.skinKhas, slot: CosmeticSlot.side, exclusive: true, khas: true),
  TokoCosmetic(id: 'lentera', monsterId: 'kabut', price: EconomySpend.skinKhas, slot: CosmeticSlot.side, exclusive: true, khas: true),
  TokoCosmetic(id: 'bintang_kintsugi', monsterId: 'sempurna', price: EconomySpend.skinKhas, slot: CosmeticSlot.side, exclusive: true, khas: true),
  TokoCosmetic(id: 'senter', monsterId: 'mengelak', price: EconomySpend.skinKhas, slot: CosmeticSlot.side, exclusive: true, khas: true),
  TokoCosmetic(id: 'selimut_peluk', monsterId: 'meronta', price: EconomySpend.skinKhas, slot: CosmeticSlot.side, exclusive: true, khas: true),
  TokoCosmetic(id: 'palu_busa', monsterId: 'hakim', price: EconomySpend.skinKhas, slot: CosmeticSlot.side, exclusive: true, khas: true),
  TokoCosmetic(id: 'jam_pasir', monsterId: 'nanti', price: EconomySpend.skinKhas, slot: CosmeticSlot.side, exclusive: true, khas: true),
  TokoCosmetic(id: 'kantong_hp', monsterId: 'gulir', price: EconomySpend.skinKhas, slot: CosmeticSlot.side, exclusive: true, khas: true),
  TokoCosmetic(id: 'topi_tidur', monsterId: 'begadang', price: EconomySpend.skinKhas, slot: CosmeticSlot.head, exclusive: true, khas: true),
  TokoCosmetic(id: 'pin_berani', monsterId: 'bunglon', price: EconomySpend.skinKhas, slot: CosmeticSlot.neck, exclusive: true, khas: true),
  TokoCosmetic(id: 'kompas', monsterId: 'bimbang', price: EconomySpend.skinKhas, slot: CosmeticSlot.side, exclusive: true, khas: true),
  TokoCosmetic(id: 'cangkir_teh', monsterId: 'bara', price: EconomySpend.skinKhas, slot: CosmeticSlot.side, exclusive: true, khas: true),
];

/// 1 sesi vs paket 5 sesi Mode Fokus prabayar (Toko § "Beli sesi fokus") —
/// harga paket sengaja < 5× harga satuan ("HEMAT 20%" di desain).
abstract final class TokoFocusBundle {
  static const int hargaSatuSesi = EconomySpend.fokus25Menit;
  static const int jumlahPaket = 5;
  static const int hargaPaket = EconomySpend.fokusBundle5Sesi;
}
