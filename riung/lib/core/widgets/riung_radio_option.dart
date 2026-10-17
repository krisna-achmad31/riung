import 'package:flutter/material.dart';

import '../theme/theme.dart';
import 'riung_skeleton.dart';

/// Opsi pilihan kaca berradio (frame `Tahunan`/`Bulanan`, `1 sesi`/`Paket 5
/// sesi`): radio, judul + badge opsional, sub, trailing opsional (harga).
/// [subtitle] null = masih memuat (mis. harga dari Play) → skeleton.
class RiungRadioOption extends StatelessWidget {
  const RiungRadioOption({
    super.key,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.badge,
    this.badgeColor = AppColors.aksenHangatLembut,
    this.badgeTextColor = AppColors.aksenHangatGelap,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;
  final String? badge;
  final Color badgeColor;
  final Color badgeTextColor;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppColors.kartuTerpilih : AppColors.kartuOpsi,
          border: Border.all(color: selected ? AppColors.primer : AppColors.garis, width: selected ? 2 : AppGlass.edgeWidth),
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppGlass.shadow,
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? AppColors.primer : Colors.transparent,
                border: Border.all(color: selected ? AppColors.primer : AppColors.teksRedup, width: 1.5),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 2,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(title, style: AppTextStyles.chipLabel.copyWith(fontSize: 15, color: AppColors.teksUtama)),
                      if (badge != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(AppRadius.pill)),
                          child: Text(badge!, style: AppTextStyles.caption.copyWith(fontSize: 9, fontWeight: FontWeight.w700, color: badgeTextColor)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  if (subtitle case final text?)
                    Text(text, style: AppTextStyles.caption.copyWith(fontSize: 12, color: AppColors.teksSekunder))
                  else
                    const Padding(padding: EdgeInsets.symmetric(vertical: 2), child: RiungSkeleton(width: 140, height: 12)),
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 8), trailing!],
          ],
        ),
      ),
    );
  }
}
