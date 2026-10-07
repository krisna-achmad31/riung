import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../logic/toko_data.dart';
import '../screens/koin_kurang_screen.dart';
import 'koin_price_pill.dart';

/// Preview kosmetik sebelum beli — RiungMonster memakai kosmetiknya,
/// badge rarity, harga, tombol Beli/Tutup. Menggantikan alur lama (tap
/// kartu langsung ke sheet konfirmasi generik) dengan preview dulu, biar
/// kelihatan hasilnya sebelum bayar.
Future<void> showKosmetikPreviewSheet(BuildContext context, {required TokoCosmetic cosmetic}) async {
  final scope = AppScope.of(context);
  final wallet = scope.wallet;
  final t = context.s.toko;
  final rarity = cosmetic.rarity;

  final beli = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => ListenableBuilder(
      listenable: wallet,
      builder: (context, _) {
        final owned = wallet.ownsCosmetic(cosmetic.id);
        return Padding(
          padding: EdgeInsets.fromLTRB(24, 12, 24, 26 + MediaQuery.paddingOf(context).bottom),
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
                width: 170,
                height: 170,
                decoration: AppGlass.card(radius: 34, shadowed: false),
                alignment: Alignment.center,
                child: RiungMonster(monsterId: cosmetic.monsterId, state: MonsterVisualState.jinak, size: 140, applyBossScale: false, cosmetics: [cosmetic.id]),
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: rarity.background, borderRadius: BorderRadius.circular(AppRadius.pill)),
                child: Text(rarity.label(t), style: AppTextStyles.caption.copyWith(fontSize: 10, fontWeight: FontWeight.w700, color: rarity.foreground)),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(t.cosmeticName(cosmetic.id), textAlign: TextAlign.center, style: AppTextStyles.title.copyWith(fontSize: 20)),
              const SizedBox(height: AppSpacing.md),
              if (owned)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_rounded, size: 16, color: AppColors.primer),
                    const SizedBox(width: 4),
                    Text(t.alreadyOwned, style: AppTextStyles.chipLabel.copyWith(color: AppColors.primer, fontSize: 13)),
                  ],
                )
              else
                KoinPricePill(label: t.coinsPrice(cosmetic.price)),
              const SizedBox(height: AppSpacing.lg),
              RiungButton(
                label: owned ? context.s.toko.alreadyOwned : context.s.toko.buyFor(cosmetic.price),
                onPressed: owned ? null : () => Navigator.of(sheetContext).pop(true),
              ),
              const SizedBox(height: 10),
              RiungButton(label: context.s.common.tutup, variant: RiungButtonVariant.secondary, onPressed: () => Navigator.of(sheetContext).pop(false)),
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
