import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Ubin statistik kaca (frame `Stat …` di layar selesai Riung Glass):
/// ikon/monster 3D 44dp + angka besar + label kecil.
class RiungStatTile extends StatelessWidget {
  const RiungStatTile({super.key, required this.leading, required this.value, required this.label});

  final Widget leading;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppGlass.card(radius: 24),
      child: Row(
        children: [
          SizedBox(width: 44, height: 44, child: leading),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, maxLines: 1, style: AppTextStyles.title.copyWith(fontSize: 22, height: 1.15, color: AppColors.teksUtama)),
                Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.caption.copyWith(fontSize: 11, color: AppColors.teksSekunder)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
