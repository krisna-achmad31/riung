import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Chip nilai kaca (frame `Chip …` di layar mini-game Riung Glass): ikon
/// 3D opsional di atas, angka besar, label kecil — semuanya di tengah.
class RiungValueChip extends StatelessWidget {
  const RiungValueChip({super.key, required this.value, required this.label, this.leading});

  final String value;
  final String label;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
      decoration: AppGlass.card(radius: 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[
            SizedBox(width: 30, height: 30, child: leading),
            const SizedBox(height: 2),
          ],
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, maxLines: 1, style: AppTextStyles.title.copyWith(fontSize: 18, height: 1.2, color: AppColors.teksUtama)),
          ),
          const SizedBox(height: 2),
          Text(label, maxLines: 2, textAlign: TextAlign.center, style: AppTextStyles.caption.copyWith(fontSize: 10, height: 1.25, color: AppColors.teksSekunder)),
        ],
      ),
    );
  }
}
