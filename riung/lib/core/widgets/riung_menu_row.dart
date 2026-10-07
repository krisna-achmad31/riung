import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Satu baris menu di dalam [RiungMenuGroup] (frame `Menu …` / `Baris …`
/// di `Glass — Profil`): ikon (3D atau kotak ikon), judul, sub, badge
/// opsional, chevron.
class RiungMenuRow extends StatelessWidget {
  const RiungMenuRow({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    this.badge,
    this.badgeColor = AppColors.aksenHangatLembut,
    this.badgeTextColor = AppColors.aksenHangatGelap,
    this.titleColor = AppColors.teksUtama,
    this.trailing,
    this.onTap,
  });

  /// Kotak ikon berwarna lembut (Pengaturan) dengan ikon garis.
  static Widget iconBox(IconData icon, {Color background = AppColors.primerLembut, Color color = AppColors.primer}) => Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, size: 17, color: color),
      );

  final Widget leading;
  final String title;
  final String? subtitle;
  final String? badge;
  final Color badgeColor;
  final Color badgeTextColor;
  final Color titleColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 60),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              leading,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: AppTextStyles.chipLabel.copyWith(fontSize: 14, color: titleColor)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle!, style: AppTextStyles.caption.copyWith(fontSize: 11, height: 1.3, color: AppColors.teksSekunder)),
                    ],
                  ],
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(AppRadius.pill)),
                  child: Text(badge!, style: AppTextStyles.caption.copyWith(fontSize: 10, fontWeight: FontWeight.w700, color: badgeTextColor)),
                ),
              ],
              const SizedBox(width: 8),
              trailing ?? (onTap == null ? const SizedBox.shrink() : const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.teksRedup)),
            ],
          ),
        ),
      ),
    );
  }
}
