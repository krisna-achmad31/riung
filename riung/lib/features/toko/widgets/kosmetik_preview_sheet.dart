import 'package:flutter/material.dart';

import '../../../core/config/economy.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../logic/toko_data.dart';
import '../screens/koin_kurang_screen.dart';

String _rarityLabel(TokoStrings t, int price) {
  if (price >= EconomySpend.skinLegendary) return t.rarityLegendary;
  if (price >= EconomySpend.skinEpic) return t.rarityEpic;
  return t.rarityCommon;
}

Color _rarityColor(int price) {
  if (price >= EconomySpend.skinLegendary) return AppColors.aksenHangat;
  if (price >= EconomySpend.skinEpic) return AppColors.monsterCermin;
  return AppColors.sekunder;
}

/// Preview kosmetik sebelum beli — RiungMonster memakai kosmetiknya,
/// badge rarity, harga, tombol Beli/Tutup. Menggantikan alur lama (tap
/// kartu langsung ke sheet konfirmasi generik) dengan preview dulu, biar
/// kelihatan hasilnya sebelum bayar.
Future<void> showKosmetikPreviewSheet(BuildContext context, {required TokoCosmetic cosmetic}) async {
  final scope = AppScope.of(context);
  final wallet = scope.wallet;
  final t = context.s.toko;
  final rarity = _rarityLabel(t, cosmetic.price);
  final rarityColor = _rarityColor(cosmetic.price);

  final beli = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: AppColors.permukaan,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (sheetContext) => ListenableBuilder(
      listenable: wallet,
      builder: (context, _) {
        final owned = wallet.ownsCosmetic(cosmetic.id);
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(color: AppColors.garis, borderRadius: BorderRadius.circular(AppRadius.pill)),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                width: 128,
                height: 136,
                decoration: BoxDecoration(
                  color: AppColors.kartu,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                ),
                alignment: Alignment.center,
                child: SizedBox(
                  width: 100,
                  height: 108,
                  child: RiungMonster(
                    monsterId: cosmetic.monsterId,
                    state: MonsterVisualState.jinak,
                    size: 100,
                    cosmetics: [cosmetic.id],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(context.s.toko.cosmeticName(cosmetic.id), textAlign: TextAlign.center, style: AppTextStyles.subtitle.copyWith(fontSize: 16)),
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
                decoration: BoxDecoration(
                  color: rarityColor.withValues(alpha: 0.14),
                  border: Border.all(color: rarityColor.withValues(alpha: 0.4)),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  rarity.toUpperCase(),
                  style: AppTextStyles.caption.copyWith(color: rarityColor, fontWeight: FontWeight.w700, fontSize: 10, letterSpacing: 0.6),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (owned)
                Text(context.s.toko.alreadyOwned, style: AppTextStyles.chipLabel.copyWith(color: AppColors.sukses, fontSize: 13))
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.monetization_on, size: 16, color: AppColors.aksenHangat),
                    const SizedBox(width: 6),
                    Text(context.s.toko.coinsPrice(cosmetic.price), style: AppTextStyles.subtitle.copyWith(color: AppColors.aksenHangat, fontSize: 15)),
                  ],
                ),
              const SizedBox(height: AppSpacing.lg),
              RiungButton(
                label: owned ? context.s.toko.alreadyOwned : context.s.toko.buyFor(cosmetic.price),
                onPressed: owned ? null : () => Navigator.of(sheetContext).pop(true),
              ),
              const SizedBox(height: AppSpacing.xs),
              TextButton(
                onPressed: () => Navigator.of(sheetContext).pop(false),
                child: Text(context.s.common.tutup, style: AppTextStyles.chipLabel.copyWith(color: AppColors.teksRedup, fontSize: 13)),
              ),
            ],
          ),
        );
      },
    ),
  );

  if (beli != true || !context.mounted) return;

  if (wallet.coins < cosmetic.price) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => KoinKurangScreen(needed: cosmetic.price, backTitle: t.shopTitle)));
    return;
  }
  final berhasil = await wallet.buyCosmetic(id: cosmetic.id, price: cosmetic.price);
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(berhasil ? t.cosmeticOwnedNow(t.cosmeticName(cosmetic.id)) : t.coinsChanged)),
  );
}
