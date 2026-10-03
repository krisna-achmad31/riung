import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../theme/theme.dart';

/// Kartu "Tahukah kamu?" — fakta riset bersumber, dipakai di Beranda, hasil
/// asesmen, dan layar lain. Lihat §05 Komponen inti di
/// `design/Design System.dc.html`.
class TahukahKamuCard extends StatelessWidget {
  const TahukahKamuCard({super.key, required this.text, required this.source});

  final String text;
  final String source;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.kartu,
        border: Border.all(color: AppColors.garis),
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, size: 16, color: AppColors.sekunder),
              const SizedBox(width: AppSpacing.sm),
              Text(
                context.s.common.didYouKnow,
                style: AppTextStyles.chipLabel.copyWith(color: AppColors.sekunder, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(text, style: AppTextStyles.body.copyWith(color: AppColors.teksUtama, fontSize: 13)),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.garis),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(source, style: AppTextStyles.caption.copyWith(fontSize: 10)),
          ),
        ],
      ),
    );
  }
}
