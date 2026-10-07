import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';

/// Kartu berjudul + isi + satu tombol. Dipakai untuk dukungan, kunci
/// Premium, dan keadaan data belum cukup — semuanya bernada lembut.
class ReportNoticeCard extends StatelessWidget {
  const ReportNoticeCard({
    super.key,
    required this.icon,
    required this.accent,
    required this.title,
    required this.body,
    required this.cta,
    required this.onCta,
    this.filledButton = false,
  });

  final IconData icon;
  final Color accent;
  final String title;
  final String body;
  final String cta;
  final VoidCallback onCta;
  final bool filledButton;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: AppGlass.card(radius: 26, color: accent.withValues(alpha: 0.12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: accent),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(title, style: AppTextStyles.chipLabel.copyWith(fontSize: 14, color: AppColors.teksUtama))),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(body, style: AppTextStyles.caption.copyWith(fontSize: 12, height: 1.45, color: AppColors.teksSekunder)),
          const SizedBox(height: AppSpacing.md),
          RiungButton(label: cta, onPressed: onCta, variant: filledButton ? RiungButtonVariant.primary : RiungButtonVariant.secondary),
        ],
      ),
    );
  }
}
