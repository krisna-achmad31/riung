import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/theme.dart';
import '../logic/toko_data.dart';
import 'koin_price_pill.dart';

/// Kartu item Lemari (frame `Item …`): rarity + centang dipakai, art item,
/// nama, lalu status (kosmetik khas berlabel "Khas" alih-alih rarity) — "Dipakai", harga (belum dimiliki), atau "Khusus …".
class LemariItemCard extends StatelessWidget {
  const LemariItemCard({super.key, required this.cosmetic, required this.owned, required this.wearable, required this.worn, required this.onTap});

  final TokoCosmetic cosmetic;
  final bool owned;
  final bool wearable;
  final bool worn;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.s.toko;
    final rarity = cosmetic.rarity;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: worn ? AppColors.permukaanPadat.withValues(alpha: 0.85) : AppColors.kartu,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: worn ? AppColors.primer : AppColors.garis, width: worn ? 2 : AppGlass.edgeWidth),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: cosmetic.khas ? AppColors.aksenHangatLembut : rarity.background, borderRadius: BorderRadius.circular(AppRadius.pill)),
                  child: Text(
                    cosmetic.khas ? t.khasLabel : rarity.label(t),
                    style: AppTextStyles.caption.copyWith(fontSize: 10, fontWeight: FontWeight.w700, color: cosmetic.khas ? AppColors.aksenHangatGelap : rarity.foreground),
                  ),
                ),
                const Spacer(),
                if (worn)
                  Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(color: AppColors.primer, shape: BoxShape.circle),
                    child: const Icon(Icons.check_rounded, size: 12, color: AppColors.diAtasTinta),
                  ),
              ],
            ),
            Expanded(
              child: Center(
                child: Opacity(
                  opacity: wearable ? 1 : 0.6,
                  child: LayoutBuilder(
                    builder: (context, c) {
                      final size = c.biggest.shortestSide.clamp(40.0, 88.0);
                      return Image.asset(cosmetic.artAsset, width: size, height: size, cacheWidth: (size * 3).round());
                    },
                  ),
                ),
              ),
            ),
            Text(t.cosmeticName(cosmetic.id), maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.chipLabel.copyWith(fontSize: 14, color: AppColors.teksUtama)),
            const SizedBox(height: 4),
            SizedBox(height: 26, child: Align(alignment: Alignment.centerLeft, child: _Status(cosmetic: cosmetic, owned: owned, wearable: wearable, worn: worn))),
          ],
        ),
      ),
    );
  }
}

class _Status extends StatelessWidget {
  const _Status({required this.cosmetic, required this.owned, required this.wearable, required this.worn});

  final TokoCosmetic cosmetic;
  final bool owned;
  final bool wearable;
  final bool worn;

  @override
  Widget build(BuildContext context) {
    final t = context.s.toko;
    final style = AppTextStyles.caption.copyWith(fontSize: 12, fontWeight: FontWeight.w600);
    if (!wearable) {
      return Row(
        children: [
          const Icon(Icons.lock_outline_rounded, size: 12, color: AppColors.teksSekunder),
          const SizedBox(width: 4),
          Flexible(child: Text(t.exclusiveTo(context.s.common.monsterName(cosmetic.monsterId)), maxLines: 1, overflow: TextOverflow.ellipsis, style: style.copyWith(color: AppColors.teksSekunder))),
        ],
      );
    }
    if (!owned) return KoinPricePill(label: t.coinsPrice(cosmetic.price));
    if (worn) return Text(t.worn, style: style.copyWith(color: AppColors.primer));
    return Text(t.owned, style: style.copyWith(color: AppColors.teksSekunder));
  }
}
