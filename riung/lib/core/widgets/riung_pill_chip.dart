import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Bentuk dasar chip pil Riung (bg kartu, border garis, radius penuh).
/// Dipakai oleh [KoinChip], [StreakChip], [TiketChip] — lihat §05 Komponen
/// inti · "Chip koin, streak & tiket" di `design/Design System.dc.html`.
class RiungPillChip extends StatelessWidget {
  const RiungPillChip({
    super.key,
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.textColor,
  });

  final IconData icon;
  final String label;
  final Color iconColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.kartu,
        border: Border.all(color: AppColors.garis),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: iconColor),
          const SizedBox(width: 6),
          Text(label, style: AppTextStyles.chipLabel.copyWith(color: textColor)),
        ],
      ),
    );
  }
}
