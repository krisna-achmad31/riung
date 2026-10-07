import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';

/// Pil harga kaca (frame `Harga`): koin 3D + angka.
class KoinPricePill extends StatelessWidget {
  const KoinPricePill({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 5, 10, 5),
      decoration: BoxDecoration(
        color: AppColors.permukaanPadat.withValues(alpha: 0.8),
        border: Border.all(color: AppColors.garis),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const RiungIcon3D(RiungIcon.koin, size: 18),
          const SizedBox(width: 4),
          Text(label, style: AppTextStyles.chipLabel.copyWith(fontSize: 13, color: AppColors.teksUtama)),
        ],
      ),
    );
  }
}
