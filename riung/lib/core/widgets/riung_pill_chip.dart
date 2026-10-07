import 'package:flutter/material.dart';

import '../theme/theme.dart';
import 'riung_icon_3d.dart';

/// Bentuk dasar chip pil kaca Riung Glass (komponen `KoinChip` di
/// `design/riung.pen`): kaca kuat, tepi putih, ikon 3D bulat di kiri.
/// Dipakai oleh [KoinChip], [StreakChip], [TiketChip].
class RiungPillChip extends StatelessWidget {
  const RiungPillChip({
    super.key,
    this.icon,
    this.icon3d,
    required this.label,
    this.iconColor = AppColors.teksUtama,
    this.textColor = AppColors.teksUtama,
  }) : assert(icon != null || icon3d != null);

  final IconData? icon;

  /// Ikon 3D; bila diisi menggantikan [icon].
  final RiungIcon? icon3d;
  final String label;
  final Color iconColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final threeD = icon3d;
    return Container(
      padding: EdgeInsets.fromLTRB(threeD != null ? 5 : 12, 5, 12, 5),
      decoration: AppGlass.pill(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (threeD != null) RiungIcon3D(threeD, size: 24) else Icon(icon, size: 17, color: iconColor),
          const SizedBox(width: 6),
          Text(label, style: AppTextStyles.chipLabel.copyWith(color: textColor)),
        ],
      ),
    );
  }
}
