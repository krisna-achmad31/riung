import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';

/// Ubin deck afirmasi (frame `Deck …` di `Glass — Afirmasi · Kategori`):
/// kartu kaca, thumbnail pastel berisi monster jinak 3D (atau ikon pena
/// untuk deck buatan sendiri), judul & jumlah kartu.
class AfirmasiDeckTile extends StatelessWidget {
  const AfirmasiDeckTile({
    super.key,
    required this.monsterId,
    required this.title,
    required this.meta,
    required this.onTap,
  });

  /// null = deck "Buatanku sendiri".
  final String? monsterId;
  final String title;
  final String meta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final id = monsterId;
    return RiungGlassCard(
      radius: 26,
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 90,
            width: double.infinity,
            decoration: BoxDecoration(
              color: id == null ? AppColors.kabutSage : (AppColors.monsterLembut[id] ?? AppColors.kabutSage),
              borderRadius: BorderRadius.circular(20),
            ),
            alignment: Alignment.center,
            child: id == null
                ? const Icon(Icons.edit_rounded, size: 30, color: AppColors.primer)
                : RiungMonster(monsterId: id, state: MonsterVisualState.jinak, size: 84, applyBossScale: false),
          ),
          const SizedBox(height: 10),
          Text(title, maxLines: 2, style: AppTextStyles.chipLabel.copyWith(fontSize: 14, height: 1.25, color: AppColors.teksUtama)),
          const SizedBox(height: 4),
          Text(meta, style: AppTextStyles.caption.copyWith(fontSize: 11, color: AppColors.teksSekunder)),
        ],
      ),
    );
  }
}
