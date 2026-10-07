import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../logic/toko_data.dart';

/// Panggung Lemari (frame `Panggung`): aura, podium, monster jinak memakai
/// kosmetik pilihan, plus label slot yang terisi.
class LemariStage extends StatelessWidget {
  const LemariStage({super.key, required this.monsterId, required this.worn});

  final String monsterId;
  final List<TokoCosmetic> worn;

  @override
  Widget build(BuildContext context) {
    final t = context.s.toko;
    TokoCosmetic? at(CosmeticSlot s) {
      for (final c in worn) {
        if (c.slot == s) return c;
      }
      return null;
    }

    final head = at(CosmeticSlot.head);
    final neck = at(CosmeticSlot.neck);
    final base = at(CosmeticSlot.base);
    final side = at(CosmeticSlot.side);
    return Container(
      height: 330,
      decoration: BoxDecoration(
        color: AppColors.permukaan.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: AppColors.garis, width: AppGlass.edgeWidth),
      ),
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            top: 30,
            child: Container(
              width: 270,
              height: 260,
              decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [AppColors.garis, AppColors.garis.withValues(alpha: 0)])),
            ),
          ),
          Positioned(
            top: 262,
            child: Container(
              width: 230,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.elliptical(115, 22)),
                gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppColors.permukaanPadat.withValues(alpha: 0.8), AppColors.langitLembut.withValues(alpha: 0.6)]),
                border: Border.all(color: AppColors.garis, width: AppGlass.edgeWidth),
              ),
            ),
          ),
          Positioned(
            top: 44,
            child: RiungMonster(monsterId: monsterId, state: MonsterVisualState.jinak, size: 230, applyBossScale: false, cosmetics: [for (final c in worn) c.id]),
          ),
          if (head != null) Positioned(left: 14, top: 40, child: _SlotTag(slot: t.slotHead, item: t.cosmeticName(head.id))),
          if (neck != null) Positioned(right: 12, top: 150, child: _SlotTag(slot: t.slotNeck, item: t.cosmeticName(neck.id))),
          if (base != null) Positioned(left: 14, top: 236, child: _SlotTag(slot: t.slotBase, item: t.cosmeticName(base.id))),
          if (side != null) Positioned(right: 12, top: 236, child: _SlotTag(slot: t.slotSide, item: t.cosmeticName(side.id))),
        ],
      ),
    );
  }
}

class _SlotTag extends StatelessWidget {
  const _SlotTag({required this.slot, required this.item});

  final String slot;
  final String item;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 120),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.permukaan,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.garis, width: AppGlass.edgeWidth),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(slot.toUpperCase(), style: AppTextStyles.caption.copyWith(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.teksRedup)),
          Text(item, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.chipLabel.copyWith(fontSize: 12, color: AppColors.teksUtama)),
        ],
      ),
    );
  }
}
