import '../../../core/config/economy.dart';
import '../../../core/services/api/api_config_store.dart';

/// Gaya tampilan kartu karakter (add-on kosmetik). Hanya tampilan: tidak
/// mengubah hasil tes, progres monster, atau ekonomi apa pun (CLAUDE.md
/// aturan #4). Harga dari `EconomySpend` (tier kosmetik yang sama dengan
/// skin monster), dibeli dengan koin lewat `WalletNotifier.buyCosmetic`.
enum CardStyle {
  klasik,
  taman,
  arkade,
  galaksi,
  aurora;

  /// Id yang disimpan di prefs & dipakai sebagai id kosmetik.
  String get id => name;

  /// Id di set `ownedCosmetics` milik dompet.
  String get cosmeticId => 'cardstyle_$name';

  /// Harga koin; null = gratis (gaya bawaan).
  int? get price {
    switch (this) {
      case CardStyle.klasik:
        return null;
      case CardStyle.taman:
      case CardStyle.arkade:
        return ApiConfigStore.instance.itemPrice('cardStyles', id, EconomySpend.skinCommon);
      case CardStyle.galaksi:
      case CardStyle.aurora:
        return ApiConfigStore.instance.itemPrice('cardStyles', id, EconomySpend.skinEpic);
    }
  }

  bool get isFree => price == null;

  static CardStyle fromId(String? id) {
    for (final style in values) {
      if (style.id == id) return style;
    }
    return CardStyle.klasik;
  }
}
