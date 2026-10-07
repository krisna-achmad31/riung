import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';

/// Tombol buka-berbayar (frame `Buka berbayar`): pil kaca, koin 3D + label.
class PaidUnlockButton extends StatelessWidget {
  const PaidUnlockButton({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.55 : 1,
      child: Material(
        color: AppColors.permukaanPadat.withValues(alpha: 0.8),
        shape: const StadiumBorder(side: BorderSide(color: AppColors.garis, width: AppGlass.edgeWidth)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: SizedBox(
            height: 52,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const RiungIcon3D(RiungIcon.koin, size: 20),
                const SizedBox(width: 6),
                Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.buttonLabel.copyWith(fontSize: 15, color: AppColors.teksUtama))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
